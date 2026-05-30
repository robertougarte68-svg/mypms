// mqttClient.js

const mqtt = require("mqtt");
const EventEmitter = require("events");

class HotelMQTT extends EventEmitter {
  constructor() {
    super();

    this.client = mqtt.connect("mqtt://localhost:1883", {
      clientId: "hotel_backend",
      clean: true,
      reconnectPeriod: 3000,
    });

    this.init();
  }

  init() {
    //gestion de conexion
    this.client.on("connect", () => {
      console.log(`MQTT conectado`);

      //SUSCRIPCIONES:
      // estados de habitaciones
      this.client.subscribe("hotel/room/+/status");

      // sensores
      this.client.subscribe("hotel/room/+/temperature");
      this.client.subscribe("hotel/room/+/smoke");

      // heartbeat
      this.client.subscribe("hotel/room/+/ping");
    });
    //gestion de mensansajes escuchados en los topicos susctitos
    this.client.on("message", async (topic, message) => {
      try {
        const payload = JSON.parse(message.toString());

        console.log(topic, payload);

        // routing principal
        await this.routeMessage(topic, payload);
      } catch (err) {
        console.error("MQTT error:", err.message);
      }
    });
    //gestion de desconexion
    this.client.on("offline", () => {
      console.log("MQTT offline");
    });
    //gestion de reconexion
    this.client.on("reconnect", () => {
      console.log("Reconectando MQTT...");
    });
  }

  async routeMessage(topic, payload) {
    // hotel/room/101/status
    const parts = topic.split("/");

    const room = parts[2];
    const type = parts[3];

    switch (type) {
      case "status":
        await this.handleRoomStatus(room, payload);
        break;

      case "temperature":
        await this.handleTemperature(room, payload);
        break;

      case "smoke":
        await this.handleSmoke(room, payload);
        break;

      case "ping":
        await this.handleHeartbeat(room, payload);
        break;
    }
  }

  async handleRoomStatus(room, payload) {
    /*
      payload:
      {
        status: "occupied",
        timestamp: 123456
      }
    */

    console.log(`Habitacion ${room}: ${payload.status}`);

    // guardar en db
    // emitir websocket
    // validar transiciones
    // registrar logs
  }

  async handleTemperature(room, payload) {
    /*
      {
        value: 28.4
      }
    */
    // guardar historico
    // alertas si excede limites
  }

  async handleSmoke(room, payload) {
    /*
      {
        detected: true
      }
    */
    // alerta inmediata
    // websocket
    // notificacion
  }

  async handleHeartbeat(room, payload) {
    // actualizar ultima conexion del terminal
  }

  // enviar comandos al ESP32
  sendRoomCommand(room, command, data = {}) {
    const topic = `hotel/room/${room}/command`;

    this.client.publish(
      topic,
      JSON.stringify({
        command,
        data,
        timestamp: Date.now(),
      }),
    );
  }
}

module.exports = new HotelMQTT();
