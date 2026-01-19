#include <Wire.h>

void setup() {
  Serial.begin(9600);
  delay(1000);

  Wire.begin(D2, D1);   // SDA, SCL (WeMos)
  Serial.println("I2C scan start");
}

void loop() {
  byte error, address;
  int devices = 0;

  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();

    if (error == 0) {
      Serial.print("Found at 0x");
      Serial.println(address, HEX);
      devices++;
    }
  }

  if (devices == 0) {
    Serial.println("No I2C devices found");
  }

  delay(5000);
}
