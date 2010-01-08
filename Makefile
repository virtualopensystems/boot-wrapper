# Build an ELF linux+filesystem image

CPPFLAGS	+= -DSMP
#CPPFLAGS	+= -DUSE_INITRD
#CPPFLAGS	+= -DTHUMB2_KERNEL

BOOTLOADER	= boot.S
KERNEL		= uImage
FILESYSTEM	= filesystem.cpio.gz

IMAGE		= linux-system.axf
LD_SCRIPT	= model.lds.S

CROSS_COMPILE	= arm-none-linux-gnueabi-

CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld

all: $(IMAGE)

clean:
	rm -f $(IMAGE) boot.o model.lds

$(IMAGE): boot.o model.lds $(KERNEL) $(FILESYSTEM)
	$(LD) -o $@ --script=model.lds

boot.o: $(BOOTLOADER)
	$(CC) $(CPPFLAGS) -c -o $@ $<

model.lds: $(LD_SCRIPT)
	$(CC) $(CPPFLAGS) -E -P -C -o $@ $<
