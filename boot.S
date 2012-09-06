/*
 * boot.S - simple register setup code for stand-alone Linux booting
 *
 * Copyright (C) 2011 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

	.syntax	unified
	.arch_extension sec
	.arch_extension virt
	.text

.align 5
/* Once we get rid of monitor.S, use these smc vectors too! */
hyp_vectors:
	.word 0	/* reset */
	.word 0	/* undef */
	.word 0 /* svc */
	.word 0 /* pabt */
	.word 0 /* dabt */
	b	into_hyp_mode /* hvc */
	.word 0 /* irq */
	.word 0 /* fiq */

	.globl	start
start:
#ifdef SMP
#ifdef VEXPRESS
	@
	@ Program architected timer frequency
	@
	mrc	p15, 0, r0, c0, c1, 1		@ CPUID_EXT_PFR1
	lsr	r0, r0, #16
	and	r0, r0, #1			@ Check generic timer support
	beq	1f
	ldr	r0, =24000000			@ 24MHz timer frequency
	mcr	p15, 0, r0, c14, c0, 0		@ CNTFRQ
1:
#endif
	@
	@ CPU initialisation
	@
	mrc	p15, 0, r4, c0, c0, 5		@ MPIDR (ARMv7 only)
	and	r4, r4, #15			@ CPU number

	@
	@ Hypervisor / TrustZone initialization
	@

	@ Set all interrupts to be non-secure
	ldr	r0, =0x2c001000			@ Dist GIC base
	ldr	r1, [r0, #0x04]			@ Type Register
	cmp	r4, #0
	andeq	r1, r1, #0x1f
	movne	r1, #0
	add	r2, r0, #0x080			@ Security Register 0
	mvn	r3, #0
2:	str	r3, [r2]
	sub	r1, r1, #1
	add	r2, r2, #4			@ Next security register
	cmp	r1, #-1
	bne	2b

	@ Set GIC priority mask bit [7] = 1
	ldr	r0, =0x2c002000			@ CPU GIC base
	mov	r1, #0x80
	str	r1, [r0, #0x4]			@ GIC ICCPMR

	@ Set NSACR to allow coprocessor access from non-secure
	mrc	p15, 0, r0, c1, c1, 2
	ldr	r1, =0x43fff
	orr	r0, r0, r1
	mcr	p15, 0, r0, c1, c1, 2

	@ Leave monitor.S trap in place for the transition...
	mov	r0, #0xf0000000
	mcr	p15, 0, r0, c12, c0, 1		@ Monitor vector base address

	@ Set up hvbar so hvc comes back here.
	ldr	r0, =hyp_vectors
	mov	r7, #0xfffffff0
	smc	#0				@ Set HVBAR

	@ We can't call hvc from secure mode, so drop down first.
	mov	r7, #0xffffffff
	smc	#0				@ Change to NS-mode 

	@ This is how we enter hyp mode, for booting the next stage.
	hvc	#0

into_hyp_mode:
	@ Check CPU nr again
	mrc	p15, 0, r0, c0, c0, 5		@ MPIDR (ARMv7 only)
	and	r0, r0, #15			@ CPU number
	cmp	r0, #0				@ primary CPU?
	beq	2f

	@
	@ Secondary CPUs (following the RealView SMP booting protocol)
	@

	ldr	r1, =fs_start - 0x100
	adr	r2, 1f
	ldmia	r2, {r3 - r7}			@ move the code to a location
	stmia	r1, {r3 - r7}			@ less likely to be overridden
#ifdef VEXPRESS
	ldr	r0, =0x1c010030			@ VE SYS_FLAGS register
#else
	ldr	r0, =0x10000030			@ RealView SYS_FLAGS register
#endif
	mov	pc, r1				@ branch to the relocated code
1:
#ifdef VEXPRESS
	wfe
#endif
	ldr	r1, [r0]
	cmp	r1, #0
	beq	1b
	mov	pc, r1				@ branch to the given address
#endif

2:
	@
	@ UART initialisation (38400 8N1)
	@
#ifdef MACH_MPS
	ldr	r0, =0x1f005000			@ UART3 base (MPS)
#elif defined (VEXPRESS)
	ldr	r0, =0x1c090000			@ UART base (Versatile Express)
#else
	ldr	r0, =0x10009000			@ UART base (RealView/EB)
#endif
	mov	r1, #0x10			@ ibrd
	str	r1, [r0, #0x24]
	mov	r1, #0xc300
	orr	r1, #0x0001			@ cr
	str	r1, [r0, #0x30]

	@ Now we've got rid of the secondary CPUs, set up a stack
	@ for CPU 0 so we can write most of this in C.
	ldr     sp, =stacktop

	@ And call the C entrypoint
	bl      c_start
	@ Never reached
1:	b 1b

	@
	@ Function for C code to make semihosting calls:
	@
	.globl __semi_call
__semi_call:
#if defined(MACH_MPS)
	@ M profile semihosting is via bpkt
	bkpt    0xab
#elif defined(__thumb__)
	@ Otherwise, different SVC numbers for ARM or Thumb mode
	svc    0xab
#else
	svc     0x123456
#endif
	mov pc, lr

	@
	@ Data
	@
	/* The kernel boot command line for builtin kernels is defined in the Make system */
	.globl kernel_cmd
	.globl kernel_cmd_end
kernel_cmd:
#ifdef KCMD
	.asciz KCMD
#endif
kernel_cmd_end:
