# Makefile - build a kernel+filesystem image for stand-alone Linux booting
#
# Copyright (C) 2011 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.txt file.

CPPFLAGS	+= -DSMP
#CPPFLAGS	+= -DTHUMB2_KERNEL
CPPFLAGS	+= -march=armv7-a
CPPFLAGS	+= -DVEXPRESS

# Turn this on to use an initrd whose contents are in filesystem.cpio.gz
USE_INITRD = no
ifeq ($(USE_INITRD),yes)
CPPFLAGS	+= -DUSE_INITRD
FILESYSTEM	= filesystem.cpio.gz
else
FILESYSTEM =
endif

# MPS (Cortex-M3) definitions
#CPPFLAGS	+= -DMACH_MPS -DTHUMB2_KERNEL
#CPPFLAGS	+= -march=armv7-m
#CPPFLAGS	+= -mthumb -Wa,-mthumb -Wa,-mimplicit-it=always

# Kernel command line
# MPS:
# KCMD = "rdinit=/bin/sh console=ttyAMA3 mem=4M earlyprintk"
# not-vexpress (ie EB, RealviewPB, etc), with initrd
# KCMD = "console=ttyAMA0 mem=256M earlyprintk"
# not-vexpress, without initrd:
# KCMD = "root=/dev/nfs nfsroot=10.1.77.43:/work/debootstrap/arm ip=dhcp console=ttyAMA0 mem=256M earlyprintk"
# Vexpress, with initrd:
# KCMD = "console=ttyAMA0 mem=512M mem=512M@0x880000000 earlyprintk ip=192.168.27.200::192.168.27.1:255.255.255.0:angstrom:eth0:off"
# VExpress, without initrd:
KCMD ?= "console=ttyAMA0 mem=512M mem=512M@0x880000000 earlyprintk root=/dev/nfs nfsroot=172.31.252.250:/srv/arm-oneiric-root,tcp rw ip=dhcp nfsrootdebug"

MONITOR		= monitor.S
BOOTLOADER	= boot.S
KERNEL_SRC	= ../linux-kvm-arm
KERNEL		= uImage

IMAGE		= linux-system.axf
LD_SCRIPT	= model.lds.S

CROSS_COMPILE	?= arm-unknown-eabi-
ARCH		?= arm

CC		= $(CROSS_COMPILE)gcc
LD		= $(CROSS_COMPILE)ld

# These are needed by the underlying kernel make
export CROSS_COMPILE ARCH

all: $(IMAGE)

clean:
	rm -f $(IMAGE) boot.o model.lds monitor.o uImage

$(KERNEL): $(KERNEL_SRC)/arch/arm/boot/uImage
	$(MAKE) -C $(KERNEL_SRC) -j4 uImage
	cp $< $@

$(IMAGE): boot.o monitor.o model.lds $(KERNEL) $(FILESYSTEM) Makefile
	$(LD) -o $@ --script=model.lds

boot.o: $(BOOTLOADER)
	$(CC) $(CPPFLAGS) -DKCMD='$(KCMD)' -c -o $@ $<

monitor.o: $(MONITOR)
	$(CC) $(CPPFLAGS) -c -o $@ $<

model.lds: $(LD_SCRIPT) Makefile
	$(CC) $(CPPFLAGS) -E -P -C -o $@ $<

.PHONY: all clean
