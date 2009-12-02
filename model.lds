start = 0x00400000;

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
TARGET(binary)

INPUT(./uImage)
INPUT(./boot.bin)
INPUT(./base.cramfs)

SECTIONS
{
	. = 0x00007fc0;
	.text.kernel : { ./uImage *(.text) }

	. = 0x00400000;
	.text.boot : { ./boot.bin *(.text) }

	. = 0x00800000;
	.text.filesystem : { ./base.cramfs *(.text) }

	.data : { *(.data) }
	.bss : { *(.bss) }
}
