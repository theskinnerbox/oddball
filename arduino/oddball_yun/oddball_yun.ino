/*
External trigger to oddBall

Author: Claudio Capobianco, Ergoproject
March 2014
*/

#include <Process.h>

// Configure pins
const int buttonPin = 2;     // the number of the pushbutton pin
const int ledPin =  13;      // the number of the LED pin

// configure cycle
const unsigned int cyclePeriodMs = 1; 
unsigned int cycleCounter = 0;

// Button state
int buttonState = 0;         // variable for reading the pushbutton status
unsigned int lowButtonStateCounter = 0; // count how many cycle the button is down
const unsigned int lowButtonStateCounterMax = 3; // number of cycles before firing the event

// Heartbeat
const unsigned int heartbeatCounterMax = 3000; // number of cycles between heartbeat

// Destination parameters
//const String dstIp = "192.168.240.131"; // mac-mini
const String dstIp = "192.168.240.222"; // iphone-di-claudio
const String dstPort = "9090";
const String pokeFile = "/root/poke.txt";
const String heartbeatFile = "/root/heartbeat.txt";

// Debug
bool useSerialForDebug = false;

void setup() {
  // Initialize Bridge
  Bridge.begin();



  // Initialize Pins
  // initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);
  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);

  if (useSerialForDebug == true) {
    // Initialize Serial
    Serial.begin(9600);
    // Wait until a Serial Monitor is connected.
    while (!Serial);
    Serial.println("Serial ok");
  }
  
  sendMessage(heartbeatFile);

}

void loop() {
  // read the state of the pushbutton value:
  buttonState = digitalRead(buttonPin);

  // check if the pushbutton is pressed.
  // if it is, the buttonState is HIGH:
  if (buttonState == HIGH) {
    // turn LED on:
    digitalWrite(ledPin, HIGH);

    // trigger message to oddball only on state change
    // use a counter to be resilient to short state changes
    if (lowButtonStateCounter > lowButtonStateCounterMax) {
      sendMessage(pokeFile);
    }
    lowButtonStateCounter = 0;
  } else {
    // turn LED off:
    digitalWrite(ledPin, LOW);
    lowButtonStateCounter++;
  }
  
  // Send heartbeat
  if ((cycleCounter % heartbeatCounterMax) == 0) {
     sendMessage(heartbeatFile);
  }

  //Serial.println(lowButtonStateCounter);
  cycleCounter++;
  delay(cyclePeriodMs);
}

void sendMessage(String msgFile) {
  Process p;		// Create a process and call it "p"


  // Method #1
  //p.runShellCommand("nc -u -c 192.168.240.131 1234 < /root/poke.txt");
  // Method #2
  String cmd = "nc -u -c " + dstIp + " " + dstPort + " < " + msgFile;
  char cmdChar[100]; // be conservative
  cmd.toCharArray(cmdChar, cmd.length() + 1);
  p.runShellCommand(cmdChar);


  // Following code only for debug
  if (useSerialForDebug == true) {
    Serial.println("Sending message...");
    // Print arduino logo over the Serial
    // A process output can be read with the stream methods
    //    Serial.println(cmdChar);
    Serial.println("Waiting for output ...");
    while (p.available() > 0) {
      char c = p.read();
      Serial.print(c);
    }
    Serial.println("sendMessage ends here");
    // Ensure the last bit of data is sent.
    Serial.flush();
  }
}
