#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include "DHT.h"
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define DHTPIN D5
#define DHTTYPE DHT22
#define MQ2_PIN A0

#define SDA_PIN D6
#define SCL_PIN D7

LiquidCrystal_I2C lcd(0x27, 16, 2);
DHT dht(DHTPIN, DHTTYPE);
ESP8266WebServer server(80);

const char* ssid = "Gang of Ausras";
const char* password = "oxyzen1234";

unsigned long lastDHTRead = 0;
const unsigned long DHT_INTERVAL = 2000;

float temperature = NAN;
float humidity = NAN;

unsigned long lastAppHit = 0;
const unsigned long APP_CONNECTED_SHOW_MS = 3000; // show "App:Connected" for 3 sec

void showIPLineAlways() {
  // Keep IP on line 1 forever (no lcd.clear here)
  lcd.setCursor(0, 0);
  lcd.print(WiFi.localIP());
  lcd.print("   "); // clears any leftover chars
}

void showIdleStatus() {
  lcd.setCursor(0, 1);
  lcd.print("Waiting...      "); // 16 chars padded
}

void showAppConnected() {
  lcd.setCursor(0, 1);
  lcd.print("App:Connected");
}

void readDHTOnce() {
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();
}

void handleRoot() {
  // Only when IP is hit, show App:Connected (IP stays on line 1)
  lastAppHit = millis();
  showAppConnected();

  int mq2 = analogRead(MQ2_PIN);

  if (isnan(temperature) || isnan(humidity)) {
    String json = "{";
    json += "\"temperature\":null,";
    json += "\"humidity\":null,";
    json += "\"mq2\":";
    json += mq2;
    json += ",\"note\":\"DHT not ready yet\"";
    json += "}";
    server.send(200, "application/json", json);
    return;
  }

  String json = "{";
  json += "\"temperature\":";
  json += temperature;
  json += ",";
  json += "\"humidity\":";
  json += humidity;
  json += ",";
  json += "\"mq2\":";
  json += mq2;
  json += "}";

  server.send(200, "application/json", json);
}

void setup() {
  Wire.begin(SDA_PIN, SCL_PIN);

  Serial.begin(9600);
  dht.begin();

  lcd.init();
  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("Booting...");
  lcd.setCursor(0, 1);
  lcd.print("Please wait...");

  Serial.println("MQ2 warming up...");
  delay(20000);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("Connected. IP: ");
  Serial.println(WiFi.localIP());

  // After WiFi connects, show IP and keep it there
  showIPLineAlways();
  showIdleStatus();

  // Warm-up DHT: try a few reads so first API hit doesn't instantly show null
  Serial.println("Waiting for first valid DHT reading...");
  for (int i = 0; i < 10; i++) {
    readDHTOnce();
    if (!isnan(temperature) && !isnan(humidity)) {
      Serial.println("DHT ready.");
      break;
    }
    delay(1000);
  }

  server.on("/", handleRoot);
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();

  unsigned long now = millis();

  // Keep reading DHT in the background
  if (now - lastDHTRead >= DHT_INTERVAL) {
    lastDHTRead = now;
    readDHTOnce();
  }

  // Always keep IP visible (in case any other print messed it up)
  // This is cheap and safe.
  showIPLineAlways();

  // After a short time from the last hit, go back to idle text on line 2
  if (lastAppHit != 0 && (now - lastAppHit > APP_CONNECTED_SHOW_MS)) {
    showIdleStatus();
    lastAppHit = 0;
  }
}
