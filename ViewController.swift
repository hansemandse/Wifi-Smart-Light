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
    var mqttClient = CocoaMQTT(clientID: "iOS Controller", host: "172.20.10.2", port: 1883)
    var connected = false
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var connectSwitch: UIButton!
    @IBOutlet weak var disconnectSwitch: UIButton!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var lightSlider: UISlider!
    
    // Setup functions
    override func viewDidLoad() {
        // Try connecting to the standard IP
        mqttClient.connect()
        connected = evaluateConnection()
        if !connected {
            // Disable slider and on/off switch till connection has been established
            onOffSwitch.isEnabled = false
            lightSlider.isEnabled = false
        }
        
        // Add toolbar to keyboard
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction(_:)))
        toolbar.setItems([flexSpace, doneButton], animated: false)
        toolbar.sizeToFit()
        self.textField.inputAccessoryView = toolbar
        
        // Maybe TODO: add stretchable images to ends of the slider (lamp on and lamp off)
        
        // Add possibility of tapping in the view to close the keyboard
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(endEditing(_:))))
        
        // Necessary function to allow for total loading of view
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @objc func doneButtonAction(_ sender: UIBarButtonItem!) {
        textField.resignFirstResponder()
    }
    @objc func endEditing(_ sender: UITapGestureRecognizer!) {
        textField.resignFirstResponder()
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
        if textField.text!.count <= 1 {
            return
        }
        print("Entered IP: " + String(describing: textField.text!))
        if IPentered(text: String(describing: textField.text!)) {
            textField.textColor = UIColor.green
            connectSwitch.isEnabled = true
            disconnectSwitch.isEnabled = true
            if connected {
                mqttClient.disconnect()
            }
            mqttClient = CocoaMQTT(clientID: "iOS Controller", host: textField.text!, port: 1883)
        } else {
            textField.textColor = UIColor.red
            connectSwitch.isEnabled = false
            disconnectSwitch.isEnabled = false
        }
    }
    func IPentered(text: String) -> Bool {
        let parts = text.components(separatedBy: ".")
        let nums = parts.compactMap { Int($0) }
        return parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 256 }.count == 4
    }
    
    // Dimming slider method
    @IBAction func dimSlider(_ sender: UISlider) {
        mqttClient.publish("rpi/gpio", withString: "dc " + String(Int(sender.value)))
        print("Slider: " + String(Int(sender.value)))
    }
    
    // Connect and Disconnect methods
    @IBAction func connectButton(_ sender: UIButton) {
        if !connected {
            mqttClient.connect()
            connected = evaluateConnection()
            if !connected {
                print("MQTT server connection could not be established")
                return
            } else {
                print("MQTT server connection established")
                onOffSwitch.isEnabled = true
                lightSlider.isEnabled = true
                mqttClient.publish("rpi/gpio", withString: "dc " + String(Int(lightSlider.value)))
            }
        }
    }
    @IBAction func disconnectButton(_ sender: UIButton) {
        if connected {
            print("MQTT server connection disabled")
            onOffSwitch.isEnabled = false
            lightSlider.isEnabled = false
            mqttClient.disconnect()
            connected = false
        }
    }
    func evaluateConnection() -> Bool {
        let state = mqttClient.connState.description
        switch state {
            case "connected", "connecting": return true
            default: return false
        }
    }
}
