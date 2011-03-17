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
	mrc	p15, 0, r0, c1, c1, 0		@ Secure configuration register
	bic	r0, r0, #0x7f
	orr	r0, r0, #0x31
	mcr	p15, 0, r0, c1, c1, 0
	movs	pc, lr
