//
//  ViewController.swift
//  Smart Light Controller
//
//  Created by Hans Jakob on 06/04/2018.
//  Copyright © 2018 DTU. All rights reserved.
//
import UIKit
import CocoaMQTT

class ViewController: UIViewController {
    // New MQTT client
    let mqttClient = CocoaMQTT(clientID: "iOS Controller", host: "172.20.10.2", port: 1883)
    
    // Setup functions
    override func viewDidLoad() {
        mqttClient.publish("rpi/gpio", withString: "dc 50")
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // ON/OFF switching method
    @IBAction func stateSwitch(_ sender: UISwitch) {
        if (sender.isOn) {
            mqttClient.publish("rpi/gpio", withString: "on")
        } else {
            mqttClient.publish("rpi/gpio", withString: "off")
        }
    }
    
    // Managing the input from the text field
    @IBAction func enterIP(_ sender: UITextField) {
        // TODO: Add reading out the entered IP-address and opening a mqttClient based on this (rather than opening it in the beginning of the program
    }
    
    // Dimming slider method
    @IBAction func dimSlider(_ sender: UISlider) {
        // TODO: Fix the reading of the slider value
        mqttClient.publish("rpi/gpio", withString: "dc " + String(Int(sender.value)))
    }
    
    // Connect and Disconnect methods
    @IBAction func connectButton(_ sender: UIButton) {
        mqttClient.connect()
    }
    @IBAction func disconnectButton(_ sender: UIButton) {
        mqttClient.disconnect()
    }
}
