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
    var mqttClient = CocoaMQTT(clientID: "iOS Controller", host: "172.20.10.5", port: 1883)
    var timer = Timer()
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var connectSwitch: UIButton!
    @IBOutlet weak var disconnectSwitch: UIButton!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var lightSlider: UISlider!
    @IBOutlet weak var connectStatus: UITextField!
    @IBOutlet weak var nightModeSwitch: UISwitch!
    
    
    // Setup functions
    override func viewDidLoad() {
        // Add toolbar to keyboard
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction(_:)))
        toolbar.setItems([flexSpace, doneButton], animated: false)
        toolbar.sizeToFit()
        self.textField.inputAccessoryView = toolbar
        
		// Subscribe to the MQTT server
        mqttClient.delegate = self
		
        // Add possibility of tapping in the view to close the keyboard
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(endEditing(_:))))
        
        // Set up timer
        timerInterval()
        
        lightSlider.isEnabled = false
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
            if (!nightModeSwitch.isOn) {
                lightSlider.isEnabled = true
            }
            mqttClient.publish("rpi/gpio", withString: "on")
            print("on")
        } else {
            lightSlider.isEnabled = false
            mqttClient.publish("rpi/gpio", withString: "off")
            print("off")
        }
    }
    @IBAction func nightSwitch(_ sender: UISwitch) {
        if (sender.isOn) {
            mqttClient.subscribe("rpi/back")
            if (lightSlider.isEnabled) {
                lightSlider.isEnabled = false
            }
            mqttClient.publish("rpi/gpio", withString: "night")
            print("night")
        } else {
            mqttClient.unsubscribe("rpi/back")
            if (onOffSwitch.isEnabled) {
                lightSlider.isEnabled = true
            }
            mqttClient.publish("rpi/gpio", withString: "day")
            print("day")
        }
    }
    
    // Running a timer for the connection status
    func timerInterval() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
    }
    @objc func checkConnection() {
        let state = evaluateConnection()
        if state {
            connectStatus.text = "Connected";
            connectStatus.textColor = UIColor.green
        } else {
            connectStatus.text = "Disconnected";
            connectStatus.textColor = UIColor.red
        }
    }
    
    // Managing the input from the text field
    @IBAction func enterIP(_ sender: UITextField) {
        if textField.text!.count <= 1 {
            mqttClient = CocoaMQTT(clientID: "iOS Controller", host: "172.20.10.5", port: 1883)
            return
        }
        print("Entered IP: " + String(describing: textField.text!))
        if IPentered(text: String(describing: textField.text!)) {
            textField.textColor = UIColor.green
            connectSwitch.isEnabled = true
            disconnectSwitch.isEnabled = true
            let state = evaluateConnection()
            if state {
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
        print("MQTT server connection established")
        mqttClient.connect()
    }
    @IBAction func disconnectButton(_ sender: UIButton) {
        print("MQTT server connection disabled")
        mqttClient.disconnect()
    }
    func evaluateConnection() -> Bool {
        let state = mqttClient.connState.description
        // Add live updates of the slider based upon messages from the RPi
        switch state {
            case "connected": return true
            default: return false
        }
    }
}
extension ViewController: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        let msgString = Float(message.string!)!
        if (msgString >= 0 && msgString <= 100) {
            lightSlider.setValue(msgString, animated: true)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("Subscribed to rpi/back")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
    }
    
    func _console(_ info: String) {
    }
}
