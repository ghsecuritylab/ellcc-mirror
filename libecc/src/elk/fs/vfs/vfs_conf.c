/*-
 * Copyright (c) 2005-2007, Kohsuke Ohtani
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the author nor the names of any co-contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * vfs_conf.c - File system configuration.
 */


#include <limits.h>
#include <stdio.h>

#include "config.h"
#include "kernel.h"
#include "mount.h"
#include "vfs.h"
#include "command.h"

/*
 * VFS switch table
 */

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
struct vfssw vfssw[FS_MAX + 1];

int vfs_register(const char *name, int (*init)(void), struct vfsops *vfsops)
{
  pthread_mutex_lock(&mutex);
  int i;
  for (i = 0; i < FS_MAX; ++i) {
    if (vfssw[i].vs_name != NULL)
      continue;

    vfssw[i].vs_name = name;
    vfssw[i].vs_init = init;
    vfssw[i].vs_op = vfsops;
    break;
  }

  if (i >= FS_MAX) {
    i = -EAGAIN;
  } else {
    i = 0;
  }

  pthread_mutex_unlock(&mutex);
  return i;
}

#if defined(VFS_COMMANDS)
/** Create a section heading for the help command.
 */
static int sectionCommand(int argc, char **argv)
{
  if (argc <= 0 ) {
    printf("File system Commands:\n");
  }
  return COMMAND_OK;
}

/*
 * List available file systems.
 */
static int fsCommand(int argc, char **argv)
{
  if (argc <= 0) {
    printf("list all available file systems.\n");
    return COMMAND_OK;
  }

  pthread_mutex_lock(&mutex);
  int i;
  int comma = 0;
  for (i = 0; i < FS_MAX; ++i) {
    if (vfssw[i].vs_name == NULL)
      continue;

    printf("%s%s", comma ? ", " : "", vfssw[i].vs_name);
    comma = 1;
  }

  if (comma)
    printf("\n");

  pthread_mutex_unlock(&mutex);
  return COMMAND_OK;
}
ELK_CONSTRUCTOR()
{
  command_insert(NULL, sectionCommand);
  command_insert("fs", fsCommand);
}
#endif

C_CONSTRUCTOR()
{
  /** Initialize the file system systems.
   * They have been registered during ELK constructor time.
   */
  for (int i = 0; vfssw[i].vs_name; ++i) {
    printf("VFS: initializing %s\n", vfssw[i].vs_name);
    vfssw[i].vs_init();
  }
}
