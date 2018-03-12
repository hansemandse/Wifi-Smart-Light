#!/bin/bash

echo "The IP address of this RPi is: "
ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/'

echo "The broadcasting IP of this RPi is: "
ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $4}' | cut -f1 -d'/'

echo "Starting mosquitto server"
sudo systemctl stop mosquitto
mosquitto -v
