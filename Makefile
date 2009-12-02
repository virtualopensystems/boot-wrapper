# Build an ELF linux+filesystem image

BOOTLOADER	= boot.bin
KERNEL		= uImage
FILESYSTEM	= base.cramfs

IMAGE		= linux-system.axf
LD_SCRIPT	= model.lds

CROSS_COMPILE	= arm-none-linux-gnueabi-

CC		= $(CROSS_COMPILE)gcc
AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)ld
OBJCOPY		= $(CROSS_COMPILE)objcopy

all: $(IMAGE)

clean:
	rm -f $(IMAGE)

$(IMAGE): $(BOOTLOADER) $(KERNEL) $(FILESYSTEM) $(LD_SCRIPT)
	$(LD) -o $@ --script=$(LD_SCRIPT)

boot.bin: boot.o
	$(OBJCOPY) -O binary -S $< $@

boot.o: boot.S
	$(AS) -o $@ $<
