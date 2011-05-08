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
	cmp	r7, #0xffffffff
	beq	_non_sec

	@ Check smc number and VMID
	bic	r12, r7, #0xf
	cmp	r12, #0xfffffff0
	movnes	pc, lr
	and	r12, r7, #0xf
	cmp	r12, #0x0
	movgts	pc, lr

	@ Check the VMID is 0
	mrrc	p15, 6, r12, r13, c2
	lsr	r13, r13, #16
	and	r13, r13, #0xff
	cmp	r13, #0
	movnes	pc, lr

	@ Jump to the right function
	and	r12, r7, #0xf
	adr	r13, _hyp_funcs
	add	r13, r13, r12, lsl #2
	ldr	pc, [r13]

	@
	@ Jump table for the SMC hypervisor API calls
	@
_hyp_funcs:
	.long	_write_hvbar

	@
	@ Switch to non-secure mode
	@
_non_sec:
	mrc	p15, 0, r0, c1, c1, 0		@ Secure configuration register
	bic	r0, r0, #0x07f
	ldr	r13, =0x131
	orr	r0, r0, r13
	mcr	p15, 0, r0, c1, c1, 0
	movs	pc, lr

	@
	@ Read/Write HVBAR
	@
_write_hvbar:
	mcr	p15, 4, r0, c12, c0, 0
	movs	pc, lr
