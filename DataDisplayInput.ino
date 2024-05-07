#include <DHT.h>

const int pulseSensorPin = A0;   // Analog pin for pulse sensor
const int tempSensorPin = A1;    // Analog pin for temperature sensor
const int dhtPin = 2;            // Digital pin for DHT11 data pin
#define minBPM 60
#define maxBPM 200

// Constants for DHT sensor
#define DHTTYPE DHT11   // DHT 11

// Initialize DHT sensor
DHT dht(dhtPin, DHTTYPE);

// Variables for pulse sensor calibration
int sensorMin = 1023;  // Minimum sensor value
int sensorMax = 0;     // Maximum sensor value

void setup() {
  Serial.begin(115200);           // Initialize serial communication
  dht.begin();                    // Start DHT sensor
  
  // Perform calibration for the pulse sensor
  performPulseSensorCalibration();
}

void loop() {
  // Read pulse sensor value
  int pulseSensorValue = analogRead(pulseSensorPin);

  // Map sensor value to BPM range (adjust minSensorValue and maxSensorValue based on calibration)
  int bpm = map(pulseSensorValue, sensorMin, sensorMax, minBPM, maxBPM);



  // Read temperature and humidity from DHT sensor
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();

  // Calculate the average temperature
  float averageTemperature = (temperature + map(analogRead(tempSensorPin), 0, 1023, 0, 500) / 10.0) / 2.0;

  // Print the sensor data in the correct format
  Serial.print(bpm);
  Serial.print(",");
  Serial.print(averageTemperature, 2); // Sending average temperature to Processing with 2 decimal places
  Serial.print(",");
  Serial.println(humidity);

  // Delay before reading the sensors again
  delay(100); // Adjust delay as needed to control data transmission rate
}

// Function to perform calibration for the pulse sensor
void performPulseSensorCalibration() {
  // Display calibration message
  Serial.println("Calibrating pulse sensor. Please keep still...");
  
  // Perform calibration for 7 seconds
  unsigned long startTime = millis();
  while (millis() - startTime < 7000) {
    int pulseSensorValue = analogRead(pulseSensorPin);

    // Record the maximum sensor value
    if (pulseSensorValue > sensorMax) {
      sensorMax = pulseSensorValue;
    }

    // Record the minimum sensor value
    if (pulseSensorValue < sensorMin) {
      sensorMin = pulseSensorValue;
    }
  }
  
  // Display calibration complete message
  Serial.println("Pulse sensor calibration complete.");
}
