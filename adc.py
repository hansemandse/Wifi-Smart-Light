#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Modules for the project
import paho.mqtt.client as mqtt
import spidev, time, wiringpi

# Create SPI
spi = spidev.SpiDev()
 
def gpioSetup():
	# Setup board pin layout
	wiringpi.wiringPiSetup()
	wiringpi.pinMode(10, wiringpi.OUTPUT)
	
	# Access global variables
	global spi
	
	# Open communication on port 0, chip-select 0
	try:
		spi.open(0, 0)
		spi.max_speed_hz = 500000
		spi.mode = 0b00
	finally:
		print("Completed setup")

def readData():
	# Read SPI data from ADS7841, 4 channels and 12 bit resolution
	# Control byte is 0b10010100
	result = spi.xfer([0x94, 0x00, 0x00])
	# GØR NOGET VED OUTPUTTET
	return result
	
try:
	# Setup functions
	gpioSetup()
	
	# Client name
	clientName = "RPISens"
	# Server IP
	serverAddress = "localhost"
	# Client instantiation
	mqttClient = mqtt.Client(clientName)
	mqttClient.connect(serverAddress)
	
	# Continously read values from ADC
	while True:
		data = readData()
		print(str(data))
		# ÆNDR FØLGENDE, SÅ DET RIGTIGE SENDES
		mqttClient.publish("rpi/gpio", "light " + hex(data[0]))
		
		# Wait before next measurement
		time.sleep(10)
		
except KeyboardInterrupt:
	spi.close()
	mqttClient.disconnect()
	
finally:
	print("Connection closed")
