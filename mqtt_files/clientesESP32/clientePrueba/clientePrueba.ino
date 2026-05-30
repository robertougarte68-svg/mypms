#include <WiFi.h>
#include <PubSubClient.h>

// ================= WIFI =================
const char* ssid = "COMTECO-N4938483";
const char* password = "D4Z3T4C2C1V8";

// ================ MQTT ==================
const char* mqtt_server = "192.168.100.66"; // IP de tu PC
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

// ============== ROOM INFO ===============
String roomId = "room101";

// ============== PINES ===================
const int BTN_CLEAN = 18;
const int LED_CLEAN = 2;

// ========================================

void setup_wifi() {
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    Serial.println("intentando conectar al wifi...");
    delay(500);
  }
 Serial.println("'conectado al wifi'");
}

//conectar al broquier mqtt
void reconnect() {

  while (!client.connected()) {
  Serial.println("intentando conectar al broker...");
    if (client.connect(roomId.c_str())) {

      // escuchar comandos
      String topic = "hotel/" + roomId + "/cmd";
      client.subscribe(topic.c_str());

      // avisar online
      String statusTopic = "hotel/" + roomId + "/status";
      client.publish(statusTopic.c_str(), "I'm online");
      Serial.println("conectado al broker");

    } else {
        Serial.print("MQTT error: ");
       Serial.println(client.state());
      delay(2000);
    }
  }
}

// FUNCION DE SUSCRIPCION PARA ATENDER LOS COMANDOS LLEGADOS PARA EL
void callback(char* topic, byte* payload, unsigned int length) {

  String message = "";
  //capturar comandos
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.println(message);

  if (message == "led_on") {
    digitalWrite(LED_CLEAN, HIGH);
  }

  if (message == "led_off") {
    digitalWrite(LED_CLEAN, LOW);
  }

}

void setup() {

  pinMode(BTN_CLEAN, INPUT_PULLUP);
  pinMode(LED_CLEAN, OUTPUT);

  Serial.begin(115200);

  setup_wifi();
  Serial.println(WiFi.localIP());

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {

  if (!client.connected()) {
    reconnect();
  }

  client.loop();

  // botón presionado
  if (digitalRead(BTN_CLEAN) == LOW) {

    String topic = "hotel/" + roomId + "/event";

    client.publish(topic.c_str(), "clean");

    digitalWrite(LED_CLEAN, HIGH);

    delay(500);
  }
  else{
  String myTopic = "hotel/" + roomId + "/event";
  client.publish(myTopic.c_str(), "wey no jodas");
  delay(1000);
  }

}