#include <Wire.h>

void setup() {
  Serial.begin(9600);
  delay(1000);

  Wire.begin();   // Mega uses pin 20(SDA), 21(SCL)
  Serial.println("I2C Scanner Started");
}

void loop() {
  byte error, address;
  int nDevices = 0;

  Serial.println("Scanning...");

  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();

    if (error == 0) {
      Serial.print("I2C device found at address 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.println();
      nDevices++;
    }
  }

  if (nDevices == 0)
    Serial.println("No I2C devices found");
  else
    Serial.println("Scan complete");

  delay(5000);
}
