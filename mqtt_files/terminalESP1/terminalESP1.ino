//====================================================
// ESP32 HOTEL ROOM FSM
// MQTT + KEYPAD + RGB LED + SERIAL UI
//====================================================

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Keypad.h>

//====================================================
// WIFI
//====================================================

const char* ssid = "TU_WIFI";
const char* password = "TU_PASSWORD";

//====================================================
// MQTT
//====================================================

const char* mqtt_server = "192.168.1.100";

WiFiClient espClient;
PubSubClient client(espClient);

//====================================================
// DEVICE
//====================================================

String deviceId = "room_203";

//====================================================
// RGB LED PINS
//====================================================

#define RED_PIN     15
#define GREEN_PIN   2
#define BLUE_PIN    4

//====================================================
// ROOM STATES
//====================================================

enum RoomState {
  OCUPADO,
  LIMPIEZA,
  INSPECCION,
  LISTO
};

RoomState currentState = OCUPADO;

//====================================================
// AUTH
//====================================================

bool authenticated = false;

String currentRole = "";
String currentUser = "";
String sessionId = "";

//====================================================
// KEYPAD
//====================================================

const byte ROWS = 4;
const byte COLS = 4;

char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};

byte rowPins[ROWS] = {13,12,14,27};
byte colPins[COLS] = {26,25,33,32};

Keypad keypad = Keypad(
  makeKeymap(keys),
  rowPins,
  colPins,
  ROWS,
  COLS
);

//====================================================
// WIFI
//====================================================

void connectWiFi() {

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {

    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected");
}

//====================================================
// MQTT
//====================================================

void connectMQTT() {

  while (!client.connected()) {

    Serial.println("Connecting MQTT...");

    if (client.connect("ESP32_ROOM_203")) {

      Serial.println("MQTT Connected");

      subscribeTopics();

    } else {

      Serial.println("MQTT Failed");

      delay(2000);
    }
  }
}

//====================================================
// SUBSCRIBE***************
//====================================================

void subscribeTopics() {

  String topic =
    "hotel/auth/response/" + deviceId;

  client.subscribe(topic.c_str());
}

//====================================================
// RGB CONTROL
//====================================================

void setColor(bool r, bool g, bool b) {

  digitalWrite(RED_PIN, r);
  digitalWrite(GREEN_PIN, g);
  digitalWrite(BLUE_PIN, b);
}

//====================================================
// UPDATE STATE LED
//====================================================

void updateStateLED() {

  switch(currentState) {

    case OCUPADO:

      // ROJO
      setColor(HIGH, LOW, LOW);

      Serial.println("STATE: OCUPADO");
      break;

    case LIMPIEZA:

      // NARANJA
      setColor(HIGH, HIGH, LOW);

      Serial.println("STATE: LIMPIEZA");
      break;

    case INSPECCION:

      // AMARILLO
      setColor(LOW, HIGH, LOW);

      Serial.println("STATE: INSPECCION");
      break;

    case LISTO:

      // VERDE
      setColor(LOW, HIGH, LOW);

      Serial.println("STATE: LISTO");
      break;
  }
}

//====================================================
// AUTH REQUEST
//====================================================

void requestAuthentication(String pin) {

  StaticJsonDocument<256> doc;

  doc["device_id"] = deviceId;
  doc["pin"] = pin;

  char buffer[256];

  serializeJson(doc, buffer);

  client.publish(
    "hotel/auth/request",
    buffer
  );

  Serial.println("AUTH REQUEST SENT");
}

//====================================================
// AUTH RESPONSE
//====================================================

void handleAuthResponse(JsonDocument& doc) {

  String status = doc["status"];

  if (status == "ok") {

    authenticated = true;

    currentUser = doc["user"].as<String>();
    currentRole = doc["role"].as<String>();
    sessionId = doc["session"].as<String>();

    Serial.println("\n===== LOGIN SUCCESS =====");

    Serial.print("USER: ");
    Serial.println(currentUser);

    Serial.print("ROLE: ");
    Serial.println(currentRole);

    Serial.print("SESSION: ");
    Serial.println(sessionId);

    Serial.println("=========================\n");

  } else {

    authenticated = false;

    Serial.println("ACCESS DENIED");
  }
}

//====================================================
// MQTT CALLBACK
  //====================================================

  void mqttCallback(
      char* topic,
      byte* payload,
      unsigned int length
    ) {

        String message = "";

        for (int i = 0; i < length; i++) {

          message += (char)payload[i];
        }

        Serial.println("\nMQTT MESSAGE:");
        Serial.println(message);

        StaticJsonDocument<256> doc;

        DeserializationError error =
          deserializeJson(doc, message);

        if (error) {

          Serial.println("JSON ERROR");
          return;
        }

        String authTopic =
          "hotel/auth/response/" + deviceId;

        if (String(topic) == authTopic) {

          handleAuthResponse(doc);
        }
    }

//====================================================
// KEYPAD LOGIN
  //====================================================
  void processKeypadLogin() {

    static String enteredPIN = "";

    char key = keypad.getKey();

    if (key) {

      Serial.print("KEY: ");
      Serial.println(key);

      // CONFIRMAR PIN
      if (key == '#') {

        Serial.print("PIN ENTERED: ");
        Serial.println(enteredPIN);

        requestAuthentication(enteredPIN);

        enteredPIN = "";
      }

      // BORRAR
      else if (key == '*') {

        enteredPIN = "";

        Serial.println("PIN CLEARED");
      }

      // AGREGAR DIGITO
      else {

        enteredPIN += key;
      }
    }
  }

//====================================================
  // TEST FSM
  //====================================================

  void processStateMachineTest() {

    static unsigned long lastChange = 0;

    if (millis() - lastChange > 8000) {

      lastChange = millis();

      switch(currentState) {

        case OCUPADO:
          currentState = LIMPIEZA;
          break;

        case LIMPIEZA:
          currentState = INSPECCION;
          break;

        case INSPECCION:
          currentState = LISTO;
          break;

        case LISTO:
          currentState = OCUPADO;
          break;
      }

      updateStateLED();
    }
  }

//====================================================
// SETUP
//====================================================

void setup() {

  Serial.begin(115200);

  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);

  updateStateLED();

  connectWiFi();

  client.setServer(mqtt_server, 1883);

  client.setCallback(mqttCallback);

  connectMQTT();

  Serial.println("\nSYSTEM READY");
  Serial.println("ENTER PIN + #");
}

//====================================================
// LOOP
//====================================================

void loop() {

  if (!client.connected()) {

    connectMQTT();
  }

  client.loop();

  processKeypadLogin();

  processStateMachineTest();
}