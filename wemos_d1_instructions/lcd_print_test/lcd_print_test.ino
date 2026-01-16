#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// address 0x27, 16x2 LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

void setup() {
  lcd.init();        // LCD initialize
  lcd.backlight();  // backlight ON

  lcd.setCursor(0, 0);
  lcd.print("Hello!");

  lcd.setCursor(0, 1);
  lcd.print("I2C LCD OK");
}

void loop() {
  // nothing here
}
