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
 * Included Files
 ****************************************************************************/

#include <tinyara/config.h>

#include <sys/types.h>
#include <sys/statfs.h>
#include <sys/stat.h>

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <assert.h>
#include <errno.h>
#include <debug.h>

#include <tinyara/kmalloc.h>
#include <tinyara/fs/fs.h>
#include <tinyara/fs/procfs.h>
#include <tinyara/version.h>

#if !defined(CONFIG_DISABLE_MOUNTPOINT) && defined(CONFIG_FS_PROCFS)

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/
/* Determines the size of an intermediate buffer that must be large enough
 * to handle the longest line generated by this logic.
 */

#define VERSION_LINELEN 64

/****************************************************************************
 * Private Types
 ****************************************************************************/

/* This structure describes one open "file" */

struct version_file_s {
	struct procfs_file_s base;	/* Base open file structure */
	unsigned int linesize;		/* Number of valid characters in line[] */
	char line[VERSION_LINELEN];	/* Pre-allocated buffer for formatted lines */
};

/****************************************************************************
 * Private Function Prototypes
 ****************************************************************************/

/* File system methods */

static int version_open(FAR struct file *filep, FAR const char *relpath, int oflags, mode_t mode);
static int version_close(FAR struct file *filep);
static ssize_t version_read(FAR struct file *filep, FAR char *buffer, size_t buflen);

static int version_dup(FAR const struct file *oldp, FAR struct file *newp);

static int version_stat(FAR const char *relpath, FAR struct stat *buf);

/****************************************************************************
 * Private Variables
 ****************************************************************************/

/****************************************************************************
 * Public Variables
 ****************************************************************************/

/* See fs_mount.c -- this structure is explicitly externed there.
 * We use the old-fashioned kind of initializers so that this will compile
 * with any compiler.
 */

const struct procfs_operations version_operations = {
	version_open,				/* open */
	version_close,				/* close */
	version_read,				/* read */
	NULL,						/* write */

	version_dup,				/* dup */

	NULL,						/* opendir */
	NULL,						/* closedir */
	NULL,						/* readdir */
	NULL,						/* rewinddir */

	version_stat				/* stat */
};

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/****************************************************************************
 * Name: version_open
 ****************************************************************************/

static int version_open(FAR struct file *filep, FAR const char *relpath, int oflags, mode_t mode)
{
	FAR struct version_file_s *attr;

	fvdbg("Open '%s'\n", relpath);

	/* PROCFS is read-only.  Any attempt to open with any kind of write
	 * access is not permitted.
	 *
	 * REVISIT:  Write-able proc files could be quite useful.
	 */

	if ((oflags & O_WRONLY) != 0 || (oflags & O_RDONLY) == 0) {
		fdbg("ERROR: Only O_RDONLY supported\n");
		return -EACCES;
	}

	/* "version" is the only acceptable value for the relpath */

	if (strcmp(relpath, "version") != 0) {
		fdbg("ERROR: relpath is '%s'\n", relpath);
		return -ENOENT;
	}

	/* Allocate a container to hold the file attributes */

	attr = (FAR struct version_file_s *)kmm_zalloc(sizeof(struct version_file_s));
	if (!attr) {
		fdbg("ERROR: Failed to allocate file attributes\n");
		return -ENOMEM;
	}

	/* Save the attributes as the open-specific state in filep->f_priv */

	filep->f_priv = (FAR void *)attr;
	return OK;
}

/****************************************************************************
 * Name: version_close
 ****************************************************************************/

static int version_close(FAR struct file *filep)
{
	FAR struct version_file_s *attr;

	/* Recover our private data from the struct file instance */

	attr = (FAR struct version_file_s *)filep->f_priv;
	DEBUGASSERT(attr);

	/* Release the file attributes structure */

	kmm_free(attr);
	filep->f_priv = NULL;
	return OK;
}

/****************************************************************************
 * Name: version_read
 ****************************************************************************/
static ssize_t version_read(FAR struct file *filep, FAR char *buffer, size_t buflen)
{
#define append_version(name, value, e) { \
	size_t linesize = snprintf(attr->line, VERSION_LINELEN, "\t%s: %s", #name, e ? value "\n" : value);	\
	size_t copysize = procfs_memcpy(attr->line, linesize, buffer, remaining, &offset);	\
	totalsize += copysize;	\
	if (e) { \
		buffer += copysize;	\
		remaining -= copysize;	\
	} \
}

	/* Recover our private data from the struct file instance */

	FAR struct version_file_s *attr = (FAR struct version_file_s *)filep->f_priv;
	size_t remaining = buflen;
	size_t totalsize = 0;
	off_t offset;

	fvdbg("buffer=%p buflen=%d\n", buffer, (int)buflen);

	DEBUGASSERT(attr);

	offset = filep->f_pos;

	append_version(Board, CONFIG_VERSION_BOARD, true);
	if (totalsize >= buflen) {
		goto end;
	}

	append_version(Version, CONFIG_VERSION_STRING, true);
	if (totalsize >= buflen) {
		goto end;
	}

	append_version(Commit Hash, CONFIG_VERSION_BUILD, true);
	if (totalsize >= buflen) {
		goto end;
	}

	append_version(Build User, CONFIG_VERSION_BUILD_USER, true);
	if (totalsize >= buflen) {
		goto end;
	}

	append_version(Build Time, CONFIG_VERSION_BUILD_TIME, false);

end:
	if (totalsize > 0) {
		filep->f_pos += totalsize;
	}

	return totalsize;

#undef append_version
}

/****************************************************************************
 * Name: version_dup
 *
 * Description:
 *   Duplicate open file data in the new file structure.
 *
 ****************************************************************************/

static int version_dup(FAR const struct file *oldp, FAR struct file *newp)
{
	FAR struct version_file_s *oldattr;
	FAR struct version_file_s *newattr;

	fvdbg("Dup %p->%p\n", oldp, newp);

	/* Recover our private data from the old struct file instance */

	oldattr = (FAR struct version_file_s *)oldp->f_priv;
	DEBUGASSERT(oldattr);

	/* Allocate a new container to hold the task and attribute selection */

	newattr = (FAR struct version_file_s *)kmm_malloc(sizeof(struct version_file_s));
	if (!newattr) {
		fdbg("ERROR: Failed to allocate file attributes\n");
		return -ENOMEM;
	}

	/* The copy the file attributes from the old attributes to the new */

	memcpy(newattr, oldattr, sizeof(struct version_file_s));

	/* Save the new attributes in the new file structure */

	newp->f_priv = (FAR void *)newattr;
	return OK;
}

/****************************************************************************
 * Name: version_stat
 *
 * Description: Return information about a file or directory
 *
 ****************************************************************************/

static int version_stat(const char *relpath, struct stat *buf)
{
	/* "version" is the only acceptable value for the relpath */

	if (strcmp(relpath, "version") != 0) {
		fdbg("ERROR: relpath is '%s'\n", relpath);
		return -ENOENT;
	}

	/* "version" is the name for a read-only file */

	buf->st_mode = S_IFREG | S_IROTH | S_IRGRP | S_IRUSR;
	buf->st_size = 0;
	buf->st_blksize = 0;
	buf->st_blocks = 0;
	return OK;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

#endif							/* !CONFIG_DISABLE_MOUNTPOINT && CONFIG_FS_PROCFS */
