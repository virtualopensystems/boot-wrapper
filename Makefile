# Makefile - build a kernel+filesystem image for stand-alone Linux booting
#
# Copyright (C) 2011 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.txt file.


# Include config file (prefer config.mk, fall back to config-default.mk)
ifneq ($(wildcard config.mk),)
include config.mk
else
include config-default.mk
endif

MONITOR		= monitor.S
BOOTLOADER	= boot.S
KERNEL		= uImage

IMAGE		= linux-system.axf
SEMIIMG 	= linux-system-semi.axf
LD_SCRIPT	= model.lds.S


CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld

# These are needed by the underlying kernel make
export CROSS_COMPILE ARCH

# Build all wrappers
all: $(IMAGE) $(SEMIIMG)
	true

# Build just the semihosting wrapper
semi: $(SEMIIMG)
	true

clean distclean:
	rm -f $(IMAGE) $(SEMIIMG) \
	boot.o model.lds monitor.o uImage \
	bootsemi.o monitor.o modelsemi.lds

$(KERNEL): $(KERNEL_SRC)/arch/arm/boot/uImage
	cp $< $@

$(IMAGE): boot.o monitor.o model.lds $(KERNEL) $(FILESYSTEM) Makefile
	$(LD) -o $@ --script=model.lds

$(SEMIIMG): bootsemi.o monitor.o modelsemi.lds
	$(LD) -o $@ --script=modelsemi.lds

boot.o: $(BOOTLOADER)
	$(CC) $(CPPFLAGS) -DKCMD='$(KCMD)' -c -o $@ $<

bootsemi.o: $(BOOTLOADER)
	$(CC) $(CPPFLAGS) -DSEMIHOSTING=1 -c -o $@ $<

monitor.o: $(MONITOR)
	$(CC) $(CPPFLAGS) -c -o $@ $<

model.lds: $(LD_SCRIPT) Makefile
	$(CC) $(CPPFLAGS) -E -P -C -o $@ $<

modelsemi.lds: $(LD_SCRIPT) Makefile
	$(CC) $(CPPFLAGS) -DSEMIHOSTING=1 -E -P -C -o $@ $<

$(KERNEL_SRC)/arch/arm/boot/uImage: force
	$(MAKE) -C $(KERNEL_SRC) -j4 uImage

# Pass any target we don't know about through to the kernel makefile.
# This is a convenience rule so we can say 'make menuconfig' etc here.
# Note that any rules in this file must have a command.
%: force
	$(MAKE) -C $(KERNEL_SRC) $@

force: ;

Makefile: ;

.PHONY: all clean config.mk config-default.mk
