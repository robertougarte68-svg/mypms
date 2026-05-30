const { dbPromise } = require("./db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
require("dotenv").config();

async function autenticarUserPin(room, device_id, pin) {
  try {
    const sqlRoom = `
      SELECT state
      FROM rooms
      WHERE number = ? AND device = ?
    `;

    const sqlUser = `
      SELECT users.*, roles.rol
      FROM users
      JOIN roles ON roles.id = users.id_rol
      WHERE users.id = ?
    `;

    // room
    const [rooms] = await dbPromise.query(sqlRoom, [room, device_id]);

    if (!rooms.length) return null;

    const room_state = rooms[0].state;

    // user
    const [users] = await dbPromise.query(sqlUser, [Number(pin)]);

    if (!users.length) return null;

    const user = users[0];
    const rol = user.rol;
    const username = user.user;

    // autorizacion
    let autorizado = false;

    if (room_state === "mantenimiento" && rol === "housekeeping") {
      autorizado = true;
    }

    if (room_state === "revision" && ["supervisor", "gerente"].includes(rol)) {
      autorizado = true;
    }

    if (!autorizado) return null;
    //sesion y token
    const token = jwt.sign(
      {
        action: "setStateRoom",
        room,
        device_id,
        userId: pin,
      },
      process.env.JWT_SECRET,
      {
        expiresIn: "1m",
      },
    );

    // generar response
    const response = {
      token,
      room_state,
      username,
      rol,
    };

    return response;
  } catch (err) {
    console.log("ERROR EN CORE", err);
    return null;
  }
}
async function makeOperation(room, payload) {
  const token = payload.token;
  const device_id = payload.device_id;
  const newState = payload.newState;

  try {
    const data = jwt.verify(token, process.env.JWT_SECRET);
    if (data.device_id == device_id && data.room == room) {
      if (data.action == "setStateRoom") {
        //TODO modificar estado en db
        //ENVIAR A LA MAQUINA DE ESTADOS PARA VER SI CORRESPONDE LA ACCION
        const [rows] = await dbPromise.query(
          "UPDATE rooms SET state=? WHERE number=? AND device=?",
          [newState, room, device_id],
        );
        return true;
      }
    }
    return false;
  } catch (err) {
    console.log("Token inválido");
    return false;
  }
}

async function getRoom(n_room, device_id) {
  const sql = `SELECT * FROM rooms WHERE number=? AND device=?`;
  console.log(device_id, n_room);
  try {
    const [rows] = await dbPromise.query(sql, [n_room, device_id]);
    console.log(rows);
    return rows[0] || null;
  } catch (e) {
    console.log("error en CORE getRoom", e);
    return null;
  }
}
module.exports = {
  autenticarUserPin,
  makeOperation,
  getRoom,
};
