import UIKit
import CocoaMQTT

class UIViewController {
	// Constants for the controller
	let clientID = "iOS Controller"
	let host = "192.168.0.xxx"
	let port = 1883
	
	// New MQTT client
	let mqttClient = CocoaMQTT(clientID: "INDSÆT", host: "INDSÆT", port: INDSÆT)
	
	// Setup functions
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	// ON/OFF switch method
	@IBAction func stateSwitch(_ sender: UISwitch) {
		var sliderValue: String = String(Int(sender.value))
		if sender.isOn {
			mqttClient.publish("rpi/gpio", withString: "on")
		} else {
			mqttClient.publish("rpi/gpio", withString: "off")
		}
	}
	
	// Dimming slider method
	@IBAction func dimSlider(_ sender: UISlider) {
		var sliderValue: String = String(Int(sender.value))
		mqttClient.publish("rpi/gpio", withString: "dc " + sliderValue)
	}
	
	// Connect and Disconnect methods
	@IBAction func buttonConnect(_ sender: UIButton) {
		mqttClient.connect()
	}
	@IBAction func buttonDisconnect(_ sender: UIButton) {
		mqttClient.disconnect()
	}
}