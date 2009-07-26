/*
 * Copyright (c) 2002, Red Hat Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#include <reent.h>
#include <stdio.h>

_off_t _ftello_r(struct _reent * ptr, register FILE * fp)
{
  /* for now we simply cast since off_t should be long */
  return (_off_t)_ftell_r (ptr, fp);
}

_off_t ftello(register FILE * fp)
{
  return (_off_t)_ftell_r (_REENT, fp);
}
