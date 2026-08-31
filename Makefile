TARGET := rtos

# ============================================================
# TI TOOLS
# ============================================================

TI_ROOT := /Applications/ti
TI_ARM_CLANG := $(TI_ROOT)/ccs2020/ccs/tools/compiler/ti-cgt-armllvm_4.0.3.LTS/bin/tiarmclang
TI_ARM_OBJCOPY := $(TI_ROOT)/ccs2020/ccs/tools/compiler/ti-cgt-armllvm_4.0.3.LTS/bin/tiarmobjcopy
TI_ARM_LIB_DIR := $(TI_ROOT)/ccs2020/ccs/tools/compiler/ti-cgt-armllvm_4.0.3.LTS/lib
SYSCONFIG := $(TI_ROOT)/ccs2020/ccs/utils/sysconfig_1.24.0/sysconfig_cli.sh

# Use the SDK copied into this project instead of any external install.
SDK_DIR := $(CURDIR)/mspm0_sdk_2_03_00_07
SDK_STARTUP_SRC := $(SDK_DIR)/source/ti/devices/msp/m0p/startup_system_files/ticlang/startup_mspm0g350x_ticlang.c
SDK_LINKER_CMD := $(SDK_DIR)/source/ti/devices/msp/m0p/linker_files/ticlang/mspm0g3507.cmd
SDK_DRIVERLIB := $(SDK_DIR)/source/ti/driverlib/lib/ticlang/m0p/mspm0g1x0x_g3x0x/driverlib.a


# ============================================================
# DIRECTORIES
# ============================================================

BUILD := build
SYSCFG_BUILD := $(BUILD)/syscfg

SRC_DIR := .
INC_DIR := .
RTOS_DIR := rtos


# ============================================================
# SOURCE FILES
# ============================================================

C_SRCS := main.c rtos/rtos.c
ASM_SRCS := rtos/context.s rtos/startup.s

C_OBJS := $(patsubst %.c,$(BUILD)/%.o,$(notdir $(C_SRCS)))
ASM_OBJS := $(patsubst %.s,$(BUILD)/%.o,$(notdir $(ASM_SRCS)))
SDK_STARTUP_OBJ := $(BUILD)/startup_mspm0g350x_ticlang.o

OBJS := $(C_OBJS) $(ASM_OBJS) $(SDK_STARTUP_OBJ)

SYSCFG_C_SRCS := $(wildcard $(SYSCFG_BUILD)/*.c)
SYSCFG_OBJS := $(patsubst $(SYSCFG_BUILD)/%.c,$(BUILD)/syscfg_%.o,$(SYSCFG_C_SRCS))


# ============================================================
# COMPILER FLAGS
# ============================================================

CPU := cortex-m0plus

CFLAGS := \
	-mcpu=$(CPU) \
	-mthumb \
	-march=thumbv6m \
	-mfloat-abi=soft \
	-O2 \
	-g \
	-Wall \
	-ffunction-sections \
	-fdata-sections \
	-D__MSPM0G3507__ \
	-I$(INC_DIR) \
	-I$(RTOS_DIR) \
	-I$(SYSCFG_BUILD) \
	-I$(SDK_DIR)/source \
	-I$(SDK_DIR)/source/third_party/CMSIS/Core/Include

LDFLAGS := \
	-mcpu=$(CPU) \
	-mthumb \
	-Wl,-u,_c_int00 \
	-Wl,-l,$(SDK_LINKER_CMD) \
	-Wl,-m,$(BUILD)/$(TARGET).map \
	-Wl,--rom_model \
	-L$(TI_ARM_LIB_DIR)/armv6m-ti-none-eabi/c \
	-llibc.a


# ============================================================
# DEFAULT TARGET
# ============================================================

.PHONY: all
all: $(BUILD)/$(TARGET).out $(BUILD)/$(TARGET).bin


# ============================================================
# SYSCONFIG
# ============================================================

.PHONY: sysconfig
sysconfig:
	@mkdir -p $(SYSCFG_BUILD)

	$(SYSCONFIG) \
		--product "$(SDK_DIR)/.metadata/product.json" \
		--device MSPM0G3507 \
		--script startup/rtos.syscfg \
		--output $(SYSCFG_BUILD)


# ============================================================
# COMPILE USER C
# ============================================================

$(BUILD)/main.o: main.c
	@mkdir -p $(BUILD)
	$(TI_ARM_CLANG) $(CFLAGS) -c $< -o $@

$(BUILD)/rtos.o: rtos/rtos.c
	@mkdir -p $(BUILD)
	$(TI_ARM_CLANG) $(CFLAGS) -c $< -o $@

$(BUILD)/context.o: rtos/context.s
	@mkdir -p $(BUILD)
	$(TI_ARM_CLANG) $(CFLAGS) -c $< -o $@

$(BUILD)/startup.o: rtos/startup.s
	@mkdir -p $(BUILD)
	$(TI_ARM_CLANG) $(CFLAGS) -c $< -o $@


# ============================================================
# COMPILE SDK STARTUP C
# ============================================================

$(SDK_STARTUP_OBJ): $(SDK_STARTUP_SRC)
	@mkdir -p $(BUILD)
	$(TI_ARM_CLANG) $(CFLAGS) -c $< -o $@


# ============================================================
# COMPILE SYSCONFIG GENERATED C
# ============================================================

$(BUILD)/syscfg_%.o: $(SYSCFG_BUILD)/%.c
	@mkdir -p $(BUILD)
	$(TI_ARM_CLANG) $(CFLAGS) -c $< -o $@


# ============================================================
# LINK
# ============================================================

$(BUILD)/$(TARGET).out: sysconfig $(OBJS) $(SYSCFG_OBJS) $(SDK_LINKER_CMD)
	@mkdir -p $(BUILD)

	$(TI_ARM_CLANG) \
		$(LDFLAGS) \
		$(OBJS) \
		$(SYSCFG_OBJS) \
		$(SDK_DRIVERLIB) \
		-o $@


# ============================================================
# BINARY
# ============================================================

$(BUILD)/$(TARGET).bin: $(BUILD)/$(TARGET).out
	$(TI_ARM_OBJCOPY) \
		-O binary \
		$< \
		$@


# ============================================================
# CLEAN
# ============================================================

.PHONY: clean
clean:
	rm -rf $(BUILD)