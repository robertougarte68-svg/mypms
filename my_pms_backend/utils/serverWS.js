const WebSocket = require("ws");
const hotelmqtt = require("../mqtt/hotel_mqtt");
const { db, dbPromise } = require("../utils/db");

const wss = new WebSocket.Server({ port: 3500 });

console.log("WebSocket server on ws://localhost:3500");

wss.on("connection", (ws) => {
  console.log("Cliente conectado");
  // escuchar mensajes del cliente
  ws.on("message", (message) => {
    const decoded = JSON.parse(message);

    console.log("Mensaje:", decoded);

    switch (decoded.event) {
      case "pair_device":
        //IMPLEMENTAR LOGICA DE EMPAREJAMIENTO
        hotelmqtt.sendConfigDevice(
          decoded.data.room_id,
          decoded.data.room_n,
          decoded.data.device_id,
          decoded.data.state,
        );

        const sql = `UPDATE rooms SET device=? WHERE id=?`;

        db.query(
          sql,
          [decoded.data.device_id, decoded.data.room_id],
          (err, res) => {
            if (err) {
              console.log(err);
              return;
            }

            console.log("room actualizada");
          },
        );

        break;
    }
  });

  ws.on("close", () => {
    console.log("Cliente desconectado");
  });
});

hotelmqtt.setWss(wss);

module.exports = { wss };
