import processing.serial.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.ArrayList; // Import for ArrayList
import java.awt.Robot;
import java.awt.AWTException;
import java.awt.event.InputEvent; // Import for InputEvent

Serial arduinoPort; // Serial object for communication with Arduino
Robot robot; // Robot object for mouse interaction

boolean displayGraph = false; // Flag to toggle displaying the temperature graph
boolean displayHeartRateGraph = false; // Flag to toggle displaying the heart rate graph
boolean displaySoundGraph = false; // Flag to toggle displaying the sound graph
boolean displayHumidityGraph = false; // Flag to toggle displaying the humidity graph
ArrayList<Float> heartRateData = new ArrayList<Float>(); // List to store heart rate data
ArrayList<Float> temperatureData = new ArrayList<Float>(); // List to store temperature data
ArrayList<Float> humidityData = new ArrayList<Float>(); // List to store humidity data
Minim minim;
AudioInput in;
FFT fft;

int interval = 1000; // Interval in milliseconds for updating temperature data
int lastTime = 0; // Last time recorded

int binsperband = 10;
int peaksize; // Number of individual peak bands
float gain = 40; // Gain in dB
float dB_scale = 4.0;  // Pixels per dB
int buffer_size = 1024;  // Sets FFT size (frequency resolution)
float sample_rate = 44100;
int spectrum_height = 500; // Height of the sound spectrum
int legend_height = 20;
int spectrum_width = 850; // Width of the sound spectrum
int legend_width = 100;

void setup() {
  size(900,600);
  textMode(SCREEN);
  textFont(createFont("Arial", 12));
  try {
    robot = new Robot();
  } catch (AWTException e) {
    e.printStackTrace();
  }
  // Open the serial port to communicate with Arduino
  String portName = "COM5"; // Serial port name
  arduinoPort = new Serial(this, portName, 115200); // Set Baud rate

  // Initialize Minim and audio objects
  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO, buffer_size, sample_rate);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.window(FFT.HAMMING);

  // Initialize peak-hold structures
  peaksize = 1 + Math.round(fft.specSize() / binsperband);
}

void draw() {
  background(255); // Clear previous visualization
  
  // Handle incoming data from Arduino
  while (arduinoPort.available() > 0) {
    String data = arduinoPort.readStringUntil('\n');
    if (data != null) {
      processData(data);
    }
  }
  
  // Display temperature graph if flag is true
  if (displayGraph) {
    displayTemperatureGraph();
  }

  // Display heart rate graph if flag is true
  if (displayHeartRateGraph) {
    displayHeartRateGraph();
  }

  // Display humidity graph if flag is true
  if (displayHumidityGraph) {
    displayHumidityGraph();
  }

  // Display sound graph if flag is true
  if (displaySoundGraph) {
    displaySoundGraph();
  }
  
  // Redraw toggle buttons after displaying all graphs
  redrawToggleButtons();
}

void mousePressed() {
  // Reset all display flags to false initially
  displayGraph = false;
  displayHeartRateGraph = false;
  displayHumidityGraph = false;
  displaySoundGraph = false;

  // Check if mouse is clicked inside temperature toggle button area
  if (mouseX > 10 && mouseX < 110 && mouseY > 10 && mouseY < 40) {
    displayGraph = !displayGraph; // Toggle temperature graph display
  }

  // Check if mouse is clicked inside heart rate toggle button area
  if (mouseX > 120 && mouseX < 220 && mouseY > 10 && mouseY < 40) {
    displayHeartRateGraph = !displayHeartRateGraph; // Toggle heart rate graph display
  }

  // Check if mouse is clicked inside humidity toggle button area
  if (mouseX > 230 && mouseX < 330 && mouseY > 10 && mouseY < 40) {
    displayHumidityGraph = !displayHumidityGraph; // Toggle humidity graph display
  }

  // Check if mouse is clicked inside sound toggle button area
  if (mouseX > 340 && mouseX < 440 && mouseY > 10 && mouseY < 40) {
    displaySoundGraph = !displaySoundGraph; // Toggle sound graph display
  }
}

void redrawToggleButtons() {
  // Temperature button
  drawToggleButton(10, 10, "Temperature", displayGraph);
  // Heart rate button
  drawToggleButton(120, 10, "Heart Rate", displayHeartRateGraph);
  // Humidity button
  drawToggleButton(230, 10, "Humidity", displayHumidityGraph);
  // Sound button
  drawToggleButton(340, 10, "Sound", displaySoundGraph);
}

void drawToggleButton(int x, int y, String label, boolean displayFlag) {
  // Set button color
  if (displayFlag) {
    fill(0, 255, 0); // Green if selected
  } else {
    fill(200); // Default color
  }
  rect(x, y, 100, 30); // Toggle button
  fill(0);
  textAlign(CENTER, CENTER);
  text(label, x + 50, y + 15); // Text label
}

void displayHeartRateGraph() {
  // Clear previous visualization
  background(255);

  // Draw heart rate graph lines
  beginShape();
  noFill();
  stroke(255, 0, 0); // Set stroke color to red for heart rate graph

  // Determine the starting index based on the size of the data
  int startIdx = max(0, heartRateData.size() - 5);

  // Calculate the distance between each plotted point
  float pointDistance = (width - 150) / max(5, heartRateData.size() - 1);

  // Draw the graph from the starting index to the end of the data
  for (int i = startIdx; i < heartRateData.size(); i++) {
    float xPos = 100 + i * pointDistance;
    float yPos = map(heartRateData.get(i), 0, 200, height - 50, 100); // Assuming heart rate data ranges from 0 to 200
    vertex(xPos, yPos);
  }
  endShape();

  // Remove the oldest points if there are more than 5 points
  if (heartRateData.size() > 5) {
    heartRateData.remove(0);
  }

  // Draw heart rate and time axes
  stroke(175); // Set stroke color to gray
  line(100, height - 50, width - 50, height - 50); // X-axis (time)
  line(100, height - 50, 100, 100); // Y-axis (heart rate)

  // Draw heart rate and time axis labels
  fill(0);
  textAlign(RIGHT);
  text("Heart Rate (BPM)", 120, 70); // Y-axis label
  textAlign(CENTER);
  text("Time", width / 2, height - 20); // X-axis label

  // Draw heart rate markings
  for (int i = 0; i <= 200; i += 20) {
    float yPos = map(i, 0, 200, height - 50, 100); // Assuming heart rate data ranges from 0 to 200
    line(95, yPos, 100, yPos);
    textAlign(RIGHT);
    text(i, 90, yPos);
  }

  // Display current BPM if heart rate data is not empty
  if (!heartRateData.isEmpty()) {
    fill(0);
    textAlign(RIGHT);
    text("Current BPM: " + heartRateData.get(heartRateData.size() - 1), width - 10, 50);
  }

 
}

void displayTemperatureGraph() {
  // Temperature data visualization
  stroke(0); // Set stroke color to black
  
  // Draw temperature graph lines
  beginShape();
  noFill();
  int dataSize = temperatureData.size();
  int startIndex = max(0, dataSize - (width - 150)); // Adjusting for graph movement
  for (int i = startIndex; i < dataSize; i++) {
    float xPos = map(i, startIndex, dataSize - 1, 100, width - 50);
    float yPos = map(temperatureData.get(i), 0, 100, height - 50, 100);
    vertex(xPos, yPos);
  }
  endShape();
  
  // Draw temperature and time axes
  stroke(175); // Set stroke color to gray
  line(100, height - 50, width - 50, height - 50); // X-axis (time)
  line(100, height - 50, 100, 100); // Y-axis (temperature)
  
  // Draw temperature and time axis labels
  fill(0);
  textAlign(RIGHT);
  text("Temperature (°C)", 120, 70); // Y-axis label
  textAlign(CENTER);
  text("Time", width / 2, height - 20); // X-axis label
  
  // Draw temperature markings
  for (int i = 0; i <= 100; i += 10) {
    float yPos = map(i, 0, 100, height - 50, 100);
    line(95, yPos, 100, yPos);
    textAlign(RIGHT);
    text(i, 90, yPos);
  }
  
  // Display current temperature if temperature graph is toggled
  if (displayGraph && !temperatureData.isEmpty()) {
    fill(0);
    textAlign(RIGHT);
    text("Current Temperature: " + temperatureData.get(temperatureData.size() - 1) + "°C", width - 10, 50);
  }
  
  // Update temperature data
  // Remove oldest data point if the graph moves out of bounds
  if (temperatureData.size() > width - 150) {
    temperatureData.remove(0);
  }
}

void displayHumidityGraph() {
  // Clear previous visualization
  background(255);

  // Draw humidity graph lines
  beginShape();
  noFill();
  stroke(0, 0, 255); // Set stroke color to blue for humidity graph

  // Calculate the distance between each plotted point
  float pointDistance = (width - 150) / max(5, humidityData.size() - 1);

  // Draw the graph from the starting index to the end of the data
  for (int i = 0; i < humidityData.size(); i++) {
    float xPos = 100 + i * pointDistance;
    float yPos = map(humidityData.get(i), 0, 100, height - 50, 100); // Assuming humidity data ranges from 0 to 100
    vertex(xPos, yPos);
  }
  endShape();

  // Remove the oldest points if there are more than 5 points
  if (humidityData.size() > 5) {
    humidityData.remove(0);
  }

  // Draw humidity and time axes
  stroke(175); // Set stroke color to gray
  line(100, height - 50, width - 50, height - 50); // X-axis (time)
  line(100, height - 50, 100, 100); // Y-axis (humidity)

  // Draw humidity and time axis labels
  fill(0);
  textAlign(RIGHT);
  text("Humidity (%)", 80, 70); // Y-axis label
  textAlign(CENTER);
  text("Time", width / 2, height - 20); // X-axis label

  // Draw humidity markings
  for (int i = 0; i <= 100; i += 10) {
    float yPos = map(i, 0, 100, height - 50, 100);
    line(95, yPos, 100, yPos);
    textAlign(RIGHT);
    text(i, 90, yPos);
  }

  // Display current humidity if humidity data is not empty
  if (!humidityData.isEmpty()) {
    fill(0);
    textAlign(RIGHT);
    text("Current Humidity: " + humidityData.get(humidityData.size() - 1) + "%", width - 10, 50);
  }
}

void displaySoundGraph() {
  // Clear window
  background(255); // Change background color to white

  // Perform a forward FFT on the samples in input buffer
  fft.forward(in.mix);

  // Draw peak bars
  noStroke();
  fill(0, 128, 144); // Dim cyan
  for (int i = 0; i < fft.specSize(); ++i) {
    float val = dB_scale * (20 * (log(fft.getBand(i)) / log(10)) + gain);
    int thisy = min(spectrum_height, max(0, spectrum_height - round(val)));
    rect(legend_width + i, thisy, 1, spectrum_height - thisy);
  }

  // Draw legend
  fill(0); // Change text color to black
  stroke(0); // Change stroke color to black
  int y = spectrum_height;
  line(legend_width, y, legend_width + spectrum_width, y); // Horizontal line
  textAlign(CENTER, TOP);
  for (float freq = 0.0; freq < in.sampleRate() / 2; freq += 2000.0) {
    int x = legend_width + fft.freqToIndex(freq); // Which bin holds this frequency
    line(x, y, x, y + 4); // Tick mark
    text(Math.round(freq / 1000) + "kHz", x, y + 5); // Add text label
  }

  // Level axis
  int x = legend_width;
  line(x, 0, x, spectrum_height); // Vertical line
  textAlign(RIGHT, CENTER);
  for (float level = -100.0; level < 100.0; level += 10) {
    // Adjust the position of the text labels
    float textY = spectrum_height - round(dB_scale * level );
    // Ensure text labels are within the visible range
    if (textY >= 0 && textY <= spectrum_height) {
      // Draw markers and labels for all dB values
      line(x, textY, x - 3, textY);
      text((int) level + " dB", x - 5, textY);
    }
  }

  // Display axis labels
  fill(0);
  textAlign(RIGHT);
  text("Sound (Db)", 80, 70); // Y-axis label
  textAlign(CENTER);
  text("Frequency(Hz)", width / 2, height - 20); // X-axis label
}

void processData(String data) {
  // Ensure that the received data is not empty
  if (!data.trim().isEmpty()) {
    // Split the received data into individual values
    String[] values = data.trim().split(",");
    if (values.length >= 3) { // Assuming BPM, humidity, and average temperature are sent
      // Convert BPM value to float
      float bpm = Float.parseFloat(values[0]);
      // Convert average temperature value to float
      float averageTemperature = Float.parseFloat(values[2]);
      // Convert humidity value to float
      float humidity = Float.parseFloat(values[1]);
      heartRateData.add(bpm);
      temperatureData.add(averageTemperature);
      humidityData.add(humidity);
      // Print the extracted values for debugging
      println("BPM: " + bpm + ", Average Temperature: " + averageTemperature + ", Humidity: " + humidity);

      // You can add further processing or visualization logic here
    } else {
      println("Received invalid data format: " + data);
    }
  }
}

void stop() {
  // Close serial port when exiting
  arduinoPort.stop();
  super.stop();
}
