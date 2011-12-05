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
	.text

	.globl	_start
_start:
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

	@ Change to NS-mode
	mov	r0, #0xf0000000
	mcr	p15, 0, r0, c12, c0, 1		@ Monitor vector base address
	mov	r7, #0xffffffff
	smc	#0				@ Change to NS-mode 

	@ Check CPU nr again
	mrc	p15, 0, r0, c0, c0, 5		@ MPIDR (ARMv7 only)
	and	r0, r0, #15			@ CPU number
	cmp	r0, #0				@ primary CPU?
	beq	2f

	@
	@ Secondary CPUs (following the RealView SMP booting protocol)
	@

	ldr	r1, =filesystem - 0x100
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

	@
	@ Kernel parameters
	@
	mov	r0, #0
#ifdef MACH_MPS
	ldr	r1, =10000			@ MPS (temporary)
#elif defined (VEXPRESS)
	ldr	r1, =2272			@ Versatile Express
#else
	ldr	r1, =827			@ RealView/EB
#endif
	adr	r2, atags
	mov	r3, #0
	ldr	lr, =kernel
#ifdef THUMB2_KERNEL
	orr	lr, lr, #1			@ Thumb-2 kernel
#endif
	mov     pc, lr				@ jump to the kernel

	.org	0x100
atags:
	@ ATAG_CORE
	.long	2
	.long	0x54410001

	@ ATAG_CMDLINE
	.long	(1f - .) >> 2
	.long	0x54410009
#ifdef KCMD
        /* User-specified command line always overrides */
        .asciz KCMD
#else
#ifdef MACH_MPS
	.asciz	"rdinit=/bin/sh console=ttyAMA3 mem=4M earlyprintk"
#elif defined(VEXPRESS)

#ifdef USE_INITRD
	.asciz	"console=ttyAMA0 mem=512M mem=512M@0x880000000 earlyprintk ip=192.168.27.200::192.168.27.1:255.255.255.0:angstrom:eth0:off"
#else /* VEXPRESS && !USE_INITRD */
	.asciz	"console=ttyAMA0 mem=512M mem=512M@0x880000000 earlyprintk root=/dev/nfs nfsroot=192.168.27.93:/srv/nfs_root,tcp rw ip=dhcp nfsrootdebug"
#endif

#else /* ! VEXPRESS && ! MACH_MPS */

#ifdef USE_INITRD
	.asciz	"console=ttyAMA0 mem=256M earlyprintk"
#else
	.asciz	"root=/dev/nfs nfsroot=10.1.77.43:/work/debootstrap/arm ip=dhcp console=ttyAMA0 mem=256M earlyprintk"
#endif

#endif
#endif
	.align	2
1:

#ifdef USE_INITRD
	@ ATAG_INITRD2
	.long	4
	.long	0x54420005
	.long	filesystem
	.long	fs_size
#endif

	@ ATAG_NONE
	.long	0
	.long	0x00000000
