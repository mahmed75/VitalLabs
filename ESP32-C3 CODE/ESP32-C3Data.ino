/*
  ESP32-C3 + MAX30102 Heart Rate Monitor + GSR + Mic + SD Logger
  I2C: SDA = GPIO8, SCL = GPIO9
  Contact microphone on GPIO1
  Grove GSR sensor on GPIO3

  SD card reader wiring:
  3V3  -> ESP32-C3 3V3
  GND  -> ESP32-C3 GND
  CS   -> GPIO7
  MOSI -> GPIO6
  CLK  -> GPIO4
  MISO -> GPIO5
*/

#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include "MAX30105.h"
#include "heartRate.h"

// I2C Pin Definition 
#define I2C_SDA 8
#define I2C_SCL 9

// Sensor Pins 
#define MIC_PIN 1   // ADC1 channel 1 on ESP32-C3 (GPIO1)
#define GSR_PIN 3   // ADC1 channel 3 on ESP32-C3 (GPIO3)

// SD Card SPI Pins 
#define SD_CLK_PIN 4
#define SD_MISO_PIN 5
#define SD_MOSI_PIN 6
#define SD_CS_PIN 7

char logFilePath[16] = "";
const unsigned long SD_RETRY_INTERVAL_MS = 5000;
const unsigned long SD_FLUSH_INTERVAL_MS = 1000;

MAX30105 particleSensor;
File logFile;

const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;

float beatsPerMinute;
int beatAvg;
bool sdReady = false;
unsigned long lastSdRetryMs = 0;
unsigned long lastSdFlushMs = 0;

bool chooseLogFilePath() {
  unsigned long bootMs = millis() % 100000UL;

  for (byte suffix = 0; suffix < 100; suffix++) {
    snprintf(logFilePath, sizeof(logFilePath), "/B%05lu%02u.CSV", bootMs, suffix);
    if (!SD.exists(logFilePath)) {
      return true;
    }
  }

  logFilePath[0] = '\0';
  return false;
}

bool startSDLogging() {
  if (sdReady) {
    return true;
  }

  SPI.begin(SD_CLK_PIN, SD_MISO_PIN, SD_MOSI_PIN, SD_CS_PIN);

  if (!SD.begin(SD_CS_PIN, SPI, 4000000)) {
    Serial.println("SD card not found. Insert card and logging will retry.");
    lastSdRetryMs = millis();
    return false;
  }

  if (!chooseLogFilePath()) {
    Serial.println("Could not create a unique CSV filename on SD card.");
    lastSdRetryMs = millis();
    return false;
  }

  logFile = SD.open(logFilePath, FILE_WRITE);
  if (!logFile) {
    Serial.print("Could not open ");
    Serial.print(logFilePath);
    Serial.println(" on SD card.");
    lastSdRetryMs = millis();
    return false;
  }

  if (logFile.size() == 0) {
    logFile.println("time_ms,ir,bpm,avg_bpm,mic,gsr,note");
    logFile.flush();
  }

  sdReady = true;
  lastSdFlushMs = millis();
  Serial.print("SD logging started: ");
  Serial.println(logFilePath);
  return true;
}

void retrySDIfNeeded() {
  if (sdReady) {
    return;
  }

  unsigned long now = millis();
  if (now - lastSdRetryMs >= SD_RETRY_INTERVAL_MS) {
    startSDLogging();
  }
}

void stopSDLogging() {
  if (logFile) {
    logFile.close();
  }
  sdReady = false;
  lastSdRetryMs = millis();
  Serial.println("SD logging stopped. Waiting for SD card.");
}

void logSampleToSD(unsigned long timeMs, long irValue, float bpm, int avgBpm, int micValue, int gsrValue, bool noFinger) {
  if (!sdReady) {
    retrySDIfNeeded();
    return;
  }

  if (!logFile) {
    stopSDLogging();
    return;
  }

  logFile.print(timeMs);
  logFile.print(',');
  logFile.print(irValue);
  logFile.print(',');
  logFile.print(bpm, 2);
  logFile.print(',');
  logFile.print(avgBpm);
  logFile.print(',');
  logFile.print(micValue);
  logFile.print(',');
  logFile.print(gsrValue);
  logFile.print(',');
  if (noFinger) {
    logFile.print("No finger?");
  }
  logFile.println();

  if (millis() - lastSdFlushMs >= SD_FLUSH_INTERVAL_MS) {
    logFile.flush();
    lastSdFlushMs = millis();
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("Initializing...");

  // Initialize I2C with custom pins
  Wire.begin(I2C_SDA, I2C_SCL);

  // Initialize sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring/power.");
    while (1);
  }
  Serial.println("Place your index finger on the sensor with steady pressure.");

  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);

  // ADC setup for ESP32-C3 (12-bit, 0-4095)
  analogReadResolution(12);
  // Optional: set attenuation for wider voltage range (e.g., 0-3.3V)
  // analogSetAttenuation(ADC_11db);  // uncomment if needed

  startSDLogging();
}

void loop() {
  unsigned long timeMs = millis();
  long irValue = particleSensor.getIR();

  //  Heart Rate Calculation 
  if (checkForBeat(irValue)) {
    long delta = millis() - lastBeat;
    lastBeat = millis();
    beatsPerMinute = 60.0 / (delta / 1000.0);

    if (beatsPerMinute > 20 && beatsPerMinute < 255) {
      rates[rateSpot++] = (byte)beatsPerMinute;
      rateSpot %= RATE_SIZE;

      beatAvg = 0;
      for (byte x = 0; x < RATE_SIZE; x++)
        beatAvg += rates[x];
      beatAvg /= RATE_SIZE;
    }
  }

  // Read Contact Microphone (raw ADC) 
  int micValue = analogRead(MIC_PIN);

  // Read Grove GSR Sensor (raw ADC)
  int gsrValue = analogRead(GSR_PIN);

  bool noFinger = irValue < 50000;

  // Print all values 
  Serial.print("IR=");
  Serial.print(irValue);
  Serial.print(", BPM=");
  Serial.print(beatsPerMinute);
  Serial.print(", Avg BPM=");
  Serial.print(beatAvg);
  Serial.print(", MIC=");
  Serial.print(micValue);
  Serial.print(", GSR=");
  Serial.print(gsrValue);

  if (noFinger)
    Serial.print(" No finger?");

  Serial.println();

  logSampleToSD(timeMs, irValue, beatsPerMinute, beatAvg, micValue, gsrValue, noFinger);

  delay(10);  // small delay to keep serial readable
}

