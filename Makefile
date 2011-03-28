# Makefile - build a kernel+filesystem image for stand-alone Linux booting
#
# Copyright (C) 2011 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.txt file.

CPPFLAGS	+= -DSMP
CPPFLAGS	+= -DUSE_INITRD
#CPPFLAGS	+= -DTHUMB2_KERNEL
CPPFLAGS	+= -march=armv7-a
CPPFLAGS	+= -DVEXPRESS

# MPS (Cortex-M3) definitions
#CPPFLAGS	+= -DMACH_MPS -DTHUMB2_KERNEL
#CPPFLAGS	+= -march=armv7-m
#CPPFLAGS	+= -mthumb -Wa,-mthumb -Wa,-mimplicit-it=always

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
