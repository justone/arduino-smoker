// Arduino sketch to control the smoker.

#include <PID_Beta6.h>
#include <pt.h>

// Data for blinkLed
const int ledPin =  13;
static int ledState = LOW;
static long ledNextMillis = 0;
static int ledWaitSeconds = 1;
static struct pt pt_led;

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
  }

  PT_END(pt);
}

static int reportStatus (struct pt *pt) {
  PT_BEGIN(pt);

  while (1) {
    statusNextMillis = millis() + (10 * 1000);
    PT_WAIT_UNTIL(pt, statusNextMillis < millis());

    Serial.println("Status:");
    Serial.print("led delay:");
    Serial.println(ledWaitSeconds);
  }

  PT_END(pt);
}

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

void setup() {
  pinMode(ledPin, OUTPUT);

  Serial.begin(9600);

  // initialize the ProtoThreads varables
  PT_INIT(&pt_led);
  PT_INIT(&pt_status);
}

void loop() {
  blinkLed(&pt_led);
  reportStatus(&pt_status);
  handleCommand();
}
