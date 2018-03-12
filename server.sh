#!/bin/bash

echo "Starting mosquitto server"
sudo systemctl stop mosquitto
mosquitto -v
