/* Reentrant versions of write system call. */

#include <config.h>
#include <reent.h>
#include <unistd.h>
#include <_syslist.h>

/* Some targets provides their own versions of this functions.  Those
   targets should define REENTRANT_SYSCALLS_PROVIDED in TARGET_CFLAGS.  */

#ifndef REENTRANT_SYSCALLS_PROVIDED

/* We use the errno variable used by the system dependent layer.  */
#undef errno
extern int errno;

/*
FUNCTION
	<<_write_r>>---Reentrant version of write
	
INDEX
	_write_r

ANSI_SYNOPSIS
	#include <reent.h>
	_ssize_t _write_r(struct _reent *<[ptr]>,
		          int <[fd]>, const void *<[buf]>, size_t <[cnt]>);

TRAD_SYNOPSIS
	#include <reent.h>
	_ssize_t _write_r(<[ptr]>, <[fd]>, <[buf]>, <[cnt]>)
	struct _reent *<[ptr]>;
	int <[fd]>;
	char *<[buf]>;
	size_t <[cnt]>;

DESCRIPTION
	This is a reentrant version of <<write>>.  It
	takes a pointer to the global data block, which holds
	<<errno>>.
*/

_ssize_t _write_r(struct _reent *ptr, int fd, const void * buf, size_t cnt)
{
  _ssize_t ret;

  errno = 0;
  if ((ret = (_ssize_t)_write (fd, buf, cnt)) == -1 && errno != 0)
    ptr->_errno = errno;
  return ret;
}

#endif /* ! defined (REENTRANT_SYSCALLS_PROVIDED) */
