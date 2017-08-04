/****************************************************************************
 *
 * Copyright 2016 Samsung Electronics All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied. See the License for the specific
 * language governing permissions and limitations under the License.
 *
 ****************************************************************************/
/*
 * Copyright (c) 2001-2004 Swedish Institute of Computer Science.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 * This file is part of the lwIP TCP/IP stack.
 *
 * Author: Adam Dunkels <adam@sics.se>
 *
 * Improved by Marc Boucher <marc@mbsi.ca> and David Haas <dhaas@alum.rpi.edu>
 *
 */

/**
 * @file
 * Sockets BSD-Like API module
 *
 */

#include <net/lwip/opt.h>
#include <tinyara/net/net.h>
#include <tinyara/net/ioctl.h>
#include <net/lwip/netif.h>
#include <netinet/in.h>

#if defined(CONFIG_ARCH_CHIP_S5JT200) || 1
#if LWIP_HAVE_LOOPIF
#define NET_DEVNAME "wl1"
#else
#define NET_DEVNAME "wl0"
#endif
#else
#error "undefined CONFIG_NET_<type>, check your .config"
#endif

#if LWIP_SOCKET					/* don't build if not configured for use in lwipopts.h */

#include <net/lwip/sockets.h>
#include <net/lwip/api.h>
#include <net/lwip/sys.h>
#include <net/lwip/ipv4/igmp.h>
#include <net/lwip/ipv4/inet.h>
#include <net/lwip/tcp.h>
#include <net/lwip/raw.h>
#include <net/lwip/udp.h>
#include <net/lwip/tcpip.h>
#include <net/lwip/pbuf.h>
#include <net/lwip/mem.h>
#if LWIP_CHECKSUM_ON_COPY
#include <net/lwip/ipv4/inet_chksum.h>
#endif

#include <string.h>
#include <poll.h>
#include <time.h>

#define NUM_SOCKETS MEMP_NUM_NETCONN

/** Description for a task waiting in select */
struct lwip_select_cb {
	/** Pointer to the next waiting task */
	struct lwip_select_cb *next;
	/** Pointer to the previous waiting task */
	struct lwip_select_cb *prev;
#if LWIP_SELECT
	/** readset passed to select */
	fd_set *readset;
	/** writeset passed to select */
	fd_set *writeset;
	/** unimplemented: exceptset passed to select */
	fd_set *exceptset;
	/** semaphore to wake up a task waiting for select */
	sys_sem_t sem;
#else
	/** Pointer to semaphore used post output event */
	sys_sem_t *poll_sem;
	/** Pointer to event-set of requested poll events */
	pollevent_t events;
	/** socket descriptor value */
	int sfd;
#endif
	/** don't signal the same semaphore twice: set to 1 when signalled */
	int sem_signalled;
};

/** This struct is used to pass data to the set/getsockopt_internal
 * functions running in tcpip_thread context (only a void* is allowed) */
struct lwip_setgetsockopt_data {
	/** socket struct for which to change options */
	struct socket *sock;
#ifdef LWIP_DEBUG
	/** socket index for which to change options */
	int s;
#endif							/* LWIP_DEBUG */
	/** level of the option to process */
	int level;
	/** name of the option to process */
	int optname;
	/** set: value to set the option to
	  * get: value of the option is stored here */
	void *optval;
	/** size of *optval */
	socklen_t *optlen;
	/** if an error occures, it is temporarily stored here */
	err_t err;
};

/** The global list of tasks waiting for select */
static struct lwip_select_cb *select_cb_list;
/** This counter is increased from lwip_select when the list is chagned
    and checked in event_callback to see if it has changed. */
static volatile int select_cb_ctr;

/** Table to quickly map an lwIP error (err_t) to a socket error
  * by using -err as an index */
static const int err_to_errno_table[] = {
	0,							/* ERR_OK          0      No error, everything OK. */
	ENOMEM,						/* ERR_MEM        -1      Out of memory error.     */
	ENOBUFS,					/* ERR_BUF        -2      Buffer error.            */
	EWOULDBLOCK,				/* ERR_TIMEOUT    -3      Timeout                  */
	EHOSTUNREACH,				/* ERR_RTE        -4      Routing problem.         */
	EINPROGRESS,				/* ERR_INPROGRESS -5      Operation in progress    */
	EINVAL,						/* ERR_VAL        -6      Illegal value.           */
	EWOULDBLOCK,				/* ERR_WOULDBLOCK -7      Operation would block.   */
	EADDRINUSE,					/* ERR_USE        -8      Address in use.          */
	EALREADY,					/* ERR_ALREADY    -9      Already connecting.      */
	EISCONN,					/* ERR_ISCONN     -10     Conn already established. */
	ENOTCONN,					/* ERR_CONN       -11     Not connected.           */
	ECONNABORTED,				/* ERR_ABRT       -12     Connection aborted.      */
	ECONNRESET,					/* ERR_RST        -13     Connection reset.        */
	ENOTCONN,					/* ERR_CLSD       -14     Connection closed.       */
	EIO,						/* ERR_ARG        -15     Illegal argument.        */
	-1,							/* ERR_IF         -16     Low-level netif error    */
};

#define ERR_TO_ERRNO_TABLE_SIZE \
	(sizeof(err_to_errno_table)/sizeof(err_to_errno_table[0]))

#define err_to_errno(err) \
	((unsigned)(-(err)) < ERR_TO_ERRNO_TABLE_SIZE ? \
			err_to_errno_table[-(err)] : EIO)

#ifdef ERRNO
#ifndef set_errno
#define set_errno(err) errno = (err)
#endif
#else							/* ERRNO */
#ifndef set_errno
#define set_errno(err)
#endif
#endif							/* ERRNO */

#define sock_set_errno(sk, e) do { \
	sk->err = (e); \
	set_errno(sk->err); \
} while (0)

/* Forward delcaration of some functions */
static void event_callback(struct netconn *conn, enum netconn_evt evt, u16_t len);
static void lwip_getsockopt_internal(void *arg);
static void lwip_setsockopt_internal(void *arg);

/**
 * Private Functions
 */

static void _net_semtake(FAR struct socketlist *list)
{
	/* Take the semaphore (perhaps waiting) */

	while (net_lockedwait(&list->sl_sem) != 0) {
		/* The only case that an error should occr here is if
		 * the wait was awakened by a signal.
		 */

		ASSERT(*get_errno_ptr() == EINTR);
	}
}

#define _net_semgive(list) sem_post(&list->sl_sem)

/**
 * Initialize this module. This function has to be called before any other
 * functions in this module!
 */
void lwip_socket_init(void)
{
}

/**
 * Map a externally used socket index to the internal socket representation.
 *
 * @param s externally used socket index
 * @return struct socket for the socket or NULL if not found / not active
 */

struct socket *get_socket(int s)
{
	struct socketlist *list;
	s -= LWIP_SOCKET_OFFSET;

	if (s >= 0 && s < NUM_SOCKETS) {
		list = sched_getsockets();
		if (list && list->sl_sockets[s].conn) {
			return &list->sl_sockets[s];
		}
	}
	LWIP_DEBUGF(SOCKETS_DEBUG, ("get_socket(%d): invalid\n", s + LWIP_SOCKET_OFFSET));
	set_errno(EBADF);
	return NULL;
}

struct socket *get_socket_from_list(int s, struct netconn *conn)
{
	s -= LWIP_SOCKET_OFFSET;
	if (conn && s >= 0 && s < NUM_SOCKETS) {
		struct socketlist *list = conn->slist;
		if (list && list->sl_sockets[s].conn) {
			return &list->sl_sockets[s];
		}
	}
	LWIP_DEBUGF(SOCKETS_DEBUG, ("get_socket_from_list(%d): invalid\n", s + LWIP_SOCKET_OFFSET));
	set_errno(EBADF);
	return NULL;
}

/**
 * Map a externally used socket index to the internal socket representation.
 *
 * @param s externally used socket index
 * @return struct socket for the socket or NULL if not found
 */
struct socket *get_socket_struct(int s)
{
	struct socketlist *list;
	s -= LWIP_SOCKET_OFFSET;

	if (s >= 0 && s < NUM_SOCKETS) {
		list = sched_getsockets();
		if (list) {
			return &list->sl_sockets[s];
		}
	}
	LWIP_DEBUGF(SOCKETS_DEBUG, ("get_socket_struct(%d): invalid\n", s + LWIP_SOCKET_OFFSET));
	set_errno(EBADF);
	return NULL;
}

/**
 * Same as get_socket but doesn't set errno
 *
 * @param s externally used socket index
 * @return struct socket for the socket or NULL if not found
 */
static struct socket *tryget_socket(int s)
{
	struct socketlist *list;
	s -= LWIP_SOCKET_OFFSET;

	if (s >= 0 && s < NUM_SOCKETS) {
		list = sched_getsockets();
		if (list && (list->sl_sockets[s].conn)) {
			return &list->sl_sockets[s];
		}
	}

	return NULL;
}

/**
 * Allocate a new socket for a given netconn.
 *
 * @param newconn the netconn for which to allocate a socket
 * @param accepted 1 if socket has been created by accept(),
 *                 0 if socket has been created by socket()
 * @return the index of the new socket; -1 on error
 */
int alloc_socket(struct netconn *newconn, int accepted)
{
	FAR struct socketlist *list;
	int i;
	/* Get the socket list for this task/thread */

	list = sched_getsockets();
	if (list) {
		/* lwip task can access task socket descriptor */
		newconn->slist = list;
		/* Search for a socket structure with no references */

		_net_semtake(list);
		for (i = 0; i < CONFIG_NSOCKET_DESCRIPTORS; i++) {
			/* Are there references on this socket? */

			if (!list->sl_sockets[i].conn) {
				/* No take the reference and return the index + an offset
				 * as the socket descriptor.
				 */
				list->sl_sockets[i].conn = newconn;
				/* The socket is not yet known to anyone, so no need to protect
				   after having marked it as used. */

				list->sl_sockets[i].lastdata = NULL;
				list->sl_sockets[i].lastoffset = 0;
				list->sl_sockets[i].rcvevent = 0;
				/* TCP sendbuf is empty, but the socket is not yet writable until connected
				 * (unless it has been created by accept()). */
				list->sl_sockets[i].sendevent = (newconn->type == NETCONN_TCP ? (accepted != 0) : 1);
				list->sl_sockets[i].errevent = 0;
				list->sl_sockets[i].err = 0;
				list->sl_sockets[i].select_waiting = 0;
				_net_semgive(list);

				return i + LWIP_SOCKET_OFFSET;
			}
		}

		_net_semgive(list);
	}
	return ERROR;
}

/** Free a socket. The socket's netconn must have been
 * delete before!
 *
 * @param sock the socket to free
 * @param is_tcp != 0 for TCP sockets, used to free lastdata
 */
static void free_socket(struct socket *sock, int is_tcp)
{
	void *lastdata;
	SYS_ARCH_DECL_PROTECT(lev);

	lastdata = sock->lastdata;
	sock->lastdata = NULL;
	sock->lastoffset = 0;
	sock->err = 0;

	/* Protect socket array */
	SYS_ARCH_PROTECT(lev);
	sock->conn = NULL;
	SYS_ARCH_UNPROTECT(lev);
	/* don't use 'sock' after this line, as another task might have allocated it */

	if (lastdata != NULL) {
		if (is_tcp) {
			pbuf_free((struct pbuf *)lastdata);
		} else {
			netbuf_delete((struct netbuf *)lastdata);
		}
	}
}

/* Below this, the well-known socket functions are implemented.
 * Use google.com or opengroup.org to get a good description :-)
 *
 * Exceptions are documented!
 */

int lwip_accept(int s, struct sockaddr *addr, socklen_t *addrlen)
{
	struct socket *sock, *nsock;
	struct netconn *newconn;
	ip_addr_t naddr;
	u16_t port = 0;
	int newsock;
	struct sockaddr_in sin;
	err_t err;
	SYS_ARCH_DECL_PROTECT(lev);

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_accept(%d)...\n", s));
	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	if (netconn_is_nonblocking(sock->conn) && (sock->rcvevent <= 0)) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_accept(%d): returning EWOULDBLOCK\n", s));
		sock_set_errno(sock, EWOULDBLOCK);
		return -1;
	}

	/* wait for a new connection */
	err = netconn_accept(sock->conn, &newconn);
	if (err != ERR_OK) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_accept(%d): netconn_acept failed, err=%d\n", s, err));
		if (netconn_type(sock->conn) != NETCONN_TCP) {
			sock_set_errno(sock, EOPNOTSUPP);
			return EOPNOTSUPP;
		}
		sock_set_errno(sock, err_to_errno(err));
		return -1;
	}
	LWIP_ASSERT("newconn != NULL", newconn != NULL);
	/* Prevent automatic window updates, we do this on our own! */
	netconn_set_noautorecved(newconn, 1);

	/* get the IP address and port of the remote host */
	err = netconn_peer(newconn, &naddr, &port);
	if (err != ERR_OK) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_accept(%d): netconn_peer failed, err=%d\n", s, err));
		netconn_delete(newconn);
		sock_set_errno(sock, err_to_errno(err));
		return -1;
	}

	/* Note that POSIX only requires us to check addr is non-NULL. addrlen must
	 * not be NULL if addr is valid.
	 */
	if (NULL != addr) {
		LWIP_ASSERT("addr valid but addrlen NULL", addrlen != NULL);
		memset(&sin, 0, sizeof(sin));
		sin.sin_len = sizeof(sin);
		sin.sin_family = AF_INET;
		sin.sin_port = htons(port);
		inet_addr_from_ipaddr(&sin.sin_addr, &naddr);

		if (*addrlen > sizeof(sin)) {
			*addrlen = sizeof(sin);
		}

		MEMCPY(addr, &sin, *addrlen);
	}

	newsock = alloc_socket(newconn, 1);
	if (newsock == -1) {
		netconn_delete(newconn);
		sock_set_errno(sock, ENFILE);
		return -1;
	}
	LWIP_ASSERT("invalid socket index", (newsock >= LWIP_SOCKET_OFFSET) && (newsock < NUM_SOCKETS + LWIP_SOCKET_OFFSET));
	LWIP_ASSERT("newconn->callback == event_callback", newconn->callback == event_callback);
	nsock = get_socket(newsock);
	LWIP_ASSERT("nsock != NULL", nsock != NULL);

	/* See event_callback: If data comes in right away after an accept, even
	 * though the server task might not have created a new socket yet.
	 * In that case, newconn->socket is counted down (newconn->socket--),
	 * so nsock->rcvevent is >= 1 here!
	 */
	SYS_ARCH_PROTECT(lev);
	nsock->rcvevent += (s16_t)(-1 - newconn->socket);
	newconn->socket = newsock;
	SYS_ARCH_UNPROTECT(lev);

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_accept(%d) returning new sock=%d addr=", s, newsock));
	ip_addr_debug_print(SOCKETS_DEBUG, &naddr);
	LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F "\n", port));

	sock_set_errno(sock, 0);
	return newsock;
}

int lwip_bind(int s, const struct sockaddr *name, socklen_t namelen)
{
	struct socket *sock;
	ip_addr_t local_addr;
	u16_t local_port;
	err_t err;
	const struct sockaddr_in *name_in;

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	/* check size, familiy and alignment of 'name' */
	LWIP_ERROR("lwip_bind: invalid address", ((namelen == sizeof(struct sockaddr_in)) && ((name->sa_family) == AF_INET) && ((((mem_ptr_t)name) % 4) == 0)), sock_set_errno(sock, err_to_errno(ERR_ARG)); return -1;);
	name_in = (const struct sockaddr_in *)(void *)name;

	inet_addr_to_ipaddr(&local_addr, &name_in->sin_addr);
	local_port = name_in->sin_port;

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_bind(%d, addr=", s));
	ip_addr_debug_print(SOCKETS_DEBUG, &local_addr);
	LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F ")\n", ntohs(local_port)));

	err = netconn_bind(sock->conn, &local_addr, ntohs(local_port));

	if (err != ERR_OK) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_bind(%d) failed, err=%d\n", s, err));
		sock_set_errno(sock, err_to_errno(err));
		return -1;
	}

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_bind(%d) succeeded\n", s));
	sock_set_errno(sock, 0);
	return 0;
}

int lwip_close(int s)
{
	struct socket *sock;

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_close(%d)\n", s));

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	return lwip_sock_close(sock);
}

/*
 * Close socket by struct socket
 * Task in TinyAra need to delete it's socket list when it is destroyed
 * We need this API, becuase Caller deletes it's socket list
 * if it calls lwip_close().
 */
int lwip_sock_close(struct socket *sock)
{
	int is_tcp = 0;
	if (sock->conn != NULL) {
		is_tcp = netconn_type(sock->conn) == NETCONN_TCP;
	} else {
		LWIP_ASSERT("sock->lastdata == NULL", sock->lastdata == NULL);
	}

	netconn_delete(sock->conn);
	free_socket(sock, is_tcp);
	set_errno(0);
	return 0;
}

int lwip_connect(int s, const struct sockaddr *name, socklen_t namelen)
{
	struct socket *sock;
	err_t err;
	const struct sockaddr_in *name_in;

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	/* check size, familiy and alignment of 'name' */
	LWIP_ERROR("lwip_connect: invalid address", ((namelen == sizeof(struct sockaddr_in)) && ((name->sa_family) == AF_INET) && ((((mem_ptr_t)name) % 4) == 0)), sock_set_errno(sock, err_to_errno(ERR_ARG)); return -1;);
	name_in = (const struct sockaddr_in *)(void *)name;

	if (name_in->sin_family == AF_UNSPEC) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_connect(%d, AF_UNSPEC)\n", s));
		err = netconn_disconnect(sock->conn);
	} else {
		ip_addr_t remote_addr;
		u16_t remote_port;

		inet_addr_to_ipaddr(&remote_addr, &name_in->sin_addr);
		remote_port = name_in->sin_port;

		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_connect(%d, addr=", s));
		ip_addr_debug_print(SOCKETS_DEBUG, &remote_addr);
		LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F ")\n", ntohs(remote_port)));

		err = netconn_connect(sock->conn, &remote_addr, ntohs(remote_port));
	}

	if (err != ERR_OK) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_connect(%d) failed, err=%d\n", s, err));
		sock_set_errno(sock, err_to_errno(err));
		return -1;
	}

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_connect(%d) succeeded\n", s));
	sock_set_errno(sock, 0);
	return 0;
}

/**
 * Set a socket into listen mode.
 * The socket may not have been used for another connection previously.
 *
 * @param s the socket to set to listening mode
 * @param backlog (ATTENTION: needs TCP_LISTEN_BACKLOG=1)
 * @return 0 on success, non-zero on failure
 */
int lwip_listen(int s, int backlog)
{
	struct socket *sock;
	err_t err;

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_listen(%d, backlog=%d)\n", s, backlog));

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	/* limit the "backlog" parameter to fit in an u8_t */
	backlog = LWIP_MIN(LWIP_MAX(backlog, 0), 0xff);

	err = netconn_listen_with_backlog(sock->conn, (u8_t)backlog);

	if (err != ERR_OK) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_listen(%d) failed, err=%d\n", s, err));
		if (netconn_type(sock->conn) != NETCONN_TCP) {
			sock_set_errno(sock, EOPNOTSUPP);
			return EOPNOTSUPP;
		}
		sock_set_errno(sock, err_to_errno(err));
		return -1;
	}

	sock_set_errno(sock, 0);
	return 0;
}

int lwip_recvfrom(int s, void *mem, size_t len, int flags, struct sockaddr *from, socklen_t *fromlen)
{
	struct socket *sock;
	void *buf = NULL;
	struct pbuf *p;
	u16_t buflen, copylen;
	int off = 0;
	ip_addr_t *addr;
	u16_t port = 0;
	u8_t done = 0;
	err_t err;

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom(%d, %p, %" SZT_F ", 0x%x, ..)\n", s, mem, len, flags));
	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	do {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom: top while sock->lastdata=%p\n", sock->lastdata));
		/* Check if there is data left from the last recv operation. */
		if (sock->lastdata) {
			buf = sock->lastdata;
		} else {
			/* If this is non-blocking call, then check first */
			if (((flags & MSG_DONTWAIT) || netconn_is_nonblocking(sock->conn)) && (sock->rcvevent <= 0)) {
				if (off > 0) {
					/* update receive window */
					netconn_recved(sock->conn, (u32_t)off);
					/* already received data, return that */
					sock_set_errno(sock, 0);
					return off;
				}
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom(%d): returning EWOULDBLOCK\n", s));
				sock_set_errno(sock, EWOULDBLOCK);
				return -1;
			}

			/* No data was left from the previous operation, so we try to get
			   some from the network. */
			if (netconn_type(sock->conn) == NETCONN_TCP) {
				err = netconn_recv_tcp_pbuf(sock->conn, (struct pbuf **)&buf);
			} else {
				err = netconn_recv(sock->conn, (struct netbuf **)&buf);
			}
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom: netconn_recv err=%d, netbuf=%p\n", err, buf));

			if (err != ERR_OK) {
				if (off > 0) {
					/* update receive window */
					netconn_recved(sock->conn, (u32_t)off);
					/* already received data, return that */
					sock_set_errno(sock, 0);
					return off;
				}
				/* We should really do some error checking here. */
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom(%d): buf == NULL, error is \"%s\"!\n", s, lwip_strerr(err)));
				sock_set_errno(sock, err_to_errno(err));
				if (err == ERR_CLSD) {
					return 0;
				} else {
					return -1;
				}
			}
			LWIP_ASSERT("buf != NULL", buf != NULL);
			sock->lastdata = buf;
		}

		if (netconn_type(sock->conn) == NETCONN_TCP) {
			p = (struct pbuf *)buf;
		} else {
			p = ((struct netbuf *)buf)->p;
		}
		buflen = p->tot_len;
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom: buflen=%" U16_F " len=%" SZT_F " off=%d sock->lastoffset=%" U16_F "\n", buflen, len, off, sock->lastoffset));

		buflen -= sock->lastoffset;

		if (len > buflen) {
			copylen = buflen;
		} else {
			copylen = (u16_t)len;
		}

		/* copy the contents of the received buffer into
		   the supplied memory pointer mem */
		pbuf_copy_partial(p, (u8_t *)mem + off, copylen, sock->lastoffset);

		off += copylen;

		if (netconn_type(sock->conn) == NETCONN_TCP) {
			LWIP_ASSERT("invalid copylen, len would underflow", len >= copylen);
			len -= copylen;
			if ((len <= 0) || (p->flags & PBUF_FLAG_PUSH) || (sock->rcvevent <= 0) || ((flags & MSG_PEEK) != 0)) {
				done = 1;
			}
		} else {
			done = 1;
		}

		/* Check to see from where the data was. */
		if (done) {
			ip_addr_t fromaddr;
			if (from && fromlen) {
				struct sockaddr_in sin;

				if (netconn_type(sock->conn) == NETCONN_TCP) {
					addr = &fromaddr;
					netconn_getaddr(sock->conn, addr, &port, 0);
				} else {
					addr = netbuf_fromaddr((struct netbuf *)buf);
					port = netbuf_fromport((struct netbuf *)buf);
				}

				memset(&sin, 0, sizeof(sin));
				sin.sin_len = sizeof(sin);
				sin.sin_family = AF_INET;
				sin.sin_port = htons(port);
				inet_addr_from_ipaddr(&sin.sin_addr, addr);

				if (*fromlen > sizeof(sin)) {
					*fromlen = sizeof(sin);
				}

				MEMCPY(from, &sin, *fromlen);

				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom(%d): addr=", s));
				ip_addr_debug_print(SOCKETS_DEBUG, addr);
				LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F " len=%d\n", port, off));
			} else {
#if SOCKETS_DEBUG
				if (netconn_type(sock->conn) == NETCONN_TCP) {
					addr = &fromaddr;
					netconn_getaddr(sock->conn, addr, &port, 0);
				} else {
					addr = netbuf_fromaddr((struct netbuf *)buf);
					port = netbuf_fromport((struct netbuf *)buf);
				}

				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom(%d): addr=", s));
				ip_addr_debug_print(SOCKETS_DEBUG, addr);
				LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F " len=%d\n", port, off));
#endif							/*  SOCKETS_DEBUG */
			}
		}

		/* If we don't peek the incoming message... */
		if ((flags & MSG_PEEK) == 0) {
			/* If this is a TCP socket, check if there is data left in the
			   buffer. If so, it should be saved in the sock structure for next
			   time around. */
			if ((netconn_type(sock->conn) == NETCONN_TCP) && (buflen - copylen > 0)) {
				sock->lastdata = buf;
				sock->lastoffset += copylen;
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom: lastdata now netbuf=%p\n", buf));
			} else {
				sock->lastdata = NULL;
				sock->lastoffset = 0;
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_recvfrom: deleting netbuf=%p\n", buf));
				if (netconn_type(sock->conn) == NETCONN_TCP) {
					pbuf_free((struct pbuf *)buf);
				} else {
					netbuf_delete((struct netbuf *)buf);
				}
			}
		}
	} while (!done);

	if (off > 0) {
		/* update receive window */
		netconn_recved(sock->conn, (u32_t)off);
	}
	sock_set_errno(sock, 0);
	return off;
}

int lwip_read(int s, void *mem, size_t len)
{
	return lwip_recvfrom(s, mem, len, 0, NULL, NULL);
}

int lwip_recv(int s, void *mem, size_t len, int flags)
{
	return lwip_recvfrom(s, mem, len, flags, NULL, NULL);
}

int lwip_send(int s, const void *data, size_t size, int flags)
{
	struct socket *sock;
	err_t err;
	u8_t write_flags;
	size_t written;

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_send(%d, data=%p, size=%" SZT_F ", flags=0x%x)\n", s, data, size, flags));

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	if (sock->conn->type != NETCONN_TCP) {
#if (LWIP_UDP || LWIP_RAW)
		return lwip_sendto(s, data, size, flags, NULL, 0);
#else							/* (LWIP_UDP || LWIP_RAW) */
		sock_set_errno(sock, err_to_errno(ERR_ARG));
		return -1;
#endif							/* (LWIP_UDP || LWIP_RAW) */
	}

	write_flags = NETCONN_COPY | ((flags & MSG_MORE) ? NETCONN_MORE : 0) | ((flags & MSG_DONTWAIT) ? NETCONN_DONTBLOCK : 0);
	written = 0;
	err = netconn_write_partly(sock->conn, data, size, write_flags, &written);

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_send(%d) err=%d written=%" SZT_F "\n", s, err, written));
	sock_set_errno(sock, err_to_errno(err));
	return (err == ERR_OK ? (int)written : -1);
}

int lwip_sendto(int s, const void *data, size_t size, int flags, const struct sockaddr *to, socklen_t tolen)
{
	struct socket *sock;
	err_t err;
	u16_t short_size;
	const struct sockaddr_in *to_in;
	u16_t remote_port;
#if !LWIP_TCPIP_CORE_LOCKING
	struct netbuf buf;
#endif

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}
	if (sock->conn->type == NETCONN_TCP) {
#if LWIP_TCP
		return lwip_send(s, data, size, flags);
#else							/* LWIP_TCP */
		LWIP_UNUSED_ARG(flags);
		sock_set_errno(sock, err_to_errno(ERR_ARG));
		return -1;
#endif							/* LWIP_TCP */
	}

	/* @todo: split into multiple sendto's? */
	LWIP_ASSERT("lwip_sendto: size must fit in u16_t", size <= 0xffff);
	short_size = (u16_t)size;
	LWIP_ERROR("lwip_sendto: invalid address", (((to == NULL) && (tolen == 0)) || ((tolen == sizeof(struct sockaddr_in)) && ((to->sa_family) == AF_INET) && ((((mem_ptr_t)to) % 4) == 0))), sock_set_errno(sock, err_to_errno(ERR_ARG)); return -1;);
	to_in = (const struct sockaddr_in *)(void *)to;

#if LWIP_TCPIP_CORE_LOCKING
	/* Should only be consider like a sample or a simple way to experiment this option (no check of "to" field...) */
	{
		struct pbuf *p;
		ip_addr_t *remote_addr;

#if LWIP_NETIF_TX_SINGLE_PBUF
		p = pbuf_alloc(PBUF_TRANSPORT, short_size, PBUF_RAM);
		if (p != NULL) {
#if LWIP_CHECKSUM_ON_COPY
			u16_t chksum = 0;
			if (sock->conn->type != NETCONN_RAW) {
				chksum = LWIP_CHKSUM_COPY(p->payload, data, short_size);
			} else
#endif							/* LWIP_CHECKSUM_ON_COPY */
				MEMCPY(p->payload, data, size);
#else							/* LWIP_NETIF_TX_SINGLE_PBUF */
		p = pbuf_alloc(PBUF_TRANSPORT, short_size, PBUF_REF);
		if (p != NULL) {
			p->payload = (void *)data;
#endif							/* LWIP_NETIF_TX_SINGLE_PBUF */

			if (to_in != NULL) {
				inet_addr_to_ipaddr_p(remote_addr, &to_in->sin_addr);
				remote_port = ntohs(to_in->sin_port);
			} else {
				remote_addr = &sock->conn->pcb.ip->remote_ip;
#if LWIP_UDP
				if (NETCONNTYPE_GROUP(sock->conn->type) == NETCONN_UDP) {
					remote_port = sock->conn->pcb.udp->remote_port;
				} else
#endif							/* LWIP_UDP */
				{
					remote_port = 0;
				}
			}

			LOCK_TCPIP_CORE();
			if (netconn_type(sock->conn) == NETCONN_RAW) {
#if LWIP_RAW
				err = sock->conn->last_err = raw_sendto(sock->conn->pcb.raw, p, remote_addr);
#else							/* LWIP_RAW */
				err = ERR_ARG;
#endif							/* LWIP_RAW */
			}
#if LWIP_UDP && LWIP_RAW
			else
#endif							/* LWIP_UDP && LWIP_RAW */
			{
#if LWIP_UDP
#if LWIP_CHECKSUM_ON_COPY && LWIP_NETIF_TX_SINGLE_PBUF
				err = sock->conn->last_err = udp_sendto_chksum(sock->conn->pcb.udp, p, remote_addr, remote_port, 1, chksum);
#else							/* LWIP_CHECKSUM_ON_COPY && LWIP_NETIF_TX_SINGLE_PBUF */
				err = sock->conn->last_err = udp_sendto(sock->conn->pcb.udp, p, remote_addr, remote_port);
#endif							/* LWIP_CHECKSUM_ON_COPY && LWIP_NETIF_TX_SINGLE_PBUF */
#else							/* LWIP_UDP */
				err = ERR_ARG;
#endif							/* LWIP_UDP */
			}
			UNLOCK_TCPIP_CORE();

			pbuf_free(p);
		} else {
			err = ERR_MEM;
		}
	}
#else							/* LWIP_TCPIP_CORE_LOCKING */
	/* initialize a buffer */
	buf.p = buf.ptr = NULL;
#if LWIP_CHECKSUM_ON_COPY
	buf.flags = 0;
#endif							/* LWIP_CHECKSUM_ON_COPY */
	if (to) {
		inet_addr_to_ipaddr(&buf.addr, &to_in->sin_addr);
		remote_port = ntohs(to_in->sin_port);
		netbuf_fromport(&buf) = remote_port;
	} else {
		remote_port = 0;
		ip_addr_set_any(&buf.addr);
		netbuf_fromport(&buf) = 0;
	}

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_sendto(%d, data=%p, short_size=%" U16_F ", flags=0x%x to=", s, data, short_size, flags));
	ip_addr_debug_print(SOCKETS_DEBUG, &buf.addr);
	LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F "\n", remote_port));

	/* make the buffer point to the data that should be sent */
#if LWIP_NETIF_TX_SINGLE_PBUF
	/* Allocate a new netbuf and copy the data into it. */
	if (netbuf_alloc(&buf, short_size) == NULL) {
		err = ERR_MEM;
	} else {
#if LWIP_CHECKSUM_ON_COPY
		if (sock->conn->type != NETCONN_RAW) {
			u16_t chksum = LWIP_CHKSUM_COPY(buf.p->payload, data, short_size);
			netbuf_set_chksum(&buf, chksum);
			err = ERR_OK;
		} else
#endif							/* LWIP_CHECKSUM_ON_COPY */
		{
			err = netbuf_take(&buf, data, short_size);
		}
	}
#else							/* LWIP_NETIF_TX_SINGLE_PBUF */
	err = netbuf_ref(&buf, data, short_size);
#endif							/* LWIP_NETIF_TX_SINGLE_PBUF */
	if (err == ERR_OK) {
		/* send the data */
		err = netconn_send(sock->conn, &buf);
	}

	/* deallocated the buffer */
	netbuf_free(&buf);
#endif							/* LWIP_TCPIP_CORE_LOCKING */
	sock_set_errno(sock, err_to_errno(err));
	return (err == ERR_OK ? short_size : -1);
}

int argument_validation(int domain, int type, int protocol)
{
	if (domain == AF_AX25 || domain == AF_X25) {
		return -1;
	}
	if (protocol == IPPROTO_IPV6 || protocol == IPPROTO_ICMPV6) {
		return -1;
	}
	if (protocol == IPPROTO_TCP && type == SOCK_DGRAM) {
		return -1;
	}
	if (domain == AF_PACKET && type == SOCK_STREAM) {
		return -1;
	}
	if (domain == AF_NETLINK && type == SOCK_STREAM) {
		return -1;
	}
	if (type == SOCK_STREAM && protocol == IPPROTO_UDP) {
		return -1;
	}
	if (type == SOCK_RAW && domain == AF_UNIX) {
		return -1;
	}
	if (domain < 0 || domain > 10) {
		return -1;
	}
	if (protocol < 0 || protocol > 255) {
		return -1;
	}
	if (domain == AF_UNIX) {
		if (protocol == IPPROTO_ICMP || protocol == IPPROTO_IGMP || protocol == IPPROTO_ROUTING) {
			return -1;
		}
	}
	return 0;
}

int lwip_socket(int domain, int type, int protocol)
{
	struct netconn *conn;
	int i;
	if (argument_validation(domain, type, protocol) == -1) {
		return -1;
	}

	LWIP_UNUSED_ARG(domain);

	/* create a netconn */
	switch (type) {
	case SOCK_RAW:
		conn = netconn_new_with_proto_and_callback(NETCONN_RAW, (u8_t)protocol, event_callback);
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_socket(%s, SOCK_RAW, %d) = ", domain == PF_INET ? "PF_INET" : "UNKNOWN", protocol));
		break;
	case SOCK_DGRAM:
		conn = netconn_new_with_callback((protocol == IPPROTO_UDPLITE) ? NETCONN_UDPLITE : NETCONN_UDP, event_callback);
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_socket(%s, SOCK_DGRAM, %d) = ", domain == PF_INET ? "PF_INET" : "UNKNOWN", protocol));
		break;
	case SOCK_STREAM:
		conn = netconn_new_with_callback(NETCONN_TCP, event_callback);
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_socket(%s, SOCK_STREAM, %d) = ", domain == PF_INET ? "PF_INET" : "UNKNOWN", protocol));
		if (conn != NULL) {
			/* Prevent automatic window updates, we do this on our own! */
			netconn_set_noautorecved(conn, 1);
		}
		break;
	default:
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_socket(%d, %d/UNKNOWN, %d) = -1\n", domain, type, protocol));
		set_errno(EINVAL);
		return -1;
	}

	if (!conn) {
		LWIP_DEBUGF(SOCKETS_DEBUG, ("-1 / ENOBUFS (could not create netconn)\n"));
		set_errno(ENOBUFS);
		return -1;
	}

	i = alloc_socket(conn, 0);

	if (i == -1) {

		netconn_delete(conn);
		set_errno(ENFILE);
		return -1;
	}
	conn->socket = i;
	LWIP_DEBUGF(SOCKETS_DEBUG, ("%d\n", i));
	set_errno(0);
	return i;
}

int lwip_write(int s, const void * data, size_t size)
{
	return lwip_send(s, data, size, 0);
}

#if LWIP_SELECT

/**
 * Go through the readset and writeset lists and see which socket of the sockets
 * set in the sets has events. On return, readset, writeset and exceptset have
 * the sockets enabled that had events.
 *
 * exceptset is not used for now!!!
 *
 * @param maxfdp1 the highest socket index in the sets
 * @param readset_in:    set of sockets to check for read events
 * @param writeset_in:   set of sockets to check for write events
 * @param exceptset_in:  set of sockets to check for error events
 * @param readset_out:   set of sockets that had read events
 * @param writeset_out:  set of sockets that had write events
 * @param exceptset_out: set os sockets that had error events
 * @return number of sockets that had events (read/write/exception) (>= 0)
 */
static int lwip_selscan(int maxfdp1, fd_set * readset_in, fd_set * writeset_in, fd_set * exceptset_in, fd_set * readset_out, fd_set * writeset_out, fd_set * exceptset_out)
{
	int i, nready = 0;
	fd_set lreadset, lwriteset, lexceptset;
	struct socket *sock;
	SYS_ARCH_DECL_PROTECT(lev);

	FD_ZERO(&lreadset);
	FD_ZERO(&lwriteset);
	FD_ZERO(&lexceptset);

	/* Go through each socket in each list to count number of sockets which
	   currently match */
	for (i = LWIP_SOCKET_OFFSET; i < maxfdp1; i++) {
		void *lastdata = NULL;
		s16_t rcvevent = 0;
		u16_t sendevent = 0;
		u16_t errevent = 0;
		/* First get the socket's status (protected)... */
		SYS_ARCH_PROTECT(lev);
		sock = tryget_socket(i);
		if (sock != NULL) {
			lastdata = sock->lastdata;
			rcvevent = sock->rcvevent;
			sendevent = sock->sendevent;
			errevent = sock->errevent;
		}
		SYS_ARCH_UNPROTECT(lev);
		/* ... then examine it: */
		/* See if netconn of this socket is ready for read */
		if (readset_in && FD_ISSET(i, readset_in) && ((lastdata != NULL) || (rcvevent > 0))) {
			FD_SET(i, &lreadset);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_selscan: fd=%d ready for reading\n", i));
			nready++;
		}
		/* See if netconn of this socket is ready for write */
		if (writeset_in && FD_ISSET(i, writeset_in) && (sendevent != 0)) {
			FD_SET(i, &lwriteset);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_selscan: fd=%d ready for writing\n", i));
			nready++;
		}
		/* See if netconn of this socket had an error */
		if (exceptset_in && FD_ISSET(i, exceptset_in) && (errevent != 0)) {
			FD_SET(i, &lexceptset);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_selscan: fd=%d ready for exception\n", i));
			nready++;
		}
	}
	/* copy local sets to the ones provided as arguments */
	*readset_out = lreadset;
	*writeset_out = lwriteset;
	*exceptset_out = lexceptset;

	LWIP_ASSERT("nready >= 0", nready >= 0);
	return nready;
}

/**
 * Processing exceptset is not yet implemented.
 */
int lwip_select(int maxfdp1, fd_set * readset, fd_set * writeset, fd_set * exceptset, struct timeval * timeout)
{
	u32_t waitres = 0;
	int nready;
	fd_set lreadset, lwriteset, lexceptset;
	u32_t msectimeout;
	struct lwip_select_cb select_cb;
	int i;
	int maxfdp2;
	SYS_ARCH_DECL_PROTECT(lev);

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_select(%d, %p, %p, %p, tvsec=%" S32_F " tvusec=%" S32_F ")\n", maxfdp1, (void *)readset, (void *)writeset, (void *)exceptset, timeout ? (s32_t)timeout->tv_sec : (s32_t)-1, timeout ? (s32_t)timeout->tv_usec : (s32_t)-1));

	/* Go through each socket in each list to count number of sockets which
	   currently match */
	nready = lwip_selscan(maxfdp1, readset, writeset, exceptset, &lreadset, &lwriteset, &lexceptset);

	/* If we don't have any current events, then suspend if we are supposed to */
	if (!nready) {
		if (timeout && timeout->tv_sec == 0 && timeout->tv_usec == 0) {
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_select: no timeout, returning 0\n"));
			/* This is OK as the local fdsets are empty and nready is zero,
			   or we would have returned earlier. */
			goto return_copy_fdsets;
		}

		/* None ready: add our semaphore to list:
		   We don't actually need any dynamic memory. Our entry on the
		   list is only valid while we are in this function, so it's ok
		   to use local variables. */

		select_cb.next = NULL;
		select_cb.prev = NULL;
		select_cb.readset = readset;
		select_cb.writeset = writeset;
		select_cb.exceptset = exceptset;
		select_cb.sem_signalled = 0;
		if (sys_sem_new(&select_cb.sem, 0) != ERR_OK) {
			/* failed to create semaphore */
			set_errno(ENOMEM);
			return -1;
		}

		/* Protect the select_cb_list */
		SYS_ARCH_PROTECT(lev);

		/* Put this select_cb on top of list */
		select_cb.next = select_cb_list;
		if (select_cb_list != NULL) {
			select_cb_list->prev = &select_cb;
		}
		select_cb_list = &select_cb;
		/* Increasing this counter tells event_callback that the list has changed. */
		select_cb_ctr++;

		/* Now we can safely unprotect */
		SYS_ARCH_UNPROTECT(lev);

		/* Increase select_waiting for each socket we are interested in */
		maxfdp2 = maxfdp1;
		for (i = LWIP_SOCKET_OFFSET; i < maxfdp1; i++) {
			if ((readset && FD_ISSET(i, readset)) || (writeset && FD_ISSET(i, writeset)) || (exceptset && FD_ISSET(i, exceptset))) {
				struct socket *sock;
				SYS_ARCH_PROTECT(lev);
				sock = tryget_socket(i);
				if (sock != NULL) {
					sock->select_waiting++;
					LWIP_ASSERT("sock->select_waiting > 0", sock->select_waiting > 0);
				} else {
					/* Not a valid socket */
					nready = -1;
					maxfdp2 = i;
					SYS_ARCH_UNPROTECT(lev);
					break;
				}
				SYS_ARCH_UNPROTECT(lev);
			}
		}

		if (nready >= 0) {
			/* Call lwip_selscan again: there could have been events between
			   the last scan (without us on the list) and putting us on the list! */
			nready = lwip_selscan(maxfdp1, readset, writeset, exceptset, &lreadset, &lwriteset, &lexceptset);
			if (!nready) {
				/* Still none ready, just wait to be woken */
				if (timeout == 0) {
					/* Wait forever */
					msectimeout = 0;
				} else {
					msectimeout = ((timeout->tv_sec * 1000) + ((timeout->tv_usec + 500) / 1000));
					if (msectimeout == 0) {
						/* Wait 1ms at least (0 means wait forever) */
						msectimeout = 1;
					}
				}

				waitres = sys_arch_sem_wait(&select_cb.sem, msectimeout);
			}
		}

		/* Decrease select_waiting for each socket we are interested in */
		for (i = LWIP_SOCKET_OFFSET; i < maxfdp2; i++) {
			if ((readset && FD_ISSET(i, readset)) || (writeset && FD_ISSET(i, writeset)) || (exceptset && FD_ISSET(i, exceptset))) {
				struct socket *sock;
				SYS_ARCH_PROTECT(lev);
				sock = tryget_socket(i);
				if (sock != NULL) {
					/* @todo: what if this is a new socket (reallocated?) in this case,
					   select_waiting-- would be wrong (a global 'sockalloc' counter,
					   stored per socket could help) */
					LWIP_ASSERT("sock->select_waiting > 0", sock->select_waiting > 0);
					if (sock->select_waiting > 0) {
						sock->select_waiting--;
					}
				} else {
					/* Not a valid socket */
					nready = -1;
				}
				SYS_ARCH_UNPROTECT(lev);
			}
		}
		/* Take us off the list */
		SYS_ARCH_PROTECT(lev);
		if (select_cb.next != NULL) {
			select_cb.next->prev = select_cb.prev;
		}
		if (select_cb_list == &select_cb) {
			LWIP_ASSERT("select_cb.prev == NULL", select_cb.prev == NULL);
			select_cb_list = select_cb.next;
		} else {
			LWIP_ASSERT("select_cb.prev != NULL", select_cb.prev != NULL);
			select_cb.prev->next = select_cb.next;
		}
		/* Increasing this counter tells event_callback that the list has changed. */
		select_cb_ctr++;
		SYS_ARCH_UNPROTECT(lev);

		sys_sem_free(&select_cb.sem);
		if (nready < 0) {
			/* This happens when a socket got closed while waiting */
			set_errno(EBADF);
			return -1;
		}

		if (waitres == SYS_ARCH_TIMEOUT) {
			/* Timeout */
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_select: timeout expired\n"));
			/* This is OK as the local fdsets are empty and nready is zero,
			   or we would have returned earlier. */
			goto return_copy_fdsets;
		}

		/* See what's set */
		nready = lwip_selscan(maxfdp1, readset, writeset, exceptset, &lreadset, &lwriteset, &lexceptset);
	}

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_select: nready=%d\n", nready));
return_copy_fdsets:
	set_errno(0);
	if (readset) {
		*readset = lreadset;
	}
	if (writeset) {
		*writeset = lwriteset;
	}
	if (exceptset) {
		*exceptset = lexceptset;
	}
	return nready;
}

#else

static int lwip_poll_scan(int fd, struct socket * sock, struct pollfd * fds)
{

	void *lastdata = NULL;
	s16_t rcvevent = 0;
	u16_t sendevent = 0;
	u16_t errevent = 0;
	int nready = 0;
	SYS_ARCH_DECL_PROTECT(lev);

	SYS_ARCH_PROTECT(lev);

	lastdata = sock->lastdata;
	rcvevent = sock->rcvevent;
	sendevent = sock->sendevent;
	errevent = sock->errevent;

	SYS_ARCH_UNPROTECT(lev);

	/* ... then examine it: */
	/* See if netconn of this socket is ready for read */
	if ((fds->events & POLLIN) && ((lastdata != NULL) || (rcvevent > 0))) {
		fds->revents |= POLLIN;
		nready++;
	}
	/* See if netconn of this socket is ready for write */
	if ((fds->events & POLLOUT) && (sendevent != 0)) {
		fds->revents |= POLLOUT;
		nready++;
	}
	/* See if netconn of this socket had an error */
	if ((fds->events & POLLERR) && (errevent != 0)) {
		fds->revents |= POLLERR;
		nready++;
	}

	LWIP_ASSERT("nready >= 0", nready >= 0);
	return nready;
}

static int lwip_poll_setup(int fd, struct socket * sock, struct pollfd * fds)
{
	int nready = 0;
	int scb_size = 0;
	struct lwip_select_cb *select_cb = NULL;

	/* Sanity check */
#ifdef CONFIG_DEBUG
	if (!fds) {
		return -EINVAL;
	}
#endif
	SYS_ARCH_DECL_PROTECT(lev);
	fds->scb = NULL;
	nready = lwip_poll_scan(fd, sock, fds);

	/* Check if any requested events are already in effect */
	if (nready > 0 && fds->revents != 0) {
		/* Yes.. then signal the poll logic */
		sys_sem_signal(fds->sem);
		return 0;
	}

	scb_size = LWIP_MEM_ALIGN_SIZE(sizeof(struct lwip_select_cb));
	select_cb = (struct lwip_select_cb *)mem_malloc(scb_size);

	if (!select_cb) {
		return -ENOMEM;
	}

	memset(select_cb, 0, scb_size);

	/* None ready: add our semaphore to list: */

	select_cb->next = NULL;
	select_cb->prev = NULL;
	select_cb->sem_signalled = 0;
	select_cb->poll_sem = fds->sem;
	select_cb->events = fds->events;
	select_cb->sfd = fd;

	/* Protect the select_cb_list */
	SYS_ARCH_PROTECT(lev);

	/* Put this select_cb on top of list */
	select_cb->next = select_cb_list;
	if (select_cb_list != NULL) {
		select_cb_list->prev = select_cb;
	}

	fds->scb = (void *)select_cb;
	select_cb_list = select_cb;

	/* Increasing this counter tells event_callback that the list has changed. */
	select_cb_ctr++;

	/* Increase select_waiting for the socket */
	sock->select_waiting++;

	/* Now we can safely unprotect */
	SYS_ARCH_UNPROTECT(lev);

	/* Call lwip_pollscan again: there could have been events between
	   the last scan (without us on the list) and putting us on the list! */
	nready = lwip_poll_scan(fd, sock, fds);

	/* Check if any requested events are already in effect */
	if (nready > 0 && fds->revents != 0) {
		/* Yes.. then signal the poll logic */

		sys_sem_signal(fds->sem);
	}

	return 0;
}

static int lwip_poll_teardown(int fd, struct socket * sock, struct pollfd * fds)
{
	struct lwip_select_cb *select_cb = NULL;
	SYS_ARCH_DECL_PROTECT(lev);

	select_cb = (struct lwip_select_cb *)fds->scb;

	SYS_ARCH_PROTECT(lev);
	if (sock->select_waiting > 0) {
		sock->select_waiting--;
	}

	/* Take select_cb_list off the list */
	if (select_cb) {
		if (select_cb->next != NULL) {
			select_cb->next->prev = select_cb->prev;
		}
		if (select_cb_list == select_cb) {
			LWIP_ASSERT("select_cb.prev == NULL", select_cb->prev == NULL);
			select_cb_list = select_cb->next;
		} else {
			LWIP_ASSERT("select_cb.prev != NULL", select_cb->prev != NULL);
			select_cb->prev->next = select_cb->next;
		}

		mem_free((void *)select_cb);
		/* Increasing this counter tells event_callback that the list has changed. */
		select_cb_ctr++;
	}
	SYS_ARCH_UNPROTECT(lev);

	/* See what's set */
	lwip_poll_scan(fd, sock, fds);

	return 0;
}

/****************************************************************************
 * Function: lwip_poll
 *
 * Description:
 *   The standard poll() operation redirects operations on socket descriptors
 *   to this function.
 *
 * Input Parameters:
 *   sock - An instance of the lwip socket structure.
 *   fds   - The structure describing the events to be monitored, OR NULL if
 *           this is a request to stop monitoring events.
 *   setup - true: Setup up the poll; false: Teardown the poll
 *
 * Returned Value:
 *  0: Success; Negated errno on failure
 *
 ****************************************************************************/

int lwip_poll(int fd, struct pollfd * fds, bool setup)
{

	int ret = 0;

	struct socket *sock = NULL;

	/* First get the socket's status (protected)... */

	sock = tryget_socket(fd);
	if (!sock) {
		return -EBADF;
	}

	/* Check if we are setting up or tearing down the poll */

	if (setup) {
		/* Perform the LWIP poll() setup */
		ret = lwip_poll_setup(fd, sock, fds);
	} else {
		/* Perform the LWIP poll() teardown */
		ret = lwip_poll_teardown(fd, sock, fds);
	}

	return ret;

}

#endif							/*LWIP_SELECT */

/**
 * Callback registered in the netconn layer for each socket-netconn.
 * Processes recvevent (data available) and wakes up tasks waiting for select.
 */
static void event_callback(struct netconn * conn, enum netconn_evt evt, u16_t len)
{
	int s;
	struct socket *sock;
	struct lwip_select_cb *scb;
	int last_select_cb_ctr;
	SYS_ARCH_DECL_PROTECT(lev);

	LWIP_UNUSED_ARG(len);

	/* Get socket */
	if (conn) {

		s = conn->socket;
		if (s < 0) {
			/* Data comes in right away after an accept, even though
			 * the server task might not have created a new socket yet.
			 * Just count down (or up) if that's the case and we
			 * will use the data later. Note that only receive events
			 * can happen before the new socket is set up. */
			SYS_ARCH_PROTECT(lev);
			if (conn->socket < 0) {
				if (evt == NETCONN_EVT_RCVPLUS) {
					conn->socket--;
				}
				SYS_ARCH_UNPROTECT(lev);
				return;
			}
			s = conn->socket;
			SYS_ARCH_UNPROTECT(lev);
		}
		/* network task have their own socketlist
		 * so get the struct socket from socketlist
		 * that is assigned alloc_socket*/
		sock = get_socket_from_list(s, conn);
		if (!sock) {
			return;
		}
	} else {
		return;
	}

	SYS_ARCH_PROTECT(lev);
	/* Set event as required */
	switch (evt) {
	case NETCONN_EVT_RCVPLUS:
		sock->rcvevent++;
		break;
	case NETCONN_EVT_RCVMINUS:
		sock->rcvevent--;
		break;
	case NETCONN_EVT_SENDPLUS:
		sock->sendevent = 1;
		break;
	case NETCONN_EVT_SENDMINUS:
		sock->sendevent = 0;
		break;
	case NETCONN_EVT_ERROR:
		sock->errevent = 1;
		break;
	default:
		LWIP_ASSERT("unknown event", 0);
		break;
	}

	if (sock->select_waiting == 0) {
		/* none is waiting for this socket, no need to check select_cb_list */
		SYS_ARCH_UNPROTECT(lev);
		return;
	}

	/* Now decide if anyone is waiting for this socket */
	/* NOTE: This code goes through the select_cb_list list multiple times
	   ONLY IF a select was actually waiting. We go through the list the number
	   of waiting select calls + 1. This list is expected to be small. */

	/* At this point, SYS_ARCH is still protected! */
again:
	for (scb = select_cb_list; scb != NULL; scb = scb->next) {

		/* remember the state of select_cb_list to detect changes */
		last_select_cb_ctr = select_cb_ctr;
		if (scb->sem_signalled == 0) {
			/* semaphore not signalled yet */
			int do_signal = 0;
			int check_set = 0;
			/* Test this select call for our socket */
			if (sock->rcvevent > 0) {
#if LWIP_SELECT
				check_set = scb->readset && FD_ISSET(s, scb->readset);
#else
				check_set = (scb->sfd == s) && (scb->events & POLLIN);
#endif
				if (check_set) {
					do_signal = 1;
				}
			}
			if (sock->sendevent != 0) {
#if LWIP_SELECT
				check_set = scb->writeset && FD_ISSET(s, scb->writeset);
#else
				check_set = (scb->sfd == s) && (scb->events & POLLOUT);
#endif
				if (!do_signal && check_set) {
					do_signal = 1;
				}
			}
			if (sock->errevent != 0) {
#if LWIP_SELECT
				check_set = scb->exceptset && FD_ISSET(s, scb->exceptset);
#else
				check_set = (scb->sfd == s) && (scb->events & POLLERR);
#endif
				if (!do_signal && check_set) {
					do_signal = 1;
				}
			}
			if (do_signal) {
				scb->sem_signalled = 1;
				/* Don't call SYS_ARCH_UNPROTECT() before signaling the semaphore, as this might
				   lead to the select thread taking itself off the list, invalidagin the semaphore. */
#if LWIP_SELECT
				sys_sem_signal(&scb->sem);
#else
				sys_sem_signal(scb->poll_sem);
#endif
			}
		}
		/* unlock interrupts with each step */
		SYS_ARCH_UNPROTECT(lev);
		/* this makes sure interrupt protection time is short */
		SYS_ARCH_PROTECT(lev);
		if (last_select_cb_ctr != select_cb_ctr) {
			/* someone has changed select_cb_list, restart at the beginning */
			goto again;
		}
	}
	SYS_ARCH_UNPROTECT(lev);
}

/**
 * Unimplemented: Close one end of a full-duplex connection.
 * Currently, the full connection is closed.
 */
int lwip_shutdown(int s, int how)
{
	struct socket *sock;
	err_t err;
	u8_t shut_rx = 0, shut_tx = 0;

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_shutdown(%d, how=%d)\n", s, how));

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	if (sock->conn != NULL) {
		if (netconn_type(sock->conn) != NETCONN_TCP) {
			sock_set_errno(sock, EOPNOTSUPP);
			return EOPNOTSUPP;
		}
	} else {
		sock_set_errno(sock, ENOTCONN);
		return ENOTCONN;
	}

	if (how == SHUT_RD) {
		shut_rx = 1;
	} else if (how == SHUT_WR) {
		shut_tx = 1;
	} else if (how == SHUT_RDWR) {
		shut_rx = 1;
		shut_tx = 1;
	} else {
		sock_set_errno(sock, EINVAL);
		return EINVAL;
	}
	err = netconn_shutdown(sock->conn, shut_rx, shut_tx);

	sock_set_errno(sock, err_to_errno(err));
	return (err == ERR_OK ? 0 : -1);
}

static int lwip_getaddrname(int s, struct sockaddr * name, socklen_t * namelen, u8_t local)
{
	struct socket *sock;
	struct sockaddr_in sin;
	ip_addr_t naddr;

	sock = get_socket(s);
	if (!sock) {
		return -1;
	}

	memset(&sin, 0, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;

	/* get the IP address and port */
	netconn_getaddr(sock->conn, &naddr, &sin.sin_port, local);

	LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getaddrname(%d, addr=", s));
	ip_addr_debug_print(SOCKETS_DEBUG, &naddr);
	LWIP_DEBUGF(SOCKETS_DEBUG, (" port=%" U16_F ")\n", sin.sin_port));

	sin.sin_port = htons(sin.sin_port);
	inet_addr_from_ipaddr(&sin.sin_addr, &naddr);

	if (*namelen > sizeof(sin)) {
		*namelen = sizeof(sin);
	}

	MEMCPY(name, &sin, *namelen);
	sock_set_errno(sock, 0);
	return 0;
}

int lwip_getpeername(int s, struct sockaddr * name, socklen_t * namelen)
{
	return lwip_getaddrname(s, name, namelen, 0);
}

int lwip_getsockname(int s, struct sockaddr * name, socklen_t * namelen)
{
	return lwip_getaddrname(s, name, namelen, 1);
}

int lwip_getsockopt(int s, int level, int optname, void * optval, socklen_t * optlen)
{
	err_t err = ERR_OK;
	struct socket *sock = get_socket(s);
	struct lwip_setgetsockopt_data data;

	if (!sock) {
		return -1;
	}

	if ((NULL == optval) || (NULL == optlen)) {
		sock_set_errno(sock, EFAULT);
		return -1;
	}

	/* Do length and type checks for the various options first, to keep it readable. */
	switch (level) {

		/* Level: SOL_SOCKET */
	case SOL_SOCKET:
		switch (optname) {

		case SO_ACCEPTCONN:
		case SO_BROADCAST:
			/* UNIMPL case SO_DEBUG: */
			/* UNIMPL case SO_DONTROUTE: */
		case SO_ERROR:
		case SO_KEEPALIVE:
			/* UNIMPL case SO_CONTIMEO: */
#if LWIP_SO_RCVBUF
		case SO_RCVBUF:
#endif							/* LWIP_SO_RCVBUF */
			/* UNIMPL case SO_OOBINLINE: */
			/* UNIMPL case SO_SNDBUF: */
			/* UNIMPL case SO_RCVLOWAT: */
			/* UNIMPL case SO_SNDLOWAT: */
#if SO_REUSE
		case SO_REUSEADDR:
		case SO_REUSEPORT:
#endif							/* SO_REUSE */
		case SO_TYPE:
			/* UNIMPL case SO_USELOOPBACK: */
			if (*optlen < sizeof(int)) {
				err = EINVAL;
			}
			break;

#if LWIP_SO_SNDTIMEO
		case SO_SNDTIMEO:
#endif							/* LWIP_SO_SNDTIMEO */
#if LWIP_SO_RCVTIMEO
		case SO_RCVTIMEO:
#endif							/* LWIP_SO_RCVTIMEO */
			if (*optlen < sizeof(struct timeval)) {
				err = EINVAL;
			}
			break;

		case SO_NO_CHECK:
			if (*optlen < sizeof(int)) {
				err = EINVAL;
			}
#if LWIP_UDP
			if ((sock->conn->type != NETCONN_UDP) || ((udp_flags(sock->conn->pcb.udp) & UDP_FLAGS_UDPLITE) != 0)) {
				/* this flag is only available for UDP, not for UDP lite */
				err = EAFNOSUPPORT;
			}
#endif							/* LWIP_UDP */
			break;

		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, SOL_SOCKET, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;

		/* Level: IPPROTO_IP */
	case IPPROTO_IP:
		switch (optname) {
			/* UNIMPL case IP_HDRINCL: */
			/* UNIMPL case IP_RCVDSTADDR: */
			/* UNIMPL case IP_RCVIF: */
		case IP_TTL:
		case IP_TOS:
			if (*optlen < sizeof(int)) {
				err = EINVAL;
			}
			break;
#if LWIP_IGMP
		case IP_MULTICAST_TTL:
			if (*optlen < sizeof(u8_t)) {
				err = EINVAL;
			}
			break;
		case IP_MULTICAST_IF:
			if (*optlen < sizeof(struct in_addr)) {
				err = EINVAL;
			}
			break;
		case IP_MULTICAST_LOOP:
			if (*optlen < sizeof(u8_t)) {
				err = EINVAL;
			}
			if (NETCONNTYPE_GROUP(sock->conn->type) != NETCONN_UDP) {
				err = EAFNOSUPPORT;
			}
			break;
#endif							/* LWIP_IGMP */

		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;

#if LWIP_TCP
		/* Level: IPPROTO_TCP */
	case IPPROTO_TCP:
		if (*optlen < sizeof(int)) {
			err = EINVAL;
			break;
		}

		/* If this is no TCP socket, ignore any options. */
		if (sock->conn->type != NETCONN_TCP) {
			return 0;
		}

		switch (optname) {
		case TCP_NODELAY:
		case TCP_KEEPALIVE:
#if LWIP_TCP_KEEPALIVE
		case TCP_KEEPIDLE:
		case TCP_KEEPINTVL:
		case TCP_KEEPCNT:
#endif							/* LWIP_TCP_KEEPALIVE */
			break;

		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_TCP, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_TCP */
#if LWIP_UDP && LWIP_UDPLITE
		/* Level: IPPROTO_UDPLITE */
	case IPPROTO_UDPLITE:
		if (*optlen < sizeof(int)) {
			err = EINVAL;
			break;
		}

		/* If this is no UDP lite socket, ignore any options. */
		if (sock->conn->type != NETCONN_UDPLITE) {
			return 0;
		}

		switch (optname) {
		case UDPLITE_SEND_CSCOV:
		case UDPLITE_RECV_CSCOV:
			break;

		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_UDPLITE, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_UDP && LWIP_UDPLITE */
		/* UNDEFINED LEVEL */
	default:
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, level=0x%x, UNIMPL: optname=0x%x, ..)\n", s, level, optname));
		err = ENOPROTOOPT;
	}							/* switch */

	if (err != ERR_OK) {
		sock_set_errno(sock, err);
		return -1;
	}

	/* Now do the actual option processing */
	data.sock = sock;
#ifdef LWIP_DEBUG
	data.s = s;
#endif							/* LWIP_DEBUG */
	data.level = level;
	data.optname = optname;
	data.optval = optval;
	data.optlen = optlen;
	data.err = err;
	tcpip_callback(lwip_getsockopt_internal, &data);
	sys_arch_sem_wait(&sock->conn->op_completed, 0);
	/* maybe lwip_getsockopt_internal has changed err */
	err = data.err;

	sock_set_errno(sock, err);
	return err ? -1 : 0;
}

static void lwip_getsockopt_internal(void * arg)
{
	struct socket *sock;
	int level, optname;
	void *optval;
	struct lwip_setgetsockopt_data *data;
#if LWIP_SO_RCVTIMEO
	struct timeval *timeout;
#endif

	LWIP_ASSERT("arg != NULL", arg != NULL);

	data = (struct lwip_setgetsockopt_data *)arg;
	sock = data->sock;
	level = data->level;
	optname = data->optname;
	optval = data->optval;

	switch (level) {

		/* Level: SOL_SOCKET */
	case SOL_SOCKET:
		switch (optname) {

			/* The option flags */
		case SO_ACCEPTCONN:
		case SO_BROADCAST:
			/* UNIMPL case SO_DEBUG: */
			/* UNIMPL case SO_DONTROUTE: */
		case SO_KEEPALIVE:
			/* UNIMPL case SO_OOBINCLUDE: */
#if SO_REUSE
		case SO_REUSEADDR:
		case SO_REUSEPORT:
#endif							/* SO_REUSE */
			/*case SO_USELOOPBACK: UNIMPL */
			*(int *)optval = ip_get_option(sock->conn->pcb.ip, _SO_BIT(optname));
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, SOL_SOCKET, optname=0x%x, ..) = %s\n", data->s, optname, (*(int *)optval ? "on" : "off")));
			break;

		case SO_TYPE:
			switch (NETCONNTYPE_GROUP(sock->conn->type)) {
			case NETCONN_RAW:
				*(int *)optval = SOCK_RAW;
				break;
			case NETCONN_TCP:
				*(int *)optval = SOCK_STREAM;
				break;
			case NETCONN_UDP:
				*(int *)optval = SOCK_DGRAM;
				break;
			default:			/* unrecognized socket type */
				*(int *)optval = sock->conn->type;
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, SOL_SOCKET, SO_TYPE): unrecognized socket type %d\n", data->s, *(int *)optval));
			}					/* switch (sock->conn->type) */
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, SOL_SOCKET, SO_TYPE) = %d\n", data->s, *(int *)optval));
			break;

		case SO_ERROR:
			/* only overwrite ERR_OK or tempoary errors */
			if ((sock->err == 0) || (sock->err == EINPROGRESS)) {
				sock_set_errno(sock, err_to_errno(sock->conn->last_err));
			}
			*(int *)optval = sock->err;
			sock->err = 0;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, SOL_SOCKET, SO_ERROR) = %d\n", data->s, *(int *)optval));
			break;

#if LWIP_SO_SNDTIMEO
		case SO_SNDTIMEO:
			timeout = (struct timeval *)optval;
			timeout->tv_sec = netconn_get_sendtimeout(sock->conn) / 1000;
			timeout->tv_usec = (netconn_get_sendtimeout(sock->conn) % 1000) * 1000;
			break;
#endif							/* LWIP_SO_SNDTIMEO */
#if LWIP_SO_RCVTIMEO
		case SO_RCVTIMEO:
			timeout = (struct timeval *)optval;
			timeout->tv_sec = netconn_get_recvtimeout(sock->conn) / 1000;
			timeout->tv_usec = (netconn_get_recvtimeout(sock->conn) % 1000) * 1000;
			break;
#endif							/* LWIP_SO_RCVTIMEO */
#if LWIP_SO_RCVBUF
		case SO_RCVBUF:
			*(int *)optval = netconn_get_recvbufsize(sock->conn);
			break;
#endif							/* LWIP_SO_RCVBUF */
#if LWIP_UDP
		case SO_NO_CHECK:
			*(int *)optval = (udp_flags(sock->conn->pcb.udp) & UDP_FLAGS_NOCHKSUM) ? 1 : 0;
			break;
#endif							/* LWIP_UDP */
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;

		/* Level: IPPROTO_IP */
	case IPPROTO_IP:
		switch (optname) {
		case IP_TTL:
			*(int *)optval = sock->conn->pcb.ip->ttl;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, IP_TTL) = %d\n", data->s, *(int *)optval));
			break;
		case IP_TOS:
			*(int *)optval = sock->conn->pcb.ip->tos;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, IP_TOS) = %d\n", data->s, *(int *)optval));
			break;
#if LWIP_IGMP
		case IP_MULTICAST_TTL:
			*(u8_t *)optval = sock->conn->pcb.ip->ttl;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, IP_MULTICAST_TTL) = %d\n", data->s, *(int *)optval));
			break;
		case IP_MULTICAST_IF:
			inet_addr_from_ipaddr((struct in_addr *)optval, &sock->conn->pcb.udp->multicast_ip);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, IP_MULTICAST_IF) = 0x%" X32_F "\n", data->s, *(u32_t *)optval));
			break;
		case IP_MULTICAST_LOOP:
			if ((sock->conn->pcb.udp->flags & UDP_FLAGS_MULTICAST_LOOP) != 0) {
				*(u8_t *)optval = 1;
			} else {
				*(u8_t *)optval = 0;
			}
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, IP_MULTICAST_LOOP) = %d\n", data->s, *(int *)optval));
			break;
#endif							/* LWIP_IGMP */
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;

#if LWIP_TCP
		/* Level: IPPROTO_TCP */
	case IPPROTO_TCP:
		switch (optname) {
		case TCP_NODELAY:
			*(int *)optval = tcp_nagle_disabled(sock->conn->pcb.tcp);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_TCP, TCP_NODELAY) = %s\n", data->s, (*(int *)optval) ? "on" : "off"));
			break;
		case TCP_KEEPALIVE:
			*(int *)optval = (int)sock->conn->pcb.tcp->keep_idle;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, TCP_KEEPALIVE) = %d\n", data->s, *(int *)optval));
			break;

#if LWIP_TCP_KEEPALIVE
		case TCP_KEEPIDLE:
			*(int *)optval = (int)(sock->conn->pcb.tcp->keep_idle / 1000);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, TCP_KEEPIDLE) = %d\n", data->s, *(int *)optval));
			break;
		case TCP_KEEPINTVL:
			*(int *)optval = (int)(sock->conn->pcb.tcp->keep_intvl / 1000);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, TCP_KEEPINTVL) = %d\n", data->s, *(int *)optval));
			break;
		case TCP_KEEPCNT:
			*(int *)optval = (int)sock->conn->pcb.tcp->keep_cnt;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_IP, TCP_KEEPCNT) = %d\n", data->s, *(int *)optval));
			break;
#endif							/* LWIP_TCP_KEEPALIVE */
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_TCP */
#if LWIP_UDP && LWIP_UDPLITE
		/* Level: IPPROTO_UDPLITE */
	case IPPROTO_UDPLITE:
		switch (optname) {
		case UDPLITE_SEND_CSCOV:
			*(int *)optval = sock->conn->pcb.udp->chksum_len_tx;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_UDPLITE, UDPLITE_SEND_CSCOV) = %d\n", data->s, (*(int *)optval)));
			break;
		case UDPLITE_RECV_CSCOV:
			*(int *)optval = sock->conn->pcb.udp->chksum_len_rx;
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_getsockopt(%d, IPPROTO_UDPLITE, UDPLITE_RECV_CSCOV) = %d\n", data->s, (*(int *)optval)));
			break;
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_UDP */
	default:
		LWIP_ASSERT("unhandled level", 0);
		break;
	}							/* switch (level) */
	sys_sem_signal(&sock->conn->op_completed);
}

int lwip_setsockopt(int s, int level, int optname, const void * optval, socklen_t optlen)
{
	struct socket *sock = get_socket(s);
	err_t err = ERR_OK;
	struct lwip_setgetsockopt_data data;

	if (!sock) {
		return -1;
	}

	if (NULL == optval) {
		sock_set_errno(sock, EFAULT);
		return -1;
	}

	/* Do length and type checks for the various options first, to keep it readable. */
	switch (level) {

		/* Level: SOL_SOCKET */
	case SOL_SOCKET:
		switch (optname) {

		case SO_BROADCAST:
			/* UNIMPL case SO_DEBUG: */
			/* UNIMPL case SO_DONTROUTE: */
		case SO_KEEPALIVE:
			/* UNIMPL case case SO_CONTIMEO: */
#if LWIP_SO_RCVBUF
		case SO_RCVBUF:
#endif							/* LWIP_SO_RCVBUF */
			/* UNIMPL case SO_OOBINLINE: */
			/* UNIMPL case SO_SNDBUF: */
			/* UNIMPL case SO_RCVLOWAT: */
			/* UNIMPL case SO_SNDLOWAT: */
#if SO_REUSE
		case SO_REUSEADDR:
		case SO_REUSEPORT:
#endif							/* SO_REUSE */
			/* UNIMPL case SO_USELOOPBACK: */
			if (optlen < sizeof(int)) {
				err = EINVAL;
			}
			break;
#if LWIP_SO_SNDTIMEO
		case SO_SNDTIMEO:
#endif							/* LWIP_SO_SNDTIMEO */
#if LWIP_SO_RCVTIMEO
		case SO_RCVTIMEO:
#endif							/* LWIP_SO_RCVTIMEO */
			if (optlen < sizeof(struct timeval)) {
				err = EINVAL;
			}
			break;

		case SO_NO_CHECK:
			if (optlen < sizeof(int)) {
				err = EINVAL;
			}
#if LWIP_UDP
			if ((sock->conn->type != NETCONN_UDP) || ((udp_flags(sock->conn->pcb.udp) & UDP_FLAGS_UDPLITE) != 0)) {
				/* this flag is only available for UDP, not for UDP lite */
				err = EAFNOSUPPORT;
			}
#endif							/* LWIP_UDP */
			break;
		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, SOL_SOCKET, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;

		/* Level: IPPROTO_IP */
	case IPPROTO_IP:
		switch (optname) {
			/* UNIMPL case IP_HDRINCL: */
			/* UNIMPL case IP_RCVDSTADDR: */
			/* UNIMPL case IP_RCVIF: */
		case IP_TTL:
		case IP_TOS:
			if (optlen < sizeof(int)) {
				err = EINVAL;
			}
			break;
#if LWIP_IGMP
		case IP_MULTICAST_TTL:
			if (optlen < sizeof(u8_t)) {
				err = EINVAL;
			}
			if (NETCONNTYPE_GROUP(sock->conn->type) != NETCONN_UDP) {
				err = EAFNOSUPPORT;
			}
			break;
		case IP_MULTICAST_IF:
			if (optlen < sizeof(struct in_addr)) {
				err = EINVAL;
			}
			if (NETCONNTYPE_GROUP(sock->conn->type) != NETCONN_UDP) {
				err = EAFNOSUPPORT;
			}
			break;
		case IP_MULTICAST_LOOP:
			if (optlen < sizeof(u8_t)) {
				err = EINVAL;
			}
			if (NETCONNTYPE_GROUP(sock->conn->type) != NETCONN_UDP) {
				err = EAFNOSUPPORT;
			}
			break;
		case IP_ADD_MEMBERSHIP:
		case IP_DROP_MEMBERSHIP:
			if (optlen < sizeof(struct ip_mreq)) {
				err = EINVAL;
			}
			if (NETCONNTYPE_GROUP(sock->conn->type) != NETCONN_UDP) {
				err = EAFNOSUPPORT;
			}
			break;
#endif							/* LWIP_IGMP */
		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_IP, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;

#if LWIP_TCP
		/* Level: IPPROTO_TCP */
	case IPPROTO_TCP:
		if (optlen < sizeof(int)) {
			err = EINVAL;
			break;
		}

		/* If this is no TCP socket, ignore any options. */
		if (sock->conn->type != NETCONN_TCP) {
			return 0;
		}

		switch (optname) {
		case TCP_NODELAY:
		case TCP_KEEPALIVE:
#if LWIP_TCP_KEEPALIVE
		case TCP_KEEPIDLE:
		case TCP_KEEPINTVL:
		case TCP_KEEPCNT:
#endif							/* LWIP_TCP_KEEPALIVE */
			break;

		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_TCP, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_TCP */
#if LWIP_UDP && LWIP_UDPLITE
		/* Level: IPPROTO_UDPLITE */
	case IPPROTO_UDPLITE:
		if (optlen < sizeof(int)) {
			err = EINVAL;
			break;
		}

		/* If this is no UDP lite socket, ignore any options. */
		if (sock->conn->type != NETCONN_UDPLITE) {
			return 0;
		}

		switch (optname) {
		case UDPLITE_SEND_CSCOV:
		case UDPLITE_RECV_CSCOV:
			break;

		default:
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_UDPLITE, UNIMPL: optname=0x%x, ..)\n", s, optname));
			err = ENOPROTOOPT;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_UDP && LWIP_UDPLITE */
		/* UNDEFINED LEVEL */
	default:
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, level=0x%x, UNIMPL: optname=0x%x, ..)\n", s, level, optname));
		err = ENOPROTOOPT;
	}							/* switch (level) */

	if (err != ERR_OK) {
		sock_set_errno(sock, err);
		return -1;
	}

	/* Now do the actual option processing */
	data.sock = sock;
#ifdef LWIP_DEBUG
	data.s = s;
#endif							/* LWIP_DEBUG */
	data.level = level;
	data.optname = optname;
	data.optval = (void *)optval;
	data.optlen = &optlen;
	data.err = err;
	tcpip_callback(lwip_setsockopt_internal, &data);
	sys_arch_sem_wait(&sock->conn->op_completed, 0);
	/* maybe lwip_setsockopt_internal has changed err */
	err = data.err;

	sock_set_errno(sock, err);
	return err ? -1 : 0;
}

static void lwip_setsockopt_internal(void * arg)
{
	struct socket *sock;
	int level, optname;
	const void *optval;
	struct lwip_setgetsockopt_data *data;
#if LWIP_SO_RCVTIMEO
	struct timeval *timeout;
	unsigned int timeout_ms;
#endif

	LWIP_ASSERT("arg != NULL", arg != NULL);

	data = (struct lwip_setgetsockopt_data *)arg;
	sock = data->sock;
	level = data->level;
	optname = data->optname;
	optval = data->optval;

	switch (level) {

		/* Level: SOL_SOCKET */
	case SOL_SOCKET:
		switch (optname) {

			/* The option flags */
		case SO_BROADCAST:
			/* UNIMPL case SO_DEBUG: */
			/* UNIMPL case SO_DONTROUTE: */
		case SO_KEEPALIVE:
			/* UNIMPL case SO_OOBINCLUDE: */
#if SO_REUSE
		case SO_REUSEADDR:
		case SO_REUSEPORT:
#endif							/* SO_REUSE */
			/* UNIMPL case SO_USELOOPBACK: */
			if (*(int *)optval) {
				ip_set_option(sock->conn->pcb.ip, _SO_BIT(optname));
			} else {
				ip_reset_option(sock->conn->pcb.ip, _SO_BIT(optname));
			}
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, SOL_SOCKET, optname=0x%x, ..) -> %s\n", data->s, optname, (*(int *)optval ? "on" : "off")));
			break;
#if LWIP_SO_SNDTIMEO
		case SO_SNDTIMEO:
			/* LWIP use ms, so it should convert sec + usec to msec */
			timeout = (struct timeval *)optval;
			timeout_ms = timeout->tv_sec * 1000 + timeout->tv_usec / 1000;
			netconn_set_sendtimeout(sock->conn, timeout_ms);
			break;
#endif							/* LWIP_SO_SNDTIMEO */
#if LWIP_SO_RCVTIMEO
		case SO_RCVTIMEO:
			/* LWIP use ms, so it should convert sec + usec to msec */
			timeout = (struct timeval *)optval;
			timeout_ms = timeout->tv_sec * 1000 + timeout->tv_usec / 1000;
			netconn_set_recvtimeout(sock->conn, timeout_ms);
			break;
#endif							/* LWIP_SO_RCVTIMEO */
#if LWIP_SO_RCVBUF
		case SO_RCVBUF:
			netconn_set_recvbufsize(sock->conn, *(int *)optval);
			break;
#endif							/* LWIP_SO_RCVBUF */
#if LWIP_UDP
		case SO_NO_CHECK:
			if (*(int *)optval) {
				udp_setflags(sock->conn->pcb.udp, udp_flags(sock->conn->pcb.udp) | UDP_FLAGS_NOCHKSUM);
			} else {
				udp_setflags(sock->conn->pcb.udp, udp_flags(sock->conn->pcb.udp) & ~UDP_FLAGS_NOCHKSUM);
			}
			break;
#endif							/* LWIP_UDP */
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;

		/* Level: IPPROTO_IP */
	case IPPROTO_IP:
		switch (optname) {
		case IP_TTL:
			sock->conn->pcb.ip->ttl = (u8_t)(*(int *)optval);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_IP, IP_TTL, ..) -> %d\n", data->s, sock->conn->pcb.ip->ttl));
			break;
		case IP_TOS:
			sock->conn->pcb.ip->tos = (u8_t)(*(int *)optval);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_IP, IP_TOS, ..)-> %d\n", data->s, sock->conn->pcb.ip->tos));
			break;
#if LWIP_IGMP
		case IP_MULTICAST_TTL:
			sock->conn->pcb.udp->ttl = (u8_t)(*(u8_t *)optval);
			break;
		case IP_MULTICAST_IF:
			inet_addr_to_ipaddr(&sock->conn->pcb.udp->multicast_ip, (struct in_addr *)optval);
			break;
		case IP_MULTICAST_LOOP:
			if (*(u8_t *)optval) {
				udp_setflags(sock->conn->pcb.udp, udp_flags(sock->conn->pcb.udp) | UDP_FLAGS_MULTICAST_LOOP);
			} else {
				udp_setflags(sock->conn->pcb.udp, udp_flags(sock->conn->pcb.udp) & ~UDP_FLAGS_MULTICAST_LOOP);
			}
			break;
		case IP_ADD_MEMBERSHIP:
		case IP_DROP_MEMBERSHIP: {
			/* If this is a TCP or a RAW socket, ignore these options. */
			struct ip_mreq *imr = (struct ip_mreq *)optval;
			ip_addr_t if_addr;
			ip_addr_t multi_addr;
			inet_addr_to_ipaddr(&if_addr, &imr->imr_interface);
			inet_addr_to_ipaddr(&multi_addr, &imr->imr_multiaddr);
			if (optname == IP_ADD_MEMBERSHIP) {
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IP_ADD_MEMBERSHIP )\n", data->s));
				data->err = igmp_joingroup(&if_addr, &multi_addr);
			} else {
				LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IP_DROP_MEMBERSHIP )\n", data->s));
				data->err = igmp_leavegroup(&if_addr, &multi_addr);
			}
			if (data->err != ERR_OK) {
				data->err = EADDRNOTAVAIL;
			}
		}
		break;
#endif							/* LWIP_IGMP */
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;

#if LWIP_TCP
		/* Level: IPPROTO_TCP */
	case IPPROTO_TCP:
		switch (optname) {
		case TCP_NODELAY:
			if (*(int *)optval) {
				tcp_nagle_disable(sock->conn->pcb.tcp);
			} else {
				tcp_nagle_enable(sock->conn->pcb.tcp);
			}
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_TCP, TCP_NODELAY) -> %s\n", data->s, (*(int *)optval) ? "on" : "off"));
			break;
		case TCP_KEEPALIVE:
			sock->conn->pcb.tcp->keep_idle = (u32_t)(*(int *)optval);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_TCP, TCP_KEEPALIVE) -> %" U32_F "\n", data->s, sock->conn->pcb.tcp->keep_idle));
			break;

#if LWIP_TCP_KEEPALIVE
		case TCP_KEEPIDLE:
			sock->conn->pcb.tcp->keep_idle = 1000 * (u32_t)(*(int *)optval);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_TCP, TCP_KEEPIDLE) -> %" U32_F "\n", data->s, sock->conn->pcb.tcp->keep_idle));
			break;
		case TCP_KEEPINTVL:
			sock->conn->pcb.tcp->keep_intvl = 1000 * (u32_t)(*(int *)optval);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_TCP, TCP_KEEPINTVL) -> %" U32_F "\n", data->s, sock->conn->pcb.tcp->keep_intvl));
			break;
		case TCP_KEEPCNT:
			sock->conn->pcb.tcp->keep_cnt = (u32_t)(*(int *)optval);
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_TCP, TCP_KEEPCNT) -> %" U32_F "\n", data->s, sock->conn->pcb.tcp->keep_cnt));
			break;
#endif							/* LWIP_TCP_KEEPALIVE */
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_TCP */
#if LWIP_UDP && LWIP_UDPLITE
		/* Level: IPPROTO_UDPLITE */
	case IPPROTO_UDPLITE:
		switch (optname) {
		case UDPLITE_SEND_CSCOV:
			if ((*(int *)optval != 0) && ((*(int *)optval < 8) || (*(int *)optval > 0xffff))) {
				/* don't allow illegal values! */
				sock->conn->pcb.udp->chksum_len_tx = 8;
			} else {
				sock->conn->pcb.udp->chksum_len_tx = (u16_t)*(int *)optval;
			}
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_UDPLITE, UDPLITE_SEND_CSCOV) -> %d\n", data->s, (*(int *)optval)));
			break;
		case UDPLITE_RECV_CSCOV:
			if ((*(int *)optval != 0) && ((*(int *)optval < 8) || (*(int *)optval > 0xffff))) {
				/* don't allow illegal values! */
				sock->conn->pcb.udp->chksum_len_rx = 8;
			} else {
				sock->conn->pcb.udp->chksum_len_rx = (u16_t)*(int *)optval;
			}
			LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_setsockopt(%d, IPPROTO_UDPLITE, UDPLITE_RECV_CSCOV) -> %d\n", data->s, (*(int *)optval)));
			break;
		default:
			LWIP_ASSERT("unhandled optname", 0);
			break;
		}						/* switch (optname) */
		break;
#endif							/* LWIP_UDP */
	default:
		LWIP_ASSERT("unhandled level", 0);
		break;
	}							/* switch (level) */
	sys_sem_signal(&sock->conn->op_completed);
}

int lwip_ioctl(int s, long cmd, void * argp)
{
	struct socket *sock = get_socket(s);
	u8_t val;
#if LWIP_SO_RCVBUF
	u16_t buflen = 0;
	s16_t recv_avail;
#endif							/* LWIP_SO_RCVBUF */
	struct netif *netif;
	struct in_addr *addr;

	if (!sock) {
		return -1;
	}
	switch (cmd) {
#if LWIP_SO_RCVBUF
	case FIONREAD:
		if (!argp) {
			sock_set_errno(sock, EINVAL);
			return -1;
		}

		SYS_ARCH_GET(sock->conn->recv_avail, recv_avail);
		if (recv_avail < 0) {
			recv_avail = 0;
		}
		*((u16_t *)argp) = (u16_t)recv_avail;

		/* Check if there is data left from the last recv operation. /maq 041215 */
		if (sock->lastdata) {
			struct pbuf *p = (struct pbuf *)sock->lastdata;
			if (netconn_type(sock->conn) != NETCONN_TCP) {
				p = ((struct netbuf *)p)->p;
			}
			buflen = p->tot_len;
			buflen -= sock->lastoffset;

			*((u16_t *)argp) += buflen;
		}

		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_ioctl(%d, FIONREAD, %p) = %" U16_F "\n", s, argp, *((u16_t *)argp)));
		sock_set_errno(sock, 0);
		return 0;
#endif							/* LWIP_SO_RCVBUF */

	case FIONBIO:
		val = 0;
		if (argp && *(u32_t *)argp) {
			val = 1;
		}
		netconn_set_nonblocking(sock->conn, val);
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_ioctl(%d, FIONBIO, %d)\n", s, val));
		sock_set_errno(sock, 0);
		return 0;

	case SIOCGIFADDR:
		addr = (struct in_addr *)argp;
		netif = netif_find(NET_DEVNAME);
		if (netif) {
			memcpy(addr, &(netif->ip_addr.addr), sizeof(in_addr_t));
		}
		return 0;

	case SIOCGIFDSTADDR:
		addr = (struct in_addr *)argp;
		netif = netif_find(NET_DEVNAME);
		if (netif) {
			memcpy(addr, &(netif->gw.addr), sizeof(in_addr_t));
		}
		return 0;
	default:
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_ioctl(%d, UNIMPL: 0x%lx, %p)\n", s, cmd, argp));
		sock_set_errno(sock, ENOSYS);	/* not yet implemented */
		return -1;
	}							/* switch (cmd) */
}

/** A minimal implementation of fcntl.
 * Currently only the commands F_GETFL and F_SETFL are implemented.
 * Only the flag O_NONBLOCK is implemented.
 */
int lwip_fcntl(int s, int cmd, int val)
{
	struct socket *sock = get_socket(s);
	int ret = -1;

	if (!sock || !sock->conn) {
		return -1;
	}

	switch (cmd) {
	case F_GETFL:
		ret = netconn_is_nonblocking(sock->conn) ? O_NONBLOCK : 0;
		break;
	case F_SETFL:
		if ((val & ~O_NONBLOCK) == 0) {
			/* only O_NONBLOCK, all other bits are zero */
			netconn_set_nonblocking(sock->conn, val & O_NONBLOCK);
			ret = 0;
		}
		break;
	default:
		LWIP_DEBUGF(SOCKETS_DEBUG, ("lwip_fcntl(%d, UNIMPL: %d, %d)\n", s, cmd, val));
		break;
	}
	return ret;
}

#endif							/* LWIP_SOCKET */
