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
	.section monitor, "x"

	.word 0
	.word 0
	b	1f
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

	@
	@ Secure Monitor Call
	@
1:
	ldr	sp, =_monitor_stack
	push	{r11, r12}

	cmp	r7, #0xffffffff
	beq	_non_sec

	@ Check smc number and VMID
	bic	r12, r7, #0xf
	cmp	r12, #0xfffffff0
	movnes	pc, lr
	and	r12, r7, #0xf
	cmp	r12, #0x0
	popgt	{r11, r12}
	movgts	pc, lr

	@ Check the VMID is 0
	mrrc	p15, 6, r12, r11, c2
	lsr	r11, r11, #16
	and	r11, r11, #0xff
	cmp	r11, #0
	popne	{r11, r12}
	movnes	pc, lr

	@ Jump to the right function
	and	r12, r7, #0xf
	adr	r11, _hyp_funcs
	add	r11, r11, r12, lsl #2
	ldr	pc, [r11]

	@
	@ Jump table for the SMC hypervisor API calls
	@
_hyp_funcs:
	.long	_write_hvbar

	@
	@ Switch to non-secure mode
	@
_non_sec:
	mrc	p15, 0, r12, c1, c1, 0		@ Secure configuration register
	bic	r12, r12, #0x07f
	ldr	r11, =0x131
	orr	r12, r12, r11
	mcr	p15, 0, r12, c1, c1, 0
	pop	{r11, r12}
	movs	pc, lr

	@
	@ Read/Write HVBAR
	@
_write_hvbar:
	mcr	p15, 4, r0, c12, c0, 0
	pop	{r11, r12}
	movs	pc, lr

	.ltorg

	/* A bit of stack space for monitor mode */
	.align	12
_monitor_stack:
