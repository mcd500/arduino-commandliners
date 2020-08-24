
# Adjast for your board
# Manually add them which Arduino IDE gives automotically

## Uno 5V 16MHz
AVR_FREQ ?= 16000000L
MCU ?= atmega328p
VARIANT = standard
ARD_CFLAGS := -DARDUINO=10813 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR
MONITOR_PORT ?= /dev/ttyACM0
MONITOR_BAUDRATE = 115200
AVRDUDE_PROGRAMMER = arduino # choose it from upload.protocol in boards.txt

## Pro Micro 5V 16MHz from SparkFun
#AVR_FREQ ?= 16000000L
#MCU ?= atmega32u4
#ARDUINO_VAR_PATH := $(HOME)/.arduino15/packages/SparkFun/hardware/avr/1.1.13/variants
#VARIANT = promicro
#ARD_CFLAGS := -DARDUINO=10813 -DARDUINO_AVR_MICRO -DARDUINO_ARCH_AVR \
#	-DUSB_VID=0x1b4f -DUSB_PID=0x9206
#MONITOR_PORT ?= /dev/ttyUSB0
#MONITOR_BAUDRATE = 57600
#AVRDUDE_PROGRAMMER = avr109

## Pro Mini 5V 16MHz
#AVR_FREQ ?= 16000000L
#MCU ?= atmega328p
#VARIANT = standard
#ARD_CFLAGS := -DARDUINO=10813 -DARDUINO_AVR_PRO -DARDUINO_ARCH_AVR
#MONITOR_PORT ?= /dev/ttyUSB0
#MONITOR_BAUDRATE = 57600
#AVRDUDE_PROGRAMMER = arduino

## Select the serial port for your board
#MONITOR_PORT ?= /dev/ttyACM0
#MONITOR_PORT ?= /dev/ttyUSB0

# List library names you only use in your sources
ARDUINO_LIBS ?= SoftwareSerial
USER_LIB_PATH ?= $(HOME)/sketchbook/libraries

# File name of your sources
SRC := main.cpp

# File name of generated binary to upload to Arduino
TARGET := uploadimg
ELF := $(TARGET).elf
BIN := $(TARGET).bin
HEX := $(TARGET).hex

# Change them where Arduino IDE is installed
ARDUINO_DIR = $(HOME)/projects/arduino-1.8.13-linux64/arduino-1.8.13
ARDUINO_CORE_PATH = $(ARDUINO_DIR)/hardware/arduino/avr/cores/arduino
ARDUINO_VAR_PATH ?= $(ARDUINO_DIR)/hardware/arduino/avr/variants

# Only have to edit above
#############################################################################
# Others below are for building and linking libraries automatically.
#SHELL = /bin/bash -xue

OBJDIR = .
CORE_LIB = $(OBJDIR)/libcore.a

CC := avr-gcc
CXX := avr-g++
OBJCOPY := avr-objcopy
AR := avr-gcc-ar

all: $(CORE_LIB) $(ELF) $(BIN) $(HEX)

CFLAGS_STD = -std=gnu11 -flto -fno-fat-lto-objects
CXXFLAGS_STD = -fpermissive -fno-exceptions -std=gnu++11 -fno-threadsafe-statics -flto

LOCAL_C_SRCS    ?= $(wildcard *.c)
LOCAL_CPP_SRCS  ?= $(wildcard *.cpp)
LOCAL_CC_SRCS   ?= $(wildcard *.cc)
LOCAL_PDE_SRCS  ?= $(wildcard *.pde)
LOCAL_INO_SRCS  ?= $(wildcard *.ino)
LOCAL_AS_SRCS   ?= $(wildcard *.S)
LOCAL_SRCS      = $(LOCAL_C_SRCS)   $(LOCAL_CPP_SRCS) \
                $(LOCAL_CC_SRCS)   $(LOCAL_PDE_SRCS) \
                $(LOCAL_INO_SRCS) $(LOCAL_AS_SRCS)

ARDUINO_LIB_PATH1 = $(ARDUINO_DIR)/libraries
ARDUINO_LIB_PATH2 = $(ARDUINO_DIR)/hardware/arduino/avr/libraries

ARDUINO_LIBS += $(filter $(notdir $(wildcard $(ARDUINO_LIB_PATH1)/*)), \
	$(shell sed -ne 's/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p' $(LOCAL_SRCS)))
ARDUINO_LIBS += $(filter $(notdir $(wildcard $(ARDUINO_LIB_PATH2)/*)), \
	$(shell sed -ne 's/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p' $(LOCAL_SRCS)))
ARDUINO_LIBS += $(filter $(notdir $(wildcard $(USER_LIB_PATH)/*)), \
	$(shell sed -ne 's/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p' $(LOCAL_SRCS)))

USER_LIBS      := $(sort $(wildcard $(patsubst %,$(USER_LIB_PATH)/%,$(ARDUINO_LIBS))))
USER_LIB_NAMES := $(patsubst $(USER_LIB_PATH)/%,%,$(USER_LIBS))

SYS_LIBS       := $(sort $(wildcard $(patsubst %,$(ARDUINO_LIB_PATH1)/%,$(filter-out $(USER_LIB_NAMES),$(ARDUINO_LIBS)))))
SYS_LIBS       += $(sort $(wildcard $(patsubst %,$(ARDUINO_LIB_PATH2)/%,$(filter-out $(USER_LIB_NAMES),$(ARDUINO_LIBS)))))
SYS_LIB_NAMES  := $(patsubst $(ARDUINO_LIB_PATH1)/%,%,$(SYS_LIBS))
SYS_LIB_NAMES  += $(patsubst $(ARDUINO_LIB_PATH2)/%,%,$(SYS_LIBS))

get_library_includes = $(if $(and $(wildcard $(1)/src), $(wildcard $(1)/library.properties)), \
	-I$(1)/src, \
	$(addprefix -I,$(1) $(wildcard $(1)/utility)))

SYS_INCLUDES        := $(foreach lib, $(SYS_LIBS),  $(call get_library_includes,$(lib)))
USER_INCLUDES       := $(foreach lib, $(USER_LIBS), $(call get_library_includes,$(lib)))

INCLUDES = $(ARD_CFLAGS) -I$(ARDUINO_CORE_PATH) -I$(ARDUINO_VAR_PATH)/$(VARIANT) \
        $(SYS_INCLUDES) $(PLATFORM_INCLUDES) $(USER_INCLUDES)

CPPFLAGS += -mmcu=$(MCU) -DF_CPU=$(AVR_FREQ) -D__PROG_TYPES_COMPAT__ \
        -Wall -ffunction-sections -fdata-sections -Os $(INCLUDES)

CORE_C_SRCS     = $(wildcard $(ARDUINO_CORE_PATH)/*.c)
CORE_C_SRCS    += $(wildcard $(ARDUINO_CORE_PATH)/avr-libc/*.c)
CORE_CPP_SRCS   = $(wildcard $(ARDUINO_CORE_PATH)/*.cpp)
CORE_AS_SRCS    = $(wildcard $(ARDUINO_CORE_PATH)/*.S)

CORE_OBJ_FILES  = $(CORE_C_SRCS:.c=.c.o) $(CORE_CPP_SRCS:.cpp=.cpp.o) $(CORE_AS_SRCS:.S=.S.o)

MKDIR   = mkdir -p

$(OBJDIR)/core/%.c.o: $(ARDUINO_CORE_PATH)/%.c $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(CFLAGS_STD) $< -o $@

$(OBJDIR)/core/%.cpp.o: $(ARDUINO_CORE_PATH)/%.cpp $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CXX) -MMD -c $(CPPFLAGS) $(CXXFLAGS_STD) $< -o $@

$(OBJDIR)/core/%.S.o: $(ARDUINO_CORE_PATH)/%.S $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

CORE_OBJS = $(patsubst $(ARDUINO_CORE_PATH)/%, $(OBJDIR)/core/%,$(CORE_OBJ_FILES))

rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

get_library_files  = $(if $(and $(wildcard $(1)/src), $(wildcard $(1)/library.properties)), \
	$(call rwildcard,$(1)/src/,*.$(2)), \
	$(wildcard $(1)/*.$(2) $(1)/utility/*.$(2)))

LIB_C_SRCS          := $(foreach lib, $(SYS_LIBS),  $(call get_library_files,$(lib),c))
LIB_CPP_SRCS        := $(foreach lib, $(SYS_LIBS),  $(call get_library_files,$(lib),cpp))
LIB_AS_SRCS         := $(foreach lib, $(SYS_LIBS),  $(call get_library_files,$(lib),S))
USER_LIB_CPP_SRCS   := $(foreach lib, $(USER_LIBS), $(call get_library_files,$(lib),cpp))
USER_LIB_C_SRCS     := $(foreach lib, $(USER_LIBS), $(call get_library_files,$(lib),c))
USER_LIB_AS_SRCS    := $(foreach lib, $(USER_LIBS), $(call get_library_files,$(lib),S))

LIB_OBJS = $(patsubst $(ARDUINO_LIB_PATH1)/%.c,$(OBJDIR)/libs/%.c.o,$(LIB_C_SRCS)) \
	$(patsubst $(ARDUINO_LIB_PATH1)/%.cpp,$(OBJDIR)/libs/%.cpp.o,$(LIB_CPP_SRCS)) \
	$(patsubst $(ARDUINO_LIB_PATH1)/%.S,$(OBJDIR)/libs/%.S.o,$(LIB_AS_SRCS))

LIB_OBJS += $(patsubst $(ARDUINO_LIB_PATH2)/%.c,$(OBJDIR)/libs/%.c.o,$(LIB_C_SRCS)) \
	$(patsubst $(ARDUINO_LIB_PATH2)/%.cpp,$(OBJDIR)/libs/%.cpp.o,$(LIB_CPP_SRCS)) \
	$(patsubst $(ARDUINO_LIB_PATH2)/%.S,$(OBJDIR)/libs/%.S.o,$(LIB_AS_SRCS))

USER_LIB_OBJS = $(patsubst $(USER_LIB_PATH)/%.cpp,$(OBJDIR)/userlibs/%.cpp.o,$(USER_LIB_CPP_SRCS)) \
	$(patsubst $(USER_LIB_PATH)/%.c,$(OBJDIR)/userlibs/%.c.o,$(USER_LIB_C_SRCS)) \
	$(patsubst $(USER_LIB_PATH)/%.S,$(OBJDIR)/userlibs/%.S.o,$(USER_LIB_AS_SRCS))

$(OBJDIR)/libs/%.c.o: $(ARDUINO_LIB_PATH1)/%.c
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(CFLAGS_STD) $< -o $@

$(OBJDIR)/libs/%.cpp.o: $(ARDUINO_LIB_PATH1)/%.cpp
	@$(MKDIR) $(dir $@)
	$(CXX) -MMD -c $(CPPFLAGS) $(CXXFLAGS_STD) $< -o $@

$(OBJDIR)/libs/%.S.o: $(ARDUINO_LIB_PATH1)/%.S
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(OBJDIR)/libs/%.c.o: $(ARDUINO_LIB_PATH2)/%.c
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(CFLAGS_STD) $< -o $@

$(OBJDIR)/libs/%.cpp.o: $(ARDUINO_LIB_PATH2)/%.cpp
	@$(MKDIR) $(dir $@)
	$(CXX) -MMD -c $(CPPFLAGS) $(CXXFLAGS_STD) $< -o $@

$(OBJDIR)/libs/%.S.o: $(ARDUINO_LIB_PATH2)/%.S
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(OBJDIR)/userlibs/%.cpp.o: $(USER_LIB_PATH)/%.cpp
	@$(MKDIR) $(dir $@)
	$(CXX) -MMD -c $(CPPFLAGS) $(CXXFLAGS_STD) $< -o $@

$(OBJDIR)/userlibs/%.c.o: $(USER_LIB_PATH)/%.c
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(CFLAGS_STD) $< -o $@

$(OBJDIR)/userlibs/%.S.o: $(USER_LIB_PATH)/%.S
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(CORE_LIB): $(CORE_OBJS) $(LIB_OBJS) $(USER_LIB_OBJS)
	$(AR) rcs $@ $(CORE_OBJS) $(LIB_OBJS) $(USER_LIB_OBJS)

# Building arduino binary image

$(ELF): $(SRC) $(CORE_LIB)
	$(CXX) $(INCLUDES) $(SYS_INCLUDES) $(CPPFLAGS) $(CXXFLAGS) $^ -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex -R .eeprom $< $@

upload: $(HEX)
	stty -F $(MONITOR_PORT) 1200; sleep 1
	avrdude -V -D -v -c $(AVRDUDE_PROGRAMMER) -p $(MCU) -P $(MONITOR_PORT) -b $(MONITOR_BAUDRATE) -U flash:w:$<:i

clean:
	rm -fr $(BIN) $(HEX) $(CORE_LIB) $(OBJDIR)/core $(OBJDIR)/libs $(OBJDIR)/platformlibs $(OBJDIR)/userlibs
