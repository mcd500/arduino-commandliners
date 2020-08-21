# Arduino for commandliners

This project is providing Makefiles for using Arduino libraries which is small as possible.

The regular procedure to adopt development of Arduino to custom designed development boards require revising `boards.txt` for the new dev boards. It is aiming to be able to adopt your own new board by changing few lines in Makefile.

It is also beneficial who are constrained (or like) to use only an editor for developments or would like to understand how to build Arduino libraries with Makefiles.

It is continent for engineers

Currently supporting AVR and STM32 only.
I have no intention to make this project to replace arduino-mk.

## Index

Prerequisites
Makefils for AVR and STM32
Configuring Makefile
Credits
TODO

## Prerequisites

*  Arduino IDE which comes with Arduino IDE for programming AVR
*  Arduino_Core_STM32 for programming STM32

The latest Arduino IDE must be installed on development machine. (tested on 1.8.13)
Only supports Linux for the host development PC.
I only have tested on Ubuntu 18.04 at the moment.

The Arduino_Core_STM32 must be installed for who programs stm32 as well but not required for who AVR only engineers.

I do not have plan to supporting Windows at the moment for keeping the Makefile simple which is the main objective of this project.

Link to how to install Arduino IDE (https://ubuntu.com/tutorials/install-the-arduino-ide#2-installing-via-a-tarball)
 (I have to replace `./install.sh` to `sudo ./install.sh` in the instruction in my case)
Link to how to install Arduino_Core_STM32 (https://github.com/stm32duino/Arduino_Core_STM32)

## Using Makefils for AVR and STM32

First download Makefiles as bellow at the location where the main sources for your developments.
```sh
$ git clone https://github.com/mcd500/arduino-commandliners.git
```

If your sources have source file with the name `main.cpp` please rename it to other name before the above git cloning. The git repo include `main.cpp` for testing purpose of the arduino- commandliners.

There will be two Makefiles.
```sh
$ ls
LICENSE  main.cpp  Makefiles   Makefiles-stm32
```

The `Makefiles` is for AVR only. The `Makefiles-stm32` is for STM32 only.

Typing from command line:
```sh
$ make
```
will build a binary for AVR.

For STM32, copying `Makefiles-stm32` to `Makefiles` and type `make` or:
```sh
$ make -f  Makefiles-stm32
```
will do.


## Configuring Makefile where the arduino is installed

Some lines in Makefile must be changed for where the arduino is installed.

```
ARDUINO_DIR = $(HOME)/projects/arduino-1.8.13-linux64/arduino-1.8.13
```

The ARDUINO_DIR have to be pointing the directory where following files after untar the arduino-1.8.13-linux64.tar.xz.
```sh
$ ls
arduino                 examples    java       reference      tools-builder
arduino-builder         hardware    lib        revisions.txt  uninstall.sh
arduino-linux-setup.sh  install.sh  libraries  tools
```

More lines are required to change for STM32 in Makefile-stm32.

```
ARM_GCC_PATH := $(HOME)/.arduino15/packages/STM32/tools/xpack-arm-none-eabi-gcc/9.2.1-1.1/bin/
TOOLS_DIR = $(HOME)/.arduino15/packages/STM32/tools
CMSIS_DIR = $(TOOLS_DIR)/CMSIS/5.5.1
```

Typically additional packages of `STM32` and  `CMSIS` are installed in location bellow after installing procedure of Arduino_Core_STM32.

```
TOOLS_DIR = $(HOME)/.arduino15/packages/STM32/tools
CMSIS_DIR = $(HOME)/.arduino15/packages/STM32/tools/CMSIS/5.5.1
```

## Configuring Makefile for target development board


These are the lines to match the dev boards I have tested on AVR.

* Uno 5V 16MHz
```
AVR_FREQ ?= 16000000L
MCU ?= atmega328p
VARIANT = standard
ARD_CFLAGS := -DARDUINO=10813 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR
MONITOR_PORT ?= /dev/ttyACM0
MONITOR_BAUDRATE = 115200
AVRDUDE_PROGRAMMER = arduino # choose it from upload.protocol in boards.txt
```

* Pro Micro 5V 16MHz from SparkFun
```
AVR_FREQ ?= 16000000L
MCU ?= atmega32u4
ARDUINO_VAR_PATH := $(HOME)/.arduino15/packages/SparkFun/hardware/avr/1.1.13/variants
VARIANT = promicro
ARD_CFLAGS := -DARDUINO=10813 -DARDUINO_AVR_MICRO -DARDUINO_ARCH_AVR -DUSB_VID=0x1b4f -DUSB_PID=0x9206
MONITOR_PORT ?= /dev/ttyUSB0
MONITOR_BAUDRATE = 57600
AVRDUDE_PROGRAMMER = avr109
```

* Pro Mini 5V 16MHz
```
AVR_FREQ ?= 16000000L
MCU ?= atmega328p
VARIANT = standard
ARD_CFLAGS := -DARDUINO=10813 -DARDUINO_AVR_PRO -DARDUINO_ARCH_AVR
MONITOR_PORT ?= /dev/ttyUSB0
MONITOR_BAUDRATE = 57600
AVRDUDE_PROGRAMMER = arduino
```

More lines are required for STM32 in Makefile-stm32.

* NUCLEO-F411RE
```
MCU ?= cortex-m4
FPU ?= fpv4-sp-d16
ISAFLAGS  = -mcpu=$(MCU) -mfpu=$(FPU) -mfloat-abi=hard -mthumb
VARIANT = NUCLEO_F4x1RE
HAL_SRC = STM32F4xx
ARD_CFLAGS := -DSTM32F4xx -DARDUINO=10813 -DARDUINO_NUCLEO_F411RE -DARDUINO_ARCH_STM32 -DBOARD_NAME="NUCLEO_F411RE" -DSTM32F411xE -DHAL_UART_MODULE_ENABLED
MASS_OPTION = -O "NODE_F411RE,NUCLEO"
```

## Credits

The first initial Makefile was developed for the question at eevblog forum by @ksoviero.
https://www.eevblog.com/forum/programming/i-dont-understand-libraries-in-c/
After my post at the forum, I spent about three days in my spare time and it became to this porject. Thanks!

The Makefile is derived from arduino-mk project. This is main reason for selecting GPL for this project.

## TODO

Support more STM32 boards.
Support serial mode writing for STM32.
Would like to support RISC-V in the future.

