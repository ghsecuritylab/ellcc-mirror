/*-
 * Copyright (c) 2005-2009, Kohsuke Ohtani
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

#ifndef _context_h_
#define _context_h_

#ifndef __ASSEMBLER__
#include <sys/types.h>

#include "config.h"

/** ARM register reference:
 *
 *  Name    Number  ARM Procedure Calling Standard Role
 *
 *  a1      r0     argument 1 / integer result / scratch register / argc
 *  a2      r1     argument 2 / scratch register / argv
 *  a3      r2     argument 3 / scratch register / envp
 *  a4      r3     argument 4 / scratch register
 *  v1      r4     register variable
 *  v2      r5     register variable
 *  v3      r6     register variable
 *  v4      r7     register variable
 *  v5      r8     register variable
 *  sb/v6   r9     static base / register variable
 *  sl/v7   r10    stack limit / stack chunk handle / reg. variable
 *  fp      r11    frame pointer
 *  ip      r12    scratch register / new-sb in inter-link-unit calls
 *  sp      r13    lower end of current stack frame
 *  lr      r14    link address / scratch register
 *  pc      r15    program counter
 */

/** Common register frame for trap/interrupt.
 * The cpu state is saved on the top of the kernel stack on
 * trap/interrupt entry.
 */
typedef struct context {
  uint32_t r0;                          //  +0 (00)
  uint32_t r1;                          //  +4 (04)
  uint32_t r2;                          //  +8 (08)
  uint32_t r3;                          // +12 (0C)
  uint32_t r4;                          // +16 (10)
  uint32_t r5;                          // +20 (14)
  uint32_t r6;                          // +24 (18)
  uint32_t r7;                          // +28 (1C)
  uint32_t r8;                          // +32 (20)
  uint32_t r9;                          // +36 (24)
  uint32_t r10;                         // +40 (28)
  uint32_t r11;                         // +44 (2C)
  uint32_t r12;                         // +48 (30)
  uint32_t lr;                          // +52 (34)
  char *sp;                             // +56 (38)
  char *tls;                            // +60 (3C)
  uint32_t pc;                          // +64 (40)
  uint32_t cpsr;                        // +68 (44)
} context_t;

#if ELK_NAMESPACE
#define context_set_return __elk_context_set_return
#endif

static inline void context_set_return(context_t *cp, int value)
{
  cp->r0 = value;
}

#endif // !__ASSEMBLER__

/** Register offset in cpu_regs
 */
#define REG_R0          0x00
#define REG_R1          0x04
#define REG_R2          0x08
#define REG_R3          0x0c
#define REG_R4          0x10
#define REG_R5          0x14
#define REG_R6          0x18
#define REG_R7          0x1c
#define REG_LR          0x34
#define REG_SP          0x38
// 0x3c is empty.
#define REG_PC          0x40
#define REG_CPSR        0x44

#define CTXREGS (4*18)

#endif // _context_h_
