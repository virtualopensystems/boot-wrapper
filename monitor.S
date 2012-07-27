/*
 * monitor.S - simple monitor code to switch to NS state before executing kernel
 *
 * Copyright (C) 2011 Columbia University. All rights reserved.
 * 		      Christoffer Dall <cdall@cs.columbia.edu>
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

#.syntax	unified
	.arch_extension virt
	.section monitor, "x"

	.word 0
	.word 0
	b	1f
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	.align 5
vect_hyp:
	nop
	nop
	nop
	nop
	nop
	b	set_hvbar
	nop
	nop

set_hvbar:
	mrc	p15, 4, r12, c5, c2, 0	@ HSR
	lsl	r12, r12, #16
	lsr	r12, r12, #16
	cmp	r12, #0xff
	mcreq	p15, 4, r0, c12, c0, 0	@ HVBAR
	eret

	@
	@ Secure Monitor Call
	@
1:
	ldr	sp, =_monitor_stack
	push	{r11, r12}

	@
	@ Switch to non-secure mode
	@
	mrc	p15, 0, r12, c1, c1, 0		@ Secure configuration register
	bic	r12, r12, #0x07f
	ldr	r11, =0x131
	orr	r12, r12, r11
	mcr	p15, 0, r12, c1, c1, 0
#if 0
	ldr	r11, =0x2c094000
	mov	r12, #0
	str	r12, [r11]
	dsb
#endif
	@
	@ Read/Write HVBAR
	@
	ldr	r11, =vect_hyp
	mcr	p15, 4, r11, c12, c0, 0
	pop	{r11, r12}
	movs	pc, lr

	.ltorg

	/* A bit of stack space for monitor mode */
	.align	12
_monitor_stack:
