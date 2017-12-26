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
/****************************************************************************
 * examples/netcat/netcat_main.c
 *
 *   Copyright (C) 2008, 2011-2012 Gregory Nutt. All rights reserved.
 *   Author: Gregory Nutt <gnutt@nuttx.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name NuttX nor the names of its contributors may be
 *    used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include <tinyara/config.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>


int netcat_server(int argc, char* argv[])
{
    FILE* fout = stdout;
    struct sockaddr_in server, client;
    int port = 54200;
    
    if ((1 < argc) && (0 == strcmp("-l", argv[1]))) {
        if (2 < argc) {
            port = atoi(argv[2]);
        }
        if (3 < argc) {
            fout = fopen(argv[3],"w");
            if ( 0 > fout ) {
                perror("error: io: Failed to create file");
                return 1;
            }
        }
    }

    int id;
    id = socket(AF_INET , SOCK_STREAM , 0);
    if (0 > id)
    {
        perror("error: net: Failed to create socket");
        return 2;
    }

    server.sin_family = AF_INET;
    server.sin_addr.s_addr = INADDR_ANY;
    server.sin_port = htons(port);
    if (0 > bind(id, (struct sockaddr *)&server , sizeof(server)))
    {
        perror("error: net: Failed to bind");
        return 3;
    }
    fprintf(stderr,"log: net: listening on :%d\n", port);
    listen(id , 3);
    int capacity = 256;
    char buf[capacity];
    socklen_t addrlen;
    int conn;
    while ((conn = accept(id, (struct sockaddr *)&client, &addrlen)))
    {
        int avail = 1;
        while (0 < avail)
        {
            avail = recv(conn, buf, capacity, 0 );
            buf[avail]=0;
            fprintf(fout, "%s", buf);
            int status = fflush(fout);
            if (0 != status) {
                perror("error: io: Failed to flush");
            }
            write(conn, buf, avail); // echo back to client
        }
    }
    if (0 > conn)
    {
        perror("accept failed");
        return 4;
    }

    if (stdout != fout) {
        fclose(fout);
    }
    return EXIT_SUCCESS;
}


int netcat_client(int argc, char* argv[])
{
    FILE *fout = stdout;
    char *host = "127.0.0.1";
    int port = 54200;

    if (argc > 1) {
        host = argv[1];
    }

    if (argc > 2) {
        port = atoi(argv[2]);
    }

    if (argc > 3) {
        fout = fopen(argv[3],"w");
        if ( 0 > fout ) {
            perror("error: io: Failed to create file");
            return 1;
        }
    }

    int id;
    id = socket(AF_INET , SOCK_STREAM , 0);
    if (0 > id)
    {
        perror("error: net: Failed to create socket");
        return 2;
    }

    struct sockaddr_in server;
    server.sin_family = AF_INET;
    server.sin_port = htons(port);
    if (1 != inet_pton(AF_INET, host, &server.sin_addr))
    {
        perror("error: net: Invalid host");
        return 3;
    }

    if (connect(id, (struct sockaddr*)&server, sizeof(server)) < 0) {
        perror("error: net: Failed to connect");
        return 4;
    }

    int capacity = 256;
    char buf[capacity];
    int avail;
    for(;;) {
        fgets(buf, capacity, stdin);
        avail = strnlen(buf, capacity);
        if (avail < 0) {
            perror("error: reading");
            exit(1);
        }
        buf[avail]=0;
        avail = write(id, buf, avail);
        if (avail < 0) {
            perror("error: net: writing to socket");
            exit(1);
        }
    }
    if (stdout != fout) {
        fclose(fout);
    }
    return EXIT_SUCCESS;
}


#ifdef CONFIG_BUILD_KERNEL
int main(int argc, FAR char *argv[])
#else
int netcat_main(int argc, char *argv[])
#endif
{
    int status = EXIT_SUCCESS;
    if (2 > argc) {
        fprintf(stderr, "Usage: $0 [-l] [destination] [port] [file]\n");
    } else if ((1 < argc) && (0 == strcmp("-l", argv[1]))) {
        status = netcat_server(argc, argv);
    } else {
        status = netcat_client(argc, argv);
    }
    return status;
}
