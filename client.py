#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Modules for the project
import paho.mqtt.client as mqtt
import time, wiringpi

nightMode = False
dcRange = 100
clockDivisor = 2
dc = 50
state = False
f = open('data.txt', 'w')
tid = time.strftime("%a, %d %b %Y %H:%M:%S", time.localtime())
print("Client started at: " + tid)

def gpioSetup():
	# Access global variables
	global dcRange
	global clockDivisor
	
	try:
		# Setup board pin layout
		wiringpi.wiringPiSetup()
		wiringpi.pinMode(1, wiringpi.PWM_OUTPUT)
		
		# Set output to mark:space mode (to avoid frequency change)
		wiringpi.pwmSetMode(wiringpi.PWM_MODE_MS)
		
		# Set output to approximately 100 kHz
		wiringpi.pwmSetClock(2)
		wiringpi.pwmSetRange(dcRange)
		
		# Initialize to 0% duty cycle
		wiringpi.pwmWrite(1, 0) 
		# pwmWrite requires numbers in range [0, dcRange]
	finally:
		print("Completed setup")

def connectionStatus(client, userdata, flags, rc):
	mqttClient.subscribe("rpi/gpio")
	
def messageDecoder(client, userdata, msg):
	message = msg.payload.decode(encoding='UTF-8')
	
	# Debugging prints included in the following
	print(message)
	
	# Access global variables
	global dc
	global state
	
	# Change lamp state
	if "on" in message:
		print("Lamp state switched to: ON")
		printTime("ON")
		wiringpi.pwmWrite(1, calcNewDC(dc)) # Return to previous duty
		# cycle on correct scale
		state = True
		
	elif "off" in message:
		print("Lamp state switched to: OFF")
		printTime("OFF")
		wiringpi.pwmWrite(1, 0) # Turn duty cycle to 0%
		state = False
		
	elif "dc" in message:
		dc = int(message[3:len(message)])
		print("Lamp duty cycle changed to: " + str(dc) + "%")
		if (dc == 0):
			wiringpi.pwmWrite(1, 0)
		else:
			wiringpi.pwmWrite(1, calcNewDC(dc))
		if state:
			printTime("ON")
		else:
			printTime("OFF")
		
	elif "light" in message:
		if nightMode:
			# INDSÆT KODE TIL BEHANDLING AF OUTPUT FRA ADC-KODEN
		
	elif "night" in message:
		nightMode = True
		printTime("NIGHT")
		
	elif "day" in message:
		nightMode = False
		printTime("DAY")
		
	else:
		print("Unknown message!")

def fileInitialization():
	# Initialize data collection
	f.write('% The following data have been collected\n')
	f.write('% Time\t\t\t Lamp state\t Duty cycle\n')
	printTime("OFF")

def printTime(stateInput):
	global dc
	# Output relevant information to file
	tid = time.strftime("%a, %d %b %Y %H:%M:%S", time.localtime())
	f.write(' '.join((tid, '\t', stateInput, '\t\t' , str(dc), '\n')))
	f.flush()

def calcNewDC(dc):
	# Calculate duty cycle on correct scale from percentage scale
	return int(50+0.35*dc)

try:
	# Setup functions
	gpioSetup()
	fileInitialization()

	# Client name
	clientName = "RPILamp"
	# Server IP
	serverAddress = "localhost"
	# Client instantiation
	mqttClient = mqtt.Client(clientName)
	mqttClient.on_connect = connectionStatus
	mqttClient.on_message = messageDecoder
	mqttClient.connect(serverAddress)

	# Monitoring for the Terminal
	mqttClient.loop_forever()
	
except KeyboardInterrupt:
	mqttClient.disconnect()
	
finally:
	wiringpi.pwmWrite(1, 0)
	f.close()
