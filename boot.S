/*
 * boot.S - simple register setup code for stand-alone Linux booting
 *
 * Copyright (C) 2006 ARM Limited
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

	mov	r0, #0x16000000			@ UART base (Integrator/CP)
	mov	r1, #0x10			@ ibrd
	str	r1, [r0, #0x24]
	mov	r1, #0xc300
	orr	r1, #0x0001			@ cr
	str	r1, [r0, #0x30]

	mov	r0, #0
	mov	r1, #0x13
	orr	r1, r1, #0x100			@ Integrator/CP
	mov	r2, #0
	mov	r3, #0
	mov	lr, #0x8000
	mov     pc, lr				@ jump to the kernel
