/*
 * Copyright (c) 2012 Linaro Limited
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Linaro Limited nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 */

/* This file just contains a small glue function which fishes the
 * location of kernel etc out of linker script defined symbols, and
 * calls semi_loader functions to do the actual work of loading
 * and booting the kernel.
 */

#include <stdint.h>
#include "semihosting.h"
#include "semi_loader.h"

/* Linker script defined symbols for any preloaded kernel/initrd */
extern uint8_t fs_start, fs_end, kernel_entry, kernel_start, kernel_end;
/* Symbols defined by boot.S */
extern uint8_t kernel_cmd, kernel_cmd_end;

static struct loader_info loader;

#ifdef MACH_MPS
#define PLAT_ID 10000 /* MPS (temporary) */
#elif defined (VEXPRESS)
#define PLAT_ID 2272 /* Versatile Express */
#else
#define PLAT_ID 827 /* RealView/EB */
#endif

void c_start(void)
{
	/* Main C entry point */
	loader.kernel_size = (uint32_t)&kernel_end - (uint32_t)&kernel_start;
	loader.initrd_start = (uint32_t)&fs_start;
	loader.initrd_size = (uint32_t)&fs_end - (uint32_t)&fs_start;
	loader.kernel_entry = (uint32_t)&kernel_entry;
	if (loader.kernel_size) {
		loader.cmdline_start = (uint32_t)&kernel_cmd;
		loader.cmdline_size = &kernel_cmd_end - &kernel_cmd;
	}
	load_kernel(&loader);

	/* Start the kernel */
	if(loader.fdt_start) {
		boot_kernel(&loader, 0, -1, loader.fdt_start, 0);
	} else {
		boot_kernel(&loader, 0, PLAT_ID, loader.atags_start, 0);
	}

	semi_write0("[bootwrapper] ERROR: returned from boot_kernel\n");
}
