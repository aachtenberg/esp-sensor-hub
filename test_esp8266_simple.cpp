// Simple test for ESP8266
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include "secrets.h"

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\nESP8266 Simple Test");
  Serial.println("Starting WiFi connection...");
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  Serial.println("");
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi failed");
  }
}

void loop() {
  Serial.println("Test loop running");
  delay(5000);
}
