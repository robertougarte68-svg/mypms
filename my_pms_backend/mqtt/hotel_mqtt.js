// mqttClient.js
// const wss=require
const { db, dbPromise } = require("../utils/db");
const mqtt = require("mqtt");
const core = require("../utils/core");
const EventEmitter = require("events");
class HotelMQTT extends EventEmitter {
  constructor() {
    super();
    this.client = mqtt.connect("mqtt://localhost:1883", {
      clientId: "servidor_backend",
      clean: true,
      reconnectPeriod: 3000,
    });
    this.availableDevices = {};
    this.wss = null;
    this.init();
    //limpiar lista de dispositivos
    setInterval(() => {
      const now = Date.now();
      let changed = false;
      for (const device_id in this.availableDevices) {
        if (now - this.availableDevices[device_id].last_seen > 6000) {
          delete this.availableDevices[device_id];
          changed = true;
        }
      }

      if (this.wss && changed) {
        this.broadcastAvailableDevices();
      }
    }, 4000);
  }

  setWss(wss) {
    this.wss = wss;
  }

  broadcastAvailableDevices() {
    const message = JSON.stringify({
      event: "available_devices",
      data: this.availableDevices,
    });

    this.wss.clients.forEach((client) => {
      if (client.readyState === 1) {
        client.send(message);
      }
    });
    console.log("dispositivos disponibles:", this.availableDevices);
  }

  init() {
    //gestion de conexion y suscribciones
    this.client.on("connect", () => {
      console.log(`MQTT conectado`);

      //SUSCRIPCIONES:
      // para emparejamiento de nevos dispositivos
      this.client.subscribe("hotel/pairing/available");
      // enviar configuracion actual a dispositivo reiniciado ya emparejado
      this.client.subscribe("hotel/room/+/configRequest");
      // solicitud de login por pin desde el device
      this.client.subscribe("hotel/room/+/authRequest");
      // solicitud para operar el device
      this.client.subscribe("hotel/room/+/operarRequest");
      // estados de habitaciones
      this.client.subscribe("hotel/room/+/status");
      // heartbeat
      this.client.subscribe("hotel/room/+/ping");
    });
    //gestion de mensansajes escuchados en los topicos susctitos. De aqui desvia a routeMessege
    this.client.on("message", async (topic, message) => {
      try {
        console.log("MENSAJE DE MQTT:");
        const payload = JSON.parse(message.toString());

        console.log("Topic: ", topic);
        console.log("messege: ", payload);

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
    //DISPOSITIVOS DISPONIBLES - EMPAREJAMIENTO
    if (topic == "hotel/pairing/available") {
      await this.handlePairing(payload);
    }

    //COMANDO
    // hotel/room/101/status
    const parts = topic.split("/");
    const room = parts[2];
    const type = parts[3];

    switch (type) {
      case "configRequest":
        await this.handleConfigRequest(room, payload);
        break;
      case "authRequest":
        await this.handleRoomAuthRequest(room, payload);
        break;
      case "operarRequest":
        await this.handleRoomOperarRequest(room, payload);
        break;
      case "status":
        await this.handleRoomStatus(room, payload);
        break;
      case "ping":
        await this.handleHeartbeat(room, payload);
        break;
    }
  }

  async handlePairing(payload) {
    //armar dispositivo disponible
    this.availableDevices[payload.device_id] = {
      ip: payload.ip,
      online: true,
      last_seen: Date.now(),
    };
    this.broadcastAvailableDevices();
  }
  async handleConfigRequest(room, payload) {
    //enviar mas informaicon si es necesario
    const data = await core.getRoom(room, payload.device_id);
    const res = { roomStatus: data.state };
    const topic = `hotel/room/${room}/configRes`;
    this.client.publish(topic, JSON.stringify(res));
  }

  async handleRoomAuthRequest(room, payload) {
    //payload={device_id, pin}

    //autenticar usuario que quiera operar el esp32\
    const data = await core.autenticarUserPin(
      room,
      payload.device_id,
      payload.pin,
    );
    let res;
    if (data) {
      res = { status: "ok", ...data }; //data={token,room_state}
    } else {
      res = { status: "deny" };
    }
    // sendRoomAuthResponse()
    const topic = `hotel/room/${room}/authResponse`;
    this.client.publish(topic, JSON.stringify(res));
    console.log("respuesta enviada desde handleRoomAuthRequest: ", res);
  }
  async handleRoomOperarRequest(room, payload) {
    const topic = `hotel/room/${room}/operarRes`;
    let data;
    if (await core.makeOperation(room, payload)) {
      data = { res: "done", newState: payload.newState };
    } else {
      data = { res: "deny" };
    }
    this.client.publish(topic, JSON.stringify(data));
  }
  async handleRoomStatus(room, payload) {
    /*
      payload:
      {
        status: "occupied",
        timestamp: 123456
      }
    */

    console.log(`Procesar RoomStatus`);

    // guardar en db
    // emitir websocket
    // validar transiciones
    // registrar logs
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
        ...data,
        timestamp: new Date().toLocaleString("es-BO", {
          hour12: false,
        }),
      }),
    );
  }

  //enviar  configuracion de emparejamiento
  sendConfigDevice(room_id, room_n, device_id, state) {
    const topic = `hotel/pairing/${device_id}/config`;
    this.client.publish(
      topic,
      JSON.stringify({
        command: "config_device",
        paired: true,
        room_n: room_n,
        room_id: room_id,
        state,
      }),
    );
  }

  //desemparejar dispositivo
  sendUnpairingDevice(room_n) {
    const topic = `hotel/room/${room_n}/unpairing`;
    this.client.publish(topic, JSON.stringify({ confirm: true }));
  }
}

module.exports = new HotelMQTT();
