#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include "DHT.h"

#define DHTPIN D4       // GPIO2
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

const char* ssid = "YOUR_WIFI_NAME";
const char* password = "YOUR_WIFI_PASSWORD";

ESP8266WebServer server(80);

void handleRoot() {
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature(); // Celsius

  if (isnan(humidity) || isnan(temperature)) {
    server.send(500, "application/json",
                "{\"error\":\"Failed to read from DHT sensor\"}");
    return;
  }

  String json = "[";
  json += "{";
  json += "\"temperature_c\":";
  json += temperature;
  json += ",";
  json += "\"humidity\":";
  json += humidity;
  json += "}";
  json += "]";

  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(9600);
  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();
}
