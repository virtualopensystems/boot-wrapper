/*
 * boot.S - simple register setup code for stand-alone Linux booting
 *
 * Copyright (C) 2009 ARM Limited
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

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
TARGET(binary)

INPUT(./uImage)
INPUT(./filesystem.cpio.gz)
INPUT(./boot.o)

PHYS = 0x70000000;

SECTIONS
{
	. = PHYS;
	.text : { boot.o }

	. = PHYS + 0x8000 - 0x40;
	kernel = . + 0x40;
	.kernel : { ./uImage }

	. = PHYS + 0x00800000;
	filesystem = .;
	.filesystem : { ./filesystem.cpio.gz }
	fs_size = . - filesystem;

	.data : { *(.data) }
	.bss : { *(.bss) }
}
