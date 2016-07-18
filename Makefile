###########################################################################
#
#  Copyright (c) 2013-2015, ARM Limited, All Rights Reserved
#  SPDX-License-Identifier: Apache-2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License"); you may
#  not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
# App
APP:=mbed-os-example-uvisor

# Toolchain
PREFIX:=arm-none-eabi-
GDB:=$(PREFIX)gdb
OBJDUMP:=$(PREFIX)objdump
NM:=$(PREFIX)nm

ifeq ("$(MBED_TARGET)","")
	MBED_TARGET:=K64F_SECURE
endif
ifeq ("$(MBED_TOOLCHAIN)","")
	MBED_TOOLCHAIN:=GCC_ARM
endif

# set JLINK CPU based on ARCH
ifeq ("$(MBED_TARGET)","K64F_SECURE")
	CPU:=MK64FN1M0XXX12
	UVISOR_PLATFORM:=kinetis
	UVISOR_CONFIGURATION:=configuration_kinetis_m4_0x1fff0000
endif
ifeq ("$(MBED_TARGET)","EFM32GG_STK3700_SECURE")
	CPU:=EFM32GG990F1024
	UVISOR_PLATFORM:=efm32
	UVISOR_CONFIGURATION:=configuration_efm32_m3_p1
endif

# JLink settings
JLINK:=$(SEGGER)JLinkExe
JLINK_CFG:=-Device $(CPU) -if SWD
JLINK_SERVER:=$(SEGGER)JLinkGDBServer
DEBUG_HOST:=localhost:2331

# Paths
TARGET:=.build/$(MBED_TARGET)/$(MBED_TOOLCHAIN)/$(APP)
TARGET_ELF:=$(TARGET).elf
TARGET_BIN:=$(TARGET).bin
TARGET_ASM:=$(TARGET).asm
DEBUG_ELF:=debug.elf

# detect SEGGER JLINK mass storages
SEGGER_DET:=Segger.html
FW_DIR:=$(wildcard /Volumes/JLINK/$(FW_DET))
ifeq ("$(wildcard $(SEGGER_DIR))","")
	FW_DIR:=$(wildcard /run/media/$(USER)/JLINK/$(FW_DET))
endif
ifeq ("$(wildcard $(FW_DIR))","")
	FW_DIR:=$(wildcard /var/run/media/$(USER)/JLINK/$(FW_DET))
endif

# detect mbed DAPLINK mass storages
MBED_DET:=MBED.HTM
ifeq ("$(wildcard $(FW_DIR))","")
	FW_DIR:=$(wildcard /Volumes/*/$(MBED_DET))
endif
ifeq ("$(wildcard $(FW_DIR))","")
	FW_DIR:=$(wildcard /run/media/$(USER)/*/$(MBED_DET))
endif
ifeq ("$(wildcard $(FW_DIR))","")
	FW_DIR:=$(wildcard /var/run/media/$(USER)/*/$(MBED_DET))
endif
ifeq ("$(wildcard $(FW_DIR))","")
	FW_DIR:=./
else
	FW_DIR:=$(dir $(firstword $(FW_DIR)))
endif

# Read uVisor symbols.
UVISOR_LIB:=mbed-os/core/features/FEATURE_UVISOR
GDB_DEBUG_UVISOR=add-symbol-file $(DEBUG_ELF) uvisor_init

# GDB scripts
include Makefile.scripts

.PHONY: all clean uvisor_clean debug release uvisor debug gdbserver gdb.script

all: release install

clean:
	rm -rf .build gdb.script $(DEBUG_ELF) firmware.asm firmware.bin

install: $(TARGET_BIN)
	cp $^ $(FW_DIR)firmware.bin
	sync

debug:
	cp $(UVISOR_LIB)/importer/TARGET_IGNORE/uvisor/platform/$(UVISOR_PLATFORM)/debug/$(UVISOR_CONFIGURATION).elf $(DEBUG_ELF)
	mbed compile -t $(MBED_TOOLCHAIN) -m $(MBED_TARGET) -j 0 $(NEO) -o "debug-info"

release:
	cp $(UVISOR_LIB)/importer/TARGET_IGNORE/uvisor/platform/$(UVISOR_PLATFORM)/release/$(UVISOR_CONFIGURATION).elf $(DEBUG_ELF)
	mbed compile -t $(MBED_TOOLCHAIN) -m $(MBED_TARGET) -j 0 $(NEO)

objdump: $(TARGET_ASM)

$(TARGET_ASM): $(TARGET_ELF) $(DEBUG_ELF)
	$(OBJDUMP) -wSd -j .text -Mforce-thumb $(DEBUG_ELF) > $@ 
	$(OBJDUMP) -wSd -j .text -Mforce-thumb --start-address=0x$$($(NM) $(TARGET_ELF) | grep ' uvisor_config$$' | cut -d\  -f1) $(TARGET_ELF) >> $@

gdbserver:
	$(JLINK_SERVER) $(JLINK_CFG)

uvisor:
	make -C $(UVISOR_LIB)/importer

uvisor_clean:
	make -C $(UVISOR_LIB)/importer clean

gdb: gdb.script
	$(GDB) -x $<

gdb.script:
	@echo "$$__SCRIPT_GDB" > $@
