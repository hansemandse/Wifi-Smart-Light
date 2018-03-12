#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Modules for the project
import paho.mqtt.client as mqtt
import RPi.GPIO as gpio

dc = 0

def gpioSetup():
	# Pin numbering
	gpio.setmode(gpio.BCM)
	# Setting output-pin (read from pin 12)
	gpio.setup(18, gpio.OUT) # PWM output
	gpio.setup(19, gpio.OUT, initial=gpio.LOW) # Turn on or off
	pwm = gpio.PWM(18, 100000)
	pwm.start(dc)

def connectionStatus(client, userdata, flags, rc):
	mqttClient.subscribe("rpi/gpio")
	
def messageDecoder(client, userdata, msg):
	message = msg.payload.decode(encoding='UTF-8')
	
	#Debugging prints included in the following
	print(message)
	
	#Change lamp state
	if message == "on":
		print("Lamp state switched to: ON")
		gpio.output(19, gpio.HIGH)
	elif message == "off":
		print("Lamp state switched to: OFF")
		gpio.output(19, gpio.LOW)
	elif message[0:1] == "dc":
		dc = int(message[3:end])
		print("Lamp duty cycle switched to: " + dc + "%")
		pwm.changeDutyCycle(dc)
	else:
		print("Unknown message!")

# Setup functions
gpioSetup()

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
