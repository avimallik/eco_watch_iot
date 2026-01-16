#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include "DHT.h"

#define DHTPIN D4
#define DHTTYPE DHT22
#define MQ2_PIN A0

DHT dht(DHTPIN, DHTTYPE);
ESP8266WebServer server(80);

const char* ssid = "Avi";
const char* password = "01956273133";

unsigned long lastDHTRead = 0;
const unsigned long DHT_INTERVAL = 2000;

float temperature = NAN;
float humidity = NAN;

void handleRoot() {
  int mq2 = analogRead(MQ2_PIN);

  if (isnan(temperature) || isnan(humidity)) {
    server.send(500, "application/json",
                "{\"error\":\"DHT22 read failed\"}");
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
  Serial.begin(9600);
  dht.begin();

  Serial.println("MQ2 warming up...");
  delay(20000);   // MQ-2 warm-up

  WiFi.begin(ssid, password);
  Serial.print("Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.begin();
  Serial.println("Server started");
}

void loop() {
  server.handleClient();

  unsigned long now = millis();
  if (now - lastDHTRead >= DHT_INTERVAL) {
    lastDHTRead = now;
    temperature = dht.readTemperature();
    humidity = dht.readHumidity();
  }
}
