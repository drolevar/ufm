SHELL := /bin/bash

EDK2_DIR := edk2
BUILD_DIR := $(EDK2_DIR)/Build/Shell

TARGET_ARCH := X64
TOOL_CHAIN := GCC5
JOBS := $(shell nproc)

ifdef DEBUG
  TARGET := DEBUG
else
  TARGET := RELEASE
endif

OUTPUT_DIR := $(BUILD_DIR)/$(TARGET)_$(TOOL_CHAIN)/$(TARGET_ARCH)

define EDK2_BUILD
  cd $(EDK2_DIR) && \
  source edksetup.sh BaseTools && \
  build -p ShellPkg/ShellPkg.dsc \
    -a $(TARGET_ARCH) \
    -t $(TOOL_CHAIN) \
    -b $(TARGET) \
    -n $(JOBS) \
    $(1)
endef

.PHONY: all standalone shell clean

all: standalone shell

standalone:
	@$(call EDK2_BUILD,-m ShellPkg/Application/UfmApp/UfmApp.inf)

shell:
	@$(call EDK2_BUILD,-m ShellPkg/Application/Shell/Shell.inf)

clean:
	rm -rf $(BUILD_DIR)
