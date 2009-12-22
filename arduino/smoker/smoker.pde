// Arduino sketch to control the smoker.

#include <PID_Beta6.h>
#include <pt.h>

// Pin assignments
const int ledPin =  13;
const int tempPin = 0;
const int hotplatePin = 3;
const int statusDelay = 2;

// State for LED
static int ledState = LOW;
static long ledNextMillis = 0;
static int ledWaitSeconds = 1;
static struct pt pt_led;

// State for Temp Sensor
float tcSum = 0.0;
float latestReading = 0.0;
int readCount = 0;
float multiplier;
static long tempNextMillis = 0;
static long tempWaitMillis = 250;
static struct pt pt_temp;

// Data for reportStatus
static long statusNextMillis = 0;
static struct pt pt_status;

static int blinkLed (struct pt *pt) {
  PT_BEGIN(pt);

  while (1) {
    ledNextMillis = millis() + (ledWaitSeconds * 1000);
    PT_WAIT_UNTIL(pt, ledNextMillis < millis());

    if (ledState == LOW)
      ledState = HIGH;
    else
      ledState = LOW;

    digitalWrite(ledPin, ledState);
    digitalWrite(hotplatePin, ledState);
  }

  PT_END(pt);
}

static int sampleTemp (struct pt *pt) {
  PT_BEGIN(pt);
  
  while(1) {
    tempNextMillis = millis() + tempWaitMillis;
    PT_WAIT_UNTIL(pt, tempNextMillis < millis());
    tcSum += analogRead(tempPin); //output from AD595 to analog pin
    readCount +=1;
  }
  PT_END(pt);
}

static int reportStatus (struct pt *pt) {
  PT_BEGIN(pt);

  while (1) {
    statusNextMillis = millis() + (statusDelay * 1000);
    PT_WAIT_UNTIL(pt, statusNextMillis < millis());

    Serial.println("Status:");
    Serial.print("led delay:");
    Serial.println(ledWaitSeconds);
    Serial.print("temp:");
    printFloat(getFreshTemp(),2);
    Serial.print("\n");
    Serial.print("raw temp:");
    Serial.println(analogRead(tempPin));
    
  }

  PT_END(pt);
}

// mostly from:
// http://todbot.com/blog/2009/07/30/arduino-serial-protocol-design-patterns/
void handleCommand () {
  if (!Serial.available()) {
    return;
  }
  char cmdbuf[40];
  char c;
  int i = 0;
  while( Serial.available() && c!= '\n' ) {  // buffer up a line
    c = Serial.read();
    cmdbuf[i++] = c;
    delay(10); // short delay to 
  }
  cmdbuf[i] = NULL;
  Serial.println(cmdbuf);

  i = 0;
  while( cmdbuf[++i] != ' ' ) ; // find first space
  cmdbuf[i] = 0;          // null terminate command
  char* cmd = cmdbuf;     //
  int cmdlen = i;         // length of cmd

  char *args[5];
  int a;  // five args max, 'a' is arg counter
  char* s; 
  char* argbuf = cmdbuf+cmdlen+1;
  while( (s = strtok(argbuf, " ")) != NULL && a < 5 ) {
    argbuf = NULL;
    args[a++] = s;
  }
  int argcnt = a;         // number of args read

  if (strcmp(cmd, "setDelay") == 0) {
    int newDelay = strtol(args[0], NULL, 0);
    if (newDelay > 0) {
      Serial.println("new delay received");
      ledWaitSeconds = newDelay;
    }
  }
}

void setupTempSensor() {
  multiplier = 1.0/(1023.0) * 500.0 * 9.0 / 5.0;
}

float getFreshTemp() { 
      latestReading = tcSum* multiplier/readCount+32.0;
      readCount = 0;
      tcSum = 0.0;
  return latestReading;

}

float getLastTemp() {
  return latestReading;

}

// printFloat prints out the float 'value' rounded to 'places' places after the decimal point
void printFloat(float value, int places) {
  // this is used to cast digits 
  int digit;
  float tens = 0.1;
  int tenscount = 0;
  int i;
  float tempfloat = value;

  // make sure we round properly. this could use pow from <math.h>, but doesn't seem worth the import
  // if this rounding step isn't here, the value  54.321 prints as 54.3209

  // calculate rounding term d:   0.5/pow(10,places)  
  float d = 0.5;
  if (value < 0)
    d *= -1.0;
  // divide by ten for each decimal place
  for (i = 0; i < places; i++)
    d/= 10.0;    
  // this small addition, combined with truncation will round our values properly 
  tempfloat +=  d;

  // first get value tens to be the large power of ten less than value
  // tenscount isn't necessary but it would be useful if you wanted to know after this how many chars the number will take

  if (value < 0)
    tempfloat *= -1.0;
  while ((tens * 10.0) <= tempfloat) {
    tens *= 10.0;
    tenscount += 1;
  }


  // write out the negative if needed
  if (value < 0)
    Serial.print('-');

  if (tenscount == 0)
    Serial.print(0, DEC);

  for (i=0; i< tenscount; i++) {
    digit = (int) (tempfloat/tens);
    Serial.print(digit, DEC);
    tempfloat = tempfloat - ((float)digit * tens);
    tens /= 10.0;
  }

  // if no places after decimal, stop now and return
  if (places <= 0)
    return;

  // otherwise, write the point and continue on
  Serial.print('.');  

  // now write out each decimal place by shifting digits one by one into the ones place and writing the truncated value
  for (i = 0; i < places; i++) {
    tempfloat *= 10.0; 
    digit = (int) tempfloat;
    Serial.print(digit,DEC);  
    // once written, subtract off that digit
    tempfloat = tempfloat - (float) digit; 
  }
}

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(hotplatePin, OUTPUT);

  Serial.begin(9600);
  setupTempSensor();

  // initialize the ProtoThreads varables
  PT_INIT(&pt_led);
  PT_INIT(&pt_status);
  PT_INIT(&pt_temp);
}

void loop() {
  blinkLed(&pt_led);
  sampleTemp(&pt_temp);
  reportStatus(&pt_status);
  handleCommand();
}
