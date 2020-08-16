
# Adjast for your board
AVR_FREQ ?= 16000000L
MCU ?= atmega328p
MONITOR_PORT ?= /dev/ttyACM0
MONITOR_BAUDRATE = 115200

ARDUINO_LIBS ?= SoftwareSerial

SRC := main.cpp
TARGET := example
BIN := $(TARGET).bin
HEX := $(TARGET).hex

# Only have to edit above
# Others below are for building and linking libraries automatically.
SHELL = /bin/bash -xue

ARDUINO_DIR = /usr/share/arduino
ARDUINO_CORE_PATH = /usr/share/arduino/hardware/arduino/cores/arduino
ARDUINO_VAR_PATH = /usr/share/arduino/hardware/arduino/variants
VARIANT = standard
OBJDIR = .
CORE_LIB = $(OBJDIR)/libcore.a

INCLUDES = -I$(ARDUINO_CORE_PATH) -I$(ARDUINO_VAR_PATH)/$(VARIANT)

CC := avr-gcc
CXX := avr-g++
OBJCOPY := avr-objcopy
AR := avr-gcc-ar

all: $(CORE_LIB) $(BIN) $(HEX)
## Bellow here is to build libcore.a

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

ARDUINO_LIB_PATH = $(ARDUINO_DIR)/libraries

ARDUINO_LIBS += $(filter $(notdir $(wildcard $(ARDUINO_DIR)/libraries/*)), \
	$(shell sed -ne 's/^ *\# *include *[<\"]\(.*\)\.h[>\"]/\1/p' $(LOCAL_SRCS)))

USER_LIBS      := $(sort $(wildcard $(patsubst %,$(USER_LIB_PATH)/%,$(ARDUINO_LIBS))))
USER_LIB_NAMES := $(patsubst $(USER_LIB_PATH)/%,%,$(USER_LIBS))

SYS_LIBS       := $(sort $(wildcard $(patsubst %,$(ARDUINO_LIB_PATH)/%,$(filter-out $(USER_LIB_NAMES),$(ARDUINO_LIBS)))))
SYS_LIB_NAMES  := $(patsubst $(ARDUINO_LIB_PATH)/%,%,$(SYS_LIBS))

get_library_includes = $(if $(and $(wildcard $(1)/src), $(wildcard $(1)/library.properties)), \
	-I$(1)/src, \
	$(addprefix -I,$(1) $(wildcard $(1)/utility)))

SYS_INCLUDES        := $(foreach lib, $(SYS_LIBS),  $(call get_library_includes,$(lib)))
USER_INCLUDES       := $(foreach lib, $(USER_LIBS), $(call get_library_includes,$(lib)))

CPPFLAGS += -mmcu=$(MCU) -DF_CPU=$(AVR_FREQ) -D__PROG_TYPES_COMPAT__ \
        -I$(ARDUINO_CORE_PATH) -I$(ARDUINO_VAR_PATH)/$(VARIANT) \
        $(SYS_INCLUDES) $(PLATFORM_INCLUDES) $(USER_INCLUDES) -Wall -ffunction-sections \
        -fdata-sections -Os

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

get_library_files  = $(if $(and $(wildcard $(1)/src), $(wildcard $(1)/library.properties)), \
	$(call rwildcard,$(1)/src/,*.$(2)), \
	$(wildcard $(1)/*.$(2) $(1)/utility/*.$(2)))

LIB_C_SRCS          := $(foreach lib, $(SYS_LIBS),  $(call get_library_files,$(lib),c))
LIB_CPP_SRCS        := $(foreach lib, $(SYS_LIBS),  $(call get_library_files,$(lib),cpp))
LIB_AS_SRCS         := $(foreach lib, $(SYS_LIBS),  $(call get_library_files,$(lib),S))
USER_LIB_CPP_SRCS   := $(foreach lib, $(USER_LIBS), $(call get_library_files,$(lib),cpp))
USER_LIB_C_SRCS     := $(foreach lib, $(USER_LIBS), $(call get_library_files,$(lib),c))
USER_LIB_AS_SRCS    := $(foreach lib, $(USER_LIBS), $(call get_library_files,$(lib),S))

LIB_OBJS = $(patsubst $(ARDUINO_LIB_PATH)/%.c,$(OBJDIR)/libs/%.c.o,$(LIB_C_SRCS)) \
	$(patsubst $(ARDUINO_LIB_PATH)/%.cpp,$(OBJDIR)/libs/%.cpp.o,$(LIB_CPP_SRCS)) \
	$(patsubst $(ARDUINO_LIB_PATH)/%.S,$(OBJDIR)/libs/%.S.o,$(LIB_AS_SRCS))

$(OBJDIR)/libs/%.c.o: $(ARDUINO_LIB_PATH)/%.c
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(CFLAGS_STD) $< -o $@

$(OBJDIR)/libs/%.cpp.o: $(ARDUINO_LIB_PATH)/%.cpp
	@$(MKDIR) $(dir $@)
	$(CXX) -MMD -c $(CPPFLAGS) $(CXXFLAGS_STD) $< -o $@

$(OBJDIR)/libs/%.S.o: $(ARDUINO_LIB_PATH)/%.S
	@$(MKDIR) $(dir $@)
	$(CC) -MMD -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(CORE_LIB): $(CORE_OBJS) $(LIB_OBJS) $(PLATFORM_LIB_OBJS)
	$(AR) rcs $@ $(CORE_OBJS) $(LIB_OBJS) $(PLATFORM_LIB_OBJS) $(USER_LIB_OBJS)

# Building arduino binari image

$(BIN): $(SRC) $(CORE_LIB)
	$(CXX) $(INCLUDES) $(SYS_INCLUDES) $(CPPFLAGS) $(CXXFLAGS) $^ -o $@

$(HEX): $(BIN)
	$(OBJCOPY) -O ihex -R .eeprom $< $@

upload: $(HEX)
	avrdude -v -c arduino -p $(MCU) -P $(MONITOR_PORT) -b 115200 -U flash:w:$<

clean:
	rm -fr $(BIN) $(HEX) $(CORE_LIB) $(OBJDIR)/core $(OBJDIR)/libs $(OBJDIR)/platformlibs
