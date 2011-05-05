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
	cmp	r12, #0xd
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
	.long	_read_httbr
	.long	_write_httbr
	.long	_read_htcr
	.long	_write_htcr
	.long	_read_hmair0
	.long	_write_hmair0
	.long	_read_hmair1
	.long	_write_hmair1
	.long	_read_hsctlr
	.long	_write_hsctlr
	.long	_read_hypsp
	.long	_write_hypsp

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
_read_hvbar:
	mrc	p15, 4, r0, c12, c0, 0
	movs	pc, lr
_write_hvbar:
	mcr	p15, 4, r0, c12, c0, 0
	movs	pc, lr

	@
	@ Read/Write HTTBR
	@
_read_httbr:
	mrrc	p15, 4, r0, r1, c2
	movs	pc, lr
_write_httbr:
	mcrr	p15, 4, r0, r1, c2
	movs	pc, lr

	@
	@ Read/Write HTCR
	@
_read_htcr:
	mrc	p15, 4, r0, c2, c0, 2
	movs	pc, lr
_write_htcr:
	mcr	p15, 4, r0, c2, c0, 2
	movs	pc, lr

	@
	@ Read/Write HMAIR0/1
	@
_read_hmair0:
	mrc	p15, 4, r0, c10, c2, 0
	movs	pc, lr
_write_hmair0:
	mcr	p15, 4, r0, c10, c2, 0
	movs	pc, lr
_read_hmair1:
	mrc	p15, 4, r0, c10, c2, 1
	movs	pc, lr
_write_hmair1:
	mcr	p15, 4, r0, c10, c2, 1
	movs	pc, lr

	@
	@ Read/Write HSCTLR
	@
_read_hsctlr:
	mrc	p15, 4, r0, c1, c0, 0
	movs	pc, lr
_write_hsctlr:
	mcr	p15, 4, r0, c1, c0, 0
	movs	pc, lr

	@
	@ Read/Write hyp sp
	@
_read_hypsp:
	mov	r0, sp
	movs	pc, lr
_write_hypsp:
	mov	sp, r0
	movs	pc, lr
