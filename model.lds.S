/*
 * model.lds.S - simple linker script for stand-alone Linux booting
 *
 * Copyright (C) 2011 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
TARGET(binary)

INPUT(./monitor.o)
INPUT(./boot.o)
INPUT(./uImage)
#ifdef USE_INITRD
 INPUT(./filesystem.cpio.gz)
#endif




PHYS_OFFSET = 0x80000000;
MON_OFFSET  = 0xf0000000;




SECTIONS
{
 . = PHYS_OFFSET;
 .text : { boot.o }

 . = PHYS_OFFSET + 0x8000 - 0x40;
 kernel = . + 0x40;
 .kernel : { ./uImage }

 . = PHYS_OFFSET + 0x00800000;
 filesystem = .;
#ifdef USE_INITRD
 .filesystem : { ./filesystem.cpio.gz }
 fs_size = . - filesystem;
#endif

 .data : { *(.data) }
 .bss : { *(.bss) }

 . = MON_OFFSET;
 .monitor : { monitor.o }
}
