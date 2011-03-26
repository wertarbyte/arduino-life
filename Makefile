ARDUINO_DIR	= /usr/share/arduino/
AVR_TOOLS_PATH	= /usr/bin
AVRDUDE_CONF	= /etc/avrdude.conf
AVRDUDE_ARD_BAUDRATE	= 115200
AVRDUDE_ARD_PROGRAMMER	= arduino

TARGET		= Arduino-Life
ARDUINO_LIBS	= 

MCU		= atmega328p
F_CPU		= 16000000
ARDUINO_PORT	= /dev/arduino

include Arduino.mk

config.h:
	touch $@
