#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Modules for the project
import paho.mqtt.client as mqtt
import RPi.GPIO as gpio
import time

dc = 99
state = False
f = open('data.txt', 'w')
tid = time.strftime("%a, %d %b %Y %H:%M:%S", time.localtime())
print("Client started at: " + tid)

def gpioSetup():
	gpio.setwarnings(False)
	# Pin numbering
	gpio.setmode(gpio.BCM)
	# Setting output-pin (read from pin 12)
	gpio.setup(18, gpio.OUT) # PWM output
	gpio.setup(19, gpio.OUT, initial=gpio.LOW) # Turn on or off

def connectionStatus(client, userdata, flags, rc):
	mqttClient.subscribe("rpi/gpio")
	
def messageDecoder(client, userdata, msg):
	message = msg.payload.decode(encoding='UTF-8')
	
	#Debugging prints included in the following
	print(message)
	
	#Accessing the global variables
	global pwm
	global state
	
	#Change lamp state
	if "on" in message:
		print("Lamp state switched to: ON")
		printTime("ON")
		gpio.output(19, gpio.HIGH)
		state = True
	elif "off" in message:
		print("Lamp state switched to: OFF")
		printTime("OFF")
		gpio.output(19, gpio.LOW)
		state = False
	elif "dc" in message:
		dc = int(message[3:len(message)])
		print("Lamp duty cycle switched to: " + str(dc) + "%")
		pwm.ChangeDutyCycle(dc)
		if state:
			printTime("ON")
		else:
			printTime("OFF")
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

# Setup functions
gpioSetup()
pwm = gpio.PWM(18, 100000)
pwm.start(dc)
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
pwm.stop()
f.close()
