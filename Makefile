#
# Makefile - build a kernel+filesystem image for stand-alone Linux booting
#
# Copyright (C) 2012 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.txt file.

# VE
PHYS_OFFSET	:= 0x80000000
UART_BASE	:= 0x1c090000
GIC_DIST_BASE	:= 0x2c001000
GIC_CPU_BASE	:= 0x2c002000
CNTFRQ		:= 0x01800000	# 24Mhz

#INITRD_FLAGS	:= -DUSE_INITRD
CPPFLAGS	+= $(INITRD_FLAGS)

BOOTLOADER	:= boot.S
MBOX_OFFSET	:= 0xfff8
KERNEL		:= Image
KERNEL_OFFSET	:= 0x80000
LD_SCRIPT	:= model.lds.S
IMAGE		:= linux-system.axf

FILESYSTEM	:= filesystem.cpio.gz
FS_OFFSET	:= 0x10000000
FILESYSTEM_START:= $(shell echo $$(($(PHYS_OFFSET) + $(FS_OFFSET))))
FILESYSTEM_SIZE	:= $(shell stat -Lc %s $(FILESYSTEM) 2>/dev/null || echo 0)
FILESYSTEM_END	:= $(shell echo $$(($(FILESYSTEM_START) + $(FILESYSTEM_SIZE))))

FDT_SRC		:= rtsm_ve-aemv8a.dts
FDT_INCL_REGEX	:= \(/include/[[:space:]]*"\)\([^"]\+\)\(".*\)
FDT_DEPS	:= $(FDT_SRC) $(addprefix $(dir $(FDT_SRC)), $(shell sed -ne 'sq$(strip $(FDT_INCL_REGEX)q\2q p' < $(FDT_SRC))))
FDT_OFFSET	:= 0x08000000

ifneq (,$(findstring USE_INITRD,$(CPPFLAGS)))
BOOTARGS	:= "console=ttyAMA0 $(BOOTARGS_EXTRA)"
CHOSEN_NODE	:= chosen {						\
			bootargs = \"$(BOOTARGS)\";			\
			linux,initrd-start = <$(FILESYSTEM_START)>;	\
			linux,initrd-end = <$(FILESYSTEM_END)>;		\
		   };
else
BOOTARGS	:= "console=ttyAMA0 root=/dev/nfs nfsroot=10.1.69.68:/work/debootstrap/aarch64,tcp rw ip=dhcp $(BOOTARGS_EXTRA)"
CHOSEN_NODE	:= chosen {						\
			bootargs = \"$(BOOTARGS)\";			\
		   };
endif

CROSS_COMPILE	:= aarch64-none-linux-gnu-
CC		:= $(CROSS_COMPILE)gcc
LD		:= $(CROSS_COMPILE)ld
DTC		:= $(if $(wildcard ./dtc), ./dtc, $(shell which dtc))

all: $(IMAGE)

clean:
	rm -f $(IMAGE) boot.o model.lds fdt.dtb

$(IMAGE): boot.o model.lds fdt.dtb $(KERNEL) $(FILESYSTEM)
	$(LD) -o $@ --script=model.lds

boot.o: $(BOOTLOADER) Makefile
	$(CC) $(CPPFLAGS) -DCNTFRQ=$(CNTFRQ) -DUART_BASE=$(UART_BASE) -DSYS_FLAGS=$(SYS_FLAGS) -DGIC_DIST_BASE=$(GIC_DIST_BASE) -DGIC_CPU_BASE=$(GIC_CPU_BASE) -c -o $@ $(BOOTLOADER)

model.lds: $(LD_SCRIPT) Makefile
	$(CC) $(CPPFLAGS) -DPHYS_OFFSET=$(PHYS_OFFSET) -DMBOX_OFFSET=$(MBOX_OFFSET) -DKERNEL_OFFSET=$(KERNEL_OFFSET) -DFDT_OFFSET=$(FDT_OFFSET) -DFS_OFFSET=$(FS_OFFSET) -DKERNEL=$(KERNEL) -DFILESYSTEM=$(FILESYSTEM) -E -P -C -o $@ $<

ifeq ($(DTC),)
	$(error No dtc found! You can git clone from git://git.jdl.com/software/dtc.git)
endif

fdt.dtb: $(FDT_DEPS) Makefile
	( echo "/include/ \"$(FDT_SRC)\"" ; echo "/ { $(CHOSEN_NODE) };" ) | $(DTC) -O dtb -o $@ -

# The filesystem archive might not exist if INITRD is not being used
.PHONY: all clean $(FILESYSTEM)
