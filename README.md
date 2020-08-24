# Arduino Makefiles for commandliners

This project is providing Makefiles for using Arduino libraries which is small as possible.

The regular procedure to adopt development of Arduino to custom designed development boards require revising `boards.txt` for the new dev boards. It is aiming to be able to adopt your own new board by changing few lines in Makefile.

It is also beneficial who are constrained (or like) to use only an editor for developments or would like to understand how to build Arduino libraries with Makefiles.

It is convenient for engineers who do not use only off-the-shelf boards.

Currently supporting AVR and STM32 only.
I have no intention to make this project to replace arduino-mk.

## Index

 - [Prerequisites](#Prerequisites)
 - [Basic flow](#Basic-flow)
 - [Makefils for AVR and STM32](#Makefile-which)
 - [Configuring Makefiles to point installed Arduino](#Makefile-arduino)
 - [Configuring Makefiles for dev boards](#Makefile-dev-baords)
 - [Usage](#Usage)
 - [Credits](#credits)
 - [TODO](#TODO)

## Prerequisites <a id="Prerequisites"></a>

*  Arduino IDE which comes with Arduino IDE for programming AVR
*  SparkFun Arduino Boards Addon Files
*  Arduino_Core_STM32 for programming STM32
*  Devlopment tools, gcc and etc for the cpu

The latest Arduino IDE must be installed on development machine. (tested on 1.8.13)
Only supports Linux for the host development PC.
I only have tested on Ubuntu 18.04 at the moment.

Arduino Pro Micro required addon files from SparkFun.

The Arduino_Core_STM32 must be installed for who programs stm32 as well but not required if it is AVR only purpose.

I do not have plan to supporting Windows at the moment for keeping the Makefile simple which is the main objective of this project.

Link to how to install Arduino IDE  
([https://ubuntu.com/tutorials/install-the-arduino-ide#2-installing-via-a-tarball](https://ubuntu.com/tutorials/install-the-arduino-ide#2-installing-via-a-tarball))  
 (I had to replace `./install.sh` to `sudo ./install.sh` in the instruction in my case.)

Link to how to install SparkFun Arduino Boards Addon Files  
([https://github.com/sparkfun/Arduino_Boards](https://github.com/sparkfun/Arduino_Boards))

Link to how to install Arduino_Core_STM32  
([https://github.com/stm32duino/Arduino_Core_STM32](https://github.com/stm32duino/Arduino_Core_STM32))

These are the minimum packages required to build. (Only tested on Ubuntu at the moment)
```sh
$ sudo apt-get -y update
$ sudo apt-get -y install apt-utils apt xz-utils wget git
```

For AVR:
```sh
$ sudo apt-get -y install binutils-avr gcc-avr avr-libc avrdude
```

For STM32:
```sh
$ sudo apt-get -y install gcc-arm-none-eabi binutils-arm-none-eabi
$ sudo dpkg --add-architecture i386 && sudo apt-get update
$ sudo apt install libusb-1.0.0:i386
```

## Basic flow of using Makefiles for Arduino libraries with no gui  <a id="Basic-flow"></a>

  1. Download Makefile for your project
  1. Customize the path where Arduino libraries are installed
  1. Customize variables in Makefile for your dev boards
  1. Build and upload

## Using Makefils for AVR and STM32 <a id="Makefile-which"></a>

First download Makefiles as bellow at the location where the main sources for your developments.

For AVR:
```sh
$ wget https://raw.githubusercontent.com/mcd500/arduino-commandliners/master/Makefile
```

For STM32:
```sh
$ wget https://raw.githubusercontent.com/mcd500/arduino-commandliners/master/Makefile-stm32
```

The `Makefile` is for AVR only. The `Makefile-stm32` is for STM32 only.

For STM32, copying `Makefile-stm32` to `Makefile`:
```sh
$ cp Makefile-stm32 Makefile
```
should be fine for most of the time, since building binaries for both AVR and STM32 is rare.

If your project require to co-exist both, then:
```sh
$ make -f Makefile-stm32
```
every time will do with having two different Makefiles.

The one of the source files must be `main.cpp` since Arduino libraries expect to be called from c++.

I have prepared `main.cpp` for testing Makefiles in later procedure. It just an example of blinking led from Arduino porject.
```sh
$ wget https://raw.githubusercontent.com/mcd500/arduino-commandliners/master/main.cpp
```

## Configuring Makefile where the arduino is installed <a id="Makefile-arduino"></a>

Some lines in Makefile must be changed for where the arduino is installed. This is my example.

```
ARDUINO_DIR = $(HOME)/projects/arduino-1.8.13-linux64/arduino-1.8.13
```

Change the portion of `1.8.13` with the Arduino version.

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

The `9.2.1-1.1` and `5.5.1` differs depend on the Arduino version.

Typically additional packages of `STM32` and  `CMSIS` are installed in location bellow after installing procedure of Arduino_Core_STM32.

```
TOOLS_DIR = $(HOME)/.arduino15/packages/STM32/tools
CMSIS_DIR = $(HOME)/.arduino15/packages/STM32/tools/CMSIS/5.5.1
```

## Configuring Makefile for target development board  <a id="Makefile-dev-baords"></a>

These are the lines to match the dev boards, which I have tested on AVR. For 3.3V 8MHz models, change the `AVR_FREQ ?= 16000000L` to `8000000L`.

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

The MCU could be chosen from `atmega32u4 atmega328p atmega168 atmega2560 atmega1280 atmegang atmega8 attiny85`.

The values to select the `VARIANT` are directory name in `${ARDUINO_DIR}/hardware/arduino/avr/variants`.

It have to have Arduino version in `-DARDUINO=10813` at `ARD_CFLAGS`. The version `1.8.13` will be `10813`, 1.5.0 will be `10500`.

The `-DARDUINO_ARCH_AVR` must be defined to use some of the libraries.

The `-DARDUINO_AVR_UNO` is not really needed, I put it there just because genuine Arduino adds it.

The `AVRDUDE_PROGRAMMER` must have correct value each board for avrdude to upload the binary correctly.
The values could be found from the upload.protocol in boards.txt. The boards.txt could be found at `${ARDUINO_DIR}/hardware/arduino/avr/boards.txt`.


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

For STM32 in Makefile-stm32.

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

TODO: add more description here

## Usage <a id="Usage"></a>


After changing your sources, then typing from command line:
```sh
$ make
```
will build a binary.

If you would like to write to your dev board every time after updating sources:
```sh
$ make upload
```
will build the sources and write to dev board consequently.

It is bellow for mass storage method of writing binary to STM32:
```sh
$ make -f Makefile-stm32 upload-mass
```

## Credits <a id="Credits"></a>

The first initial Makefile was developed for the question at eevblog forum by @ksoviero.
https://www.eevblog.com/forum/programming/i-dont-understand-libraries-in-c/
After my post at the forum, I spent about three days in my spare time and it became to this porject. Thanks!

The Makefile is derived from arduino-mk project. This is main reason for selecting GPL for this project.

## TODO <a id="TODO"></a>

Support more STM32 boards.  
Support serial mode writing for STM32.  
Would like to support RISC-V in the future.  
