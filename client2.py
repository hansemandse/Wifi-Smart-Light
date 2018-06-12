#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Modules for the project
import paho.mqtt.client as mqtt
import RPi.GPIO as GPIO
import time, wiringpi

maxLight = 1000
measurements = [100] * 25
nightMode = False
dcRange = 100
clockDivisor = 2
dc = 50
state = False
f = open('data2.txt', 'w')
tid = time.strftime("%a, %d %b %Y %H:%M:%S", time.localtime())
print("Client started at: " + tid)

def gpioSetup():
	# Access global variables
	global dcRange
	global clockDivisor
	global pwm
	global pwm2
	
	try:
		# Setup board pin layout
		wiringpi.wiringPiSetup()
		wiringpi.pinMode(1, wiringpi.PWM_OUTPUT)
		GPIO.setmode(GPIO.BCM)
		GPIO.setup(13, GPIO.OUT)
		GPIO.setup(19, GPIO.OUT)
		pwm = GPIO.PWM(13, 1000)
		pwm2 = GPIO.PWM(19, 1000)
		
		# Set output to mark:space mode (to avoid frequency change)
		wiringpi.pwmSetMode(wiringpi.PWM_MODE_MS)
		
		# Set output to approximately 100 kHz
		wiringpi.pwmSetClock(2)
		wiringpi.pwmSetRange(dcRange)
		
		# Initialize duty cycles
		wiringpi.pwmWrite(1, 0)
		pwm.start(50)
		pwm2.start(50)
		# pwmWrite requires numbers in range [0, dcRange]
	finally:
		print("Completed setup")

def connectionStatus(client, userdata, flags, rc):
	mqttClient.subscribe("rpi/gpio")
	
def messageDecoder(client, userdata, msg):
	message = msg.payload.decode(encoding='UTF-8')
	
	# Debugging prints included in the following
	#print(message)
	
	# Access global variables
	global dc
	global state
	global maxLight
	global nightMode
	global measurements
	global pwm, pwm2
	
	# Change lamp state
	if "on" in message:
		print("Lamp state switched to: ON")
		printTime("ON")
		wiringpi.pwmWrite(1, 85) # Return to previous duty
		# cycle on correct scale
		state = True
		
	elif "off" in message:
		print("Lamp state switched to: OFF")
		printTime("OFF")
		wiringpi.pwmWrite(1, 0) # Turn duty cycle to 0%
		state = False
		
	elif "dc" in message:
		dc = int(message[3:len(message)])
		#print("Lamp duty cycle switched to: " + str(dc) + "%")
		pwm.ChangeDutyCycle(dc)
		pwm2.ChangeDutyCycle(100-dc)
		if state:
			printTime("ON")
		else:
			printTime("OFF")
		
	elif "light" in message:
		if nightMode:
			print(message)
		
	elif "night" in message:
		nightMode = True
		print("Night mode activated")
		printTime("NIGHT")
		
	elif "day" in message:
		nightMode = False
		print("Night mode deactivated")
		printTime("DAY")
		
	else:
		print("Unknown message!")

def fileInitialization():
	# Initialize data collection
	f.write('% The following data have been collected\n')
	f.write('% Time\t\t\t Lamp state\t Duty cycle\n')
	printTime("OFF")

def printTime(stateInput):
	# Output relevant information to file
	tid = time.strftime("%a, %d %b %Y %H:%M:%S", time.localtime())
	f.write(' '.join((tid, '\t', stateInput, '\t\t' , str(dc), '\n')))
	f.flush()

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
	pwm.stop()
	pwm2.stop()
	GPIO.cleanup()
	f.close()
