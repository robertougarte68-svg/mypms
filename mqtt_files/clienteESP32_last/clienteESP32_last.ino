#include <WiFi.h>
#include <PubSubClient.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include <Keypad.h>
#define RESET_BUTTON 0



//====================================================
// WIFI
  //====================================================
  const char* WIFI_SSID = "COMTECO-N4938483";
  const char* WIFI_PASS = "D4Z3T4C2C1V8";

//====================================================
// MQTT
  //====================================================
  const char* MQTT_HOST = "192.168.100.66";

  // const char* WIFI_SSID = "TUKUYPAQ";
  // const char* WIFI_PASS = "u0+jBGT4md#";

  // const char* MQTT_HOST = "192.168.100.248";

  const int MQTT_PORT = 1883;

  WiFiClient espClient;
  PubSubClient mqtt(espClient);

//====================================================
// DEVICE
    //====================================================
    Preferences preferences;

    String deviceId;
    String roomNumber = "";
    String roomId = "";
    String roomState = "";
    bool paired = false;

    // TOPICS
    
    String pairingTopic;
    String configTopic;
    String roomStatusTopic;
    String roomCommandTopic;
    String currentConfigTopic;
    String unpairingTopic;
    unsigned long lastPairingMsg = 0;

    // ROOM STATES
    enum RoomState {
      OCUPADO,
      LIMPIEZA,
      INSPECCION,
      LISTO
    };
    RoomState currentState;
    bool NoKeyPad=false;

//====================================================
// AUTH SESION DATA
  //====================================================
  unsigned long pressStart = 0;//timer para boton reset
  unsigned timerA=0;
  bool arriveAuthRes=false;
  //AUTH
  bool authenticated = false;
  String authResTopic="";
  String currentRole = "";
  String currentUser = "";
  String sessionId = "";
  String token ="";
  bool loging=false;
  bool showed=false;

//====================================================
//====================================================
// OPERACION DATA
  //====================================================
  String operarResTopic;
  bool waitRes=false;
  unsigned long timerRes=0;

//==============================================
// HARDWARE 
    //====================================================
    //RGB LED PINS
    #define RED_PIN     5
    #define GREEN_PIN   18
    #define BLUE_PIN    19

    // KEYPAD
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
void  handleUnpairing(JsonDocument& doc){
   if (doc["confirm"]){
     myFactoryReset();
   }
}

void handlePairingConfig(JsonDocument& doc){
      bool approved = doc["paired"];

    if (approved) {

      roomNumber = doc["room_n"].as<String>();
      roomId = doc["room_id"].as<String>();
      roomState = doc["state"].as<String>();

      preferences.begin("config", false);

      preferences.putBool("paired", true);
      preferences.putString("room_n", roomNumber);
      preferences.putString("room_id", roomId);

      preferences.end();

      paired = true;

      Serial.print("DISPOSITIVO EMPAREJADO, NROOM:");
      Serial.println(roomNumber);
      ESP.restart();
    }
}
void getCurrentConfig() {

  String topic = "hotel/room/" + roomNumber + "/configRequest";

  StaticJsonDocument<256> doc;
  doc["device_id"] = deviceId;

  String payload;
  serializeJson(doc, payload);

  bool ok = mqtt.publish(topic.c_str(), payload.c_str());

  Serial.print("CURRENT CONFIG REQUEST SENT?: ");
  Serial.println(ok);

  Serial.println(payload);
}
void handleConfigRes(JsonDocument& doc){
    String newState=doc["roomStatus"];
    setRoomState(newState);
}

void handleAuthResponse(JsonDocument& doc) {
  
  String status = doc["status"];

  if (status == "ok") {
    // timerA=millis();
    authenticated = true;

    currentUser = doc["username"].as<String>();
    currentRole = doc["rol"].as<String>();
    // sessionId = doc["sessionId"].as<String>();
    token = doc["token"].as<String>();
    // String room_state = doc["room_state"].as<String>();//TODO sin uso

    Serial.println("\n===== LOGIN SUCCESS =====");

    Serial.print("USER: ");
    Serial.println(currentUser);

    Serial.print("ROLE: ");
    Serial.println(currentRole);

    Serial.print("TOKEN: ");
    Serial.println(token);

    Serial.println("=========================\n");

  } else {
    Serial.println("ACCESS DENIED");
     clearSession();
  }
}
void requestAuthentication(String pin) {

  StaticJsonDocument<256> doc;

  doc["device_id"] = deviceId;
  doc["pin"] = pin;

  char buffer[256];

  serializeJson(doc, buffer);
  String topic="hotel/room/" + roomNumber + "/authRequest";

  mqtt.publish(
    topic.c_str(),
    buffer
  );

  Serial.println("AUTH REQUEST SENT");
}
void handleOperarRes(JsonDocument& doc){
  String res=doc["res"].as<String>();
  if(res=="done"){
    String state = doc["newState"].as<String>();
    Serial.println(state);
    setRoomState(state);
    Serial.println("ESTADO CAMBIADO");
  
  }
  else{
    Serial.println(res+"... ALGO SALIO MAL");
  }
    clearSession();
}
void handleRoomCommand(JsonDocument& doc){
      String command = doc["command"];
      if (command == "set_state_room") {
          setRoomState(doc["roomState"]);
    }    
}
void processKeypadLogin() {

  static String enteredPIN = "";

  char key = keypad.getKey();

  if (key) {
    loging=true;

    // Serial.print("KEY: ");
    Serial.print(key);

    // CONFIRMAR PIN
    if (key == '#') {

      // Serial.print("PIN ENTERED: ");
      // Serial.println(enteredPIN);

      requestAuthentication(enteredPIN);
      enteredPIN = "";
      NoKeyPad=true;
      // timerA=millis();
      // Serial.println("wait response....");
      //     while(!arriveAuthRes&&(millis()-timerA<10000)){
      //         delay(5);
      //  }
      //  if(!arriveAuthRes){
      //   Serial.println("Serivor no disponible");
      //  }
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
void setRoomState(String state){
      if(state == "revision"){
          currentState = INSPECCION;
      }
      else if(state == "libre"){
          currentState = LISTO;
      }
      else if(state == "mantenimiento"){
          currentState = LIMPIEZA;
      }
      else if(state == "ocupado"){
          currentState = OCUPADO;
      }
      updateStateLED();
}
void updateStateLED() {

    switch(currentState) {

      case OCUPADO:

        // ROJO
        setColor(255, 0, 0);

        Serial.println("STATE: OCUPADO");
        break;

      case LIMPIEZA:

        // NARANJA
        setColor(200, 150, 0);

        Serial.println("STATE: LIMPIEZA");
        break;

      case INSPECCION:

        // AMARILLO
        setColor(100, 255, 0);

        Serial.println("STATE: INSPECCION");
        break;

      case LISTO:

        // VERDE
        setColor(0, 255, 0);

        Serial.println("STATE: LISTO");
        break;
    }
}


void showCurrentState() {
  static unsigned long timerS=0;

  if (millis()-timerS > 5000){
    timerS=millis();


    switch(currentState) {

      case OCUPADO:
        Serial.println("ROOM: OCUPADO");
        break;

      case LIMPIEZA:
        Serial.println("ROOM: LIMPIEZA");
        break;

      case INSPECCION:
        Serial.println("ROOM: INSPECCION");
        break;

      case LISTO:
        Serial.println("ROOM: LISTO");
        break;
    }


  }
  
}
void showAvailableActions() {

  Serial.println("\nAVAILABLE ACTIONS:");

  if (currentRole == "housekeeping") {

    if (currentState == LIMPIEZA) {

      Serial.println("A = COMPLETE CLEANING");
    }
  }

  if (currentRole == "supervisor"||currentRole=="gerente") {

    if (currentState == INSPECCION) {

      Serial.println("A = APPROVE");
      Serial.println("B = REJECT");
    }
  }

  Serial.println("C = CANCEL");//logout
  showed=true;
}

void approveInspection() {

  if (currentState != INSPECCION) {

    Serial.println("INVALID STATE");
    clearSession();
    return;
  }

  if (!(currentRole == "supervisor"||currentRole=="gerente")) {

    Serial.println("ONLY SUPERVISOR");
    clearSession();
    return;
  }

  StaticJsonDocument<512> doc;

  doc["action"] = "success_inspection";
  doc["device_id"] = deviceId;
  doc["token"] = token;
  doc["newState"]="libre";

  //implementar en el servidor check satateMachine

  char buffer[512];

  serializeJson(doc, buffer);
  String topic="hotel/room/"+roomNumber+"/operarRequest";

  mqtt.publish(
    topic.c_str(),
    buffer
  );
  

}
void rejectInspection() {

  if (currentState != INSPECCION) {

    Serial.println("INVALID STATE");
    clearSession();
    return;
  }

  if (!(currentRole == "supervisor"||currentRole=="gerente")) {

    Serial.println("ONLY SUPERVISOR");
    clearSession();
    return;
  }

  StaticJsonDocument<512> doc;

  doc["action"] = "rejected_inspection";
  doc["device_id"] = deviceId;
  doc["token"] = token;
  doc["newState"]="mantenimiento";

  //implementar en el servidor check satateMachine

  char buffer[512];

  serializeJson(doc, buffer);
  String topic="hotel/room/"+roomNumber+"/operarRequest";

  mqtt.publish(
    topic.c_str(),
    buffer
  );
}
void processFSMInputs() {
  // bool done=false;
  // while(done==false){
    char key = keypad.getKey();

    // if (!key) return;

    switch(key) {


      case 'A':
        if(currentRole == "housekeeping"){
          completeCleaning();//clearSession si hay incongruencia
        }
        else if(currentRole == "supervisor"||currentRole=="gerente"){
          approveInspection();
        }    
        timerRes=millis();
        waitRes=true;
        break;



      case 'B':
          if(currentRole == "supervisor"||currentRole=="gerente"){
            rejectInspection();
            timerRes=millis();
           waitRes=true;
          }

        break;


      case 'C':
        Serial.println("LOGOUT");
        clearSession();

        break;
    }
}
void completeCleaning() {

  if (currentState != LIMPIEZA) {
    //salir y reconfigurar maquina de estados
    Serial.println("INVALID STATE");
    clearSession();
    return;//ejecutar clean session
  }

  if (currentRole != "housekeeping") {
    //salir y reconfigurar maquina de estados
    Serial.println("ONLY HOUSEKEEPING");
    clearSession();
    return;
  }
  //ENVIAR MODIFICACION AL SERVIDOR

    StaticJsonDocument<512> doc;

  doc["action"] = "cleaning_completed";
  doc["device_id"]=deviceId;
  doc["token"] = token;
  doc["newState"]="revision";

  //implementar en el servidor check satateMachine

  char buffer[512];

  serializeJson(doc, buffer);
  String topic="hotel/room/"+roomNumber+"/operarRequest";

  mqtt.publish(
    topic.c_str(),
    buffer
  );
  


}
void clearSession() {

  authenticated = false;
  showed=false;
  currentRole = "";
  currentUser = "";
  sessionId = "";

  loging=false;
  NoKeyPad=false;
  authenticated=false;
  waitRes=false;
  Serial.println("SESSION CLEARED");
}

//====================================================
// SETUP
  //====================================================
  void setup() {

    Serial.begin(115200);
    //HARDWARE
    pinMode(RED_PIN, OUTPUT);
    pinMode(GREEN_PIN, OUTPUT);
    pinMode(BLUE_PIN, OUTPUT); 
    updateStateLED();     

    deviceId = getDeviceId();
    pairingTopic = "hotel/pairing/available";//topico para anunciar disponibilidad
    configTopic =  "hotel/pairing/" + deviceId + "/config";//topico para recibir configuracion inicial

    loadConfig(); //cargar preferences-config (configuracion flash) y crear topics en caso de paired
    connectWiFi();
    mqtt.setServer(MQTT_HOST, MQTT_PORT);
    mqtt.setBufferSize(512);
    mqtt.setCallback(mqttCallback); //setear acciones para los topics (de configuracion en caso de no paired)
    connectMQTT(); // se queda aqui hasta conectar

    if (paired) {   
        roomStatusTopic="hotel/room/"+roomNumber+"/status";//para enviar status
        roomCommandTopic="hotel/room/"+roomNumber+"/command";
        currentConfigTopic="hotel/room/"+roomNumber+"/configRes";
        authResTopic="hotel/room/"+roomNumber+"/authResponse";
        operarResTopic="hotel/room/"+roomNumber+"/operarRes";
        unpairingTopic="hotel/room/"+roomNumber+"/unpairing";
        mqtt.subscribe(roomCommandTopic.c_str()); //escuchar topicos nomales
        mqtt.subscribe(authResTopic.c_str());//escuchar topico de autenticacion con pin
        mqtt.subscribe(operarResTopic.c_str());//escuchar confirmacion de modificacion
        mqtt.subscribe(currentConfigTopic.c_str());//escuchar recepcion de configuracion actual
        mqtt.subscribe(unpairingTopic.c_str());//desemparejar y resetear
        getCurrentConfig();
        Serial.println("MODO: EN OPERACION ");
        Serial.println("\nSYSTEM READY");

        // Serial.println("ENTER PIN + #");
      } else {
        mqtt.subscribe(configTopic.c_str());
        Serial.println("MODO: EN EMPAREJAMIENTO");
    }
  }

//====================================================
// LOOP
//====================================================

  void loop() {

    if (!mqtt.connected()) {
      connectMQTT();
    }
    mqtt.loop();
    if (!paired) {
      sendPairingBeacon();
    }
    else{
    // MODO NORMAL     
    //enviar estado al backend 
    static unsigned long lastStatus = 0;//static=solo una vez en 0
    if ((millis() - lastStatus > 10000)&&(!loging)) {//para produccion se debe seguir enviando el status
      lastStatus = millis();
      sendRoomStatus();
      //mostrar estado fisicamente
      showCurrentState();
    }   

    //esperando login//bloquear recepcion keypad despues de #
      if(!NoKeyPad){
      processKeypadLogin();//si key=#. se envia el loginRequest
      }

      // arriveAuthRes=false;//ya respondio el servidor o expiro tiempo de espera
      if(!waitRes){
       
        if(authenticated){//waitRes =true despues de elegir la operacion
          if(showed==false){
          showAvailableActions();
          }
          processFSMInputs();// se envio el informe de la operacion, esperar confirmacion
        }
      } else{
        if(millis()-timerRes>5000){
          Serial.println("TIME OUT");
          clearSession();
        }
      }

    }


    //TODO limpiar la pantalla

    // atento a factory reset
    checkFactoryReset();
    delay(20);
  }

String getDeviceId() {
  uint64_t chipid = ESP.getEfuseMac();

  char id[20];

  sprintf(
    id,
    "ESP32_%04X%08X",
    (uint16_t)(chipid >> 32),
    (uint32_t)chipid
  );

  return String(id);
}

void connectWiFi() {

  WiFi.begin(WIFI_SSID, WIFI_PASS);

  while (WiFi.status() != WL_CONNECTED) {
    Serial.println("intentando conectar a la red wifi");
    delay(500);
  }
   Serial.println("\nWiFi Connected");
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  
  String incoming;
  String topicStr = String(topic);

  for (int i = 0; i < length; i++) {
    incoming += (char)payload[i];
  }
  Serial.println("MENSAJE MQTT RECIBIDO:");
  Serial.println(topicStr);
  Serial.println(incoming);
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, incoming);
  if (error) {
    Serial.println("ERROR JSON EN mqtt Callback");
    return;
  }
  // CONFIG
  if (topicStr == configTopic) {
    handlePairingConfig(doc);
  } else if (topicStr == roomCommandTopic) {
    handleRoomCommand(doc);
  } else if(topicStr==authResTopic){//"hotel/room/"+roomNumber+"/authResponse"
      handleAuthResponse(doc);
  } else if(topicStr==operarResTopic){//"hotel/room/"+roomNumber+"/operarRes"
      handleOperarRes(doc);     
  } else if(topicStr==currentConfigTopic){//"hotel/room/"+roomNumber+"/configRes"      
        handleConfigRes(doc);
  } else if(topicStr==unpairingTopic){
      handleUnpairing(doc);
  }
}
void connectMQTT() {

  while (!mqtt.connected()) {

    Serial.println("Intentando conectar al broker MQTT...");

    if (mqtt.connect(deviceId.c_str())) {

      Serial.println("MQTT conectado");

    //   mqtt.subscribe(configTopic.c_str());//escuchar topico de configuracion inicial
    // if(paired){
    //     mqtt.subscribe(roomCommandTopic.c_str());
    //     mqtt.subscribe(authResTopic.c_str());
    //     mqtt.subscribe(operarResTopic.c_str());
    //     mqtt.subscribe(currentConfigTopic.c_str());
    // }

    // } else {

    //   
   }
  delay(2000);
  }
}

void sendPairingBeacon() {

  if (millis() - lastPairingMsg < 5000)
    return;

  lastPairingMsg = millis();

  DynamicJsonDocument doc(256);

  doc["device_id"] = deviceId;
  doc["ip"] = WiFi.localIP().toString();

  String payload;

  serializeJson(doc, payload);

  mqtt.publish(pairingTopic.c_str(), payload.c_str());

  Serial.println("PAIRING BEACON ENVIADO");
}

void sendRoomStatus() {

  DynamicJsonDocument doc(256);
  switch(currentState){
    case OCUPADO:
      doc["state"] = "ocupado";
      break;
    case LIMPIEZA:
      doc["state"] = "mantenimiento";
      break;
    case INSPECCION:
      doc["state"] = "revision";
      break;
    case LISTO:
      doc["state"] = "libre";
      break;
  }
  
  doc["temp"] = 24.5;
  doc["humo"] = false;

  String payload;

  serializeJson(doc, payload);
 
  mqtt.publish(roomStatusTopic.c_str(), payload.c_str());
  Serial.println(payload);
}
void loadConfig() {

  preferences.begin("config", true);

  paired = preferences.getBool("paired", false);

  roomNumber = preferences.getString("room_n", "");
  roomId=preferences.getString("room_id","");
   Serial.print("room number: " );
   Serial.println(roomNumber);
   Serial.print("room id: ");
   Serial.println(roomId);

  preferences.end();

}


//====================================================
// RGB CONTROL
//====================================================

void setColor(int r, int g, int b) {

  analogWrite(RED_PIN, r);
  analogWrite(GREEN_PIN, g);
  analogWrite(BLUE_PIN, b);
}

void checkFactoryReset() {

  if (digitalRead(RESET_BUTTON) == LOW) {

    if (pressStart == 0)
      pressStart = millis();

    if (millis() - pressStart > 5000) {

      myFactoryReset();

    }

  } else {

    pressStart = 0;
  }
}

void myFactoryReset(){
      preferences.begin("config", false);

      preferences.clear();

      preferences.end();

      ESP.restart();
}
