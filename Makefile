# Build an ELF linux+filesystem image

BOOTLOADER	= boot.S
KERNEL		= uImage
FILESYSTEM	= filesystem.cpio.gz

IMAGE		= linux-system.axf
LD_SCRIPT	= model.lds

CROSS_COMPILE	= arm-none-linux-gnueabi-

CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld

all: $(IMAGE)

clean:
	rm -f $(IMAGE) boot.o

$(IMAGE): boot.o $(LD_SCRIPT) $(KERNEL) $(FILESYSTEM)
	$(LD) -o $@ --script=$(LD_SCRIPT)

boot.o: $(BOOTLOADER)
	$(CC) -c -o $@ $<
