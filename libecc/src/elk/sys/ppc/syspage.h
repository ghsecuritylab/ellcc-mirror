/*-
 * Copyright (c) 2008-2009, Kohsuke Ohtani
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

#ifndef _syspage_h_
#define _syspage_h_

/**
 * syspage layout:
 *
 * +------------------+ __syspage_base__
 * | Vector page      |
 * |                  |
 * |                  |
 * |                  |
 * |                  |
 * |                  |
 * +------------------+ +0x3000
 * | Interrupt stack  |
 * |                  |
 * |                  |
 * +------------------+ +0x4000
 * | Boot information |
 * +------------------+ +0x4400
 * | Boot stack       |
 * +------------------+ +0x5000
 * | PGD for boot     |
 * | (MMU only)       |
 * |                  |
 * +------------------+ +0x6000
 * | PTE0 for boot    |
 * | (MMU only)       |
 * |                  |
 * +------------------+ +0x7000
 *
 * Note: Interrupt stack should be placed after NULL page
 * to detect the stack overflow.
 */

#ifdef __ASSEMBLER__
#define SYSPAGE         __syspage_base__
#define SYSPHYSPAGE     __syspage_physical_base__
#else
extern char __syspage_base__[];         // Defined at link time.
extern char __syspage_physical_base__[];
#define SYSPAGE         ((paddr_t)__syspage_base__)
#define SYSPHYSPAGE     ((paddr_t)__syspage_physical_base__)
#define SYSPAGESZ       (mmu_enabled() ? 0x7000 : 0x5000)
#endif // __ASSEMBLER__

#define INTSTK          (SYSPAGE + 0x3000)
#define BOOTINFO        (SYSPAGE + 0x4000)
#define BOOTSTK         (SYSPAGE + 0x4400)
#define BOOT_PGD        (SYSPAGE + 0x5000)
#define BOOT_PTE0       (SYSPAGE + 0x6000)

#define BOOT_PGD_PHYS   ((SYSPHYSPAGE + 0x5000)
#define BOOT_PTE0_PHYS  ((SYSPHYSPAGE + 0x6000)

#define INTSTKSZ        0x1000          // Size of interrupt stack.
#define BOOTSTKSZ       0x0c00          // Size of boot stack.

#define INTSTKTOP       (INTSTK + INTSTKSZ)
#define BOOTSTKTOP      (BOOTSTK + BOOTSTKSZ)

#endif // !_syspage_h_
