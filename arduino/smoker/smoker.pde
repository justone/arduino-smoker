// Arduino sketch to control the smoker.

#include <PID_Beta6.h>
#include <pt.h>

int ledPin =  13;

void setup() {
  pinMode(ledPin, OUTPUT);
}

void loop() {
  digitalWrite(ledPin, HIGH);
  delay(1000);
  digitalWrite(ledPin, LOW);
  delay(1000);
}
