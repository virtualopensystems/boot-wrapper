/*
 * boot.S - simple register setup code for stand-alone Linux booting
 *
 * Copyright (C) 2009 ARM Limited
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

	.text

	.globl	_start
_start:
	@
	@ UART initialisation (38400 8N1)
	@
	ldr	r0, =0x10009000			@ UART base (RealView/EB)
	mov	r1, #0x10			@ ibrd
	str	r1, [r0, #0x24]
	mov	r1, #0xc300
	orr	r1, #0x0001			@ cr
	str	r1, [r0, #0x30]

	@
	@ Kernel parameters
	@
	mov	r0, #0
	ldr	r1, =827			@ RealView/EB
	adr	r2, atags
	mov	r3, #0
	ldr	lr, =kernel
@	orr	lr, lr, #1			@ Thumb-2 kernel
	mov     pc, lr				@ jump to the kernel

	.org	0x100
atags:
	@ ATAG_CORE
	.long	2
	.long	0x54410001

	@ ATAG_CMDLINE
	.long	(1f - .) >> 2
	.long	0x54410009
	.asciz	"console=ttyAMA0 mem=256M earlyprintk"
	.align	2
1:

	@ ATAG_INITRD2
	.long	4
	.long	0x54420005
	.long	filesystem
	.long	fs_size

	@ ATAG_NONE
	.long	0
	.long	0x00000000
