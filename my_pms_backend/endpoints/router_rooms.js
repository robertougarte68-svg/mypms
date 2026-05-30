const hotelmqtt = require("../mqtt/hotel_mqtt");
const express = require("express");
const { db, dbPromise } = require("../utils/db");

const routerRooms = express.Router();
routerRooms.use(express.json());
/*
Intermediario. Convierte la informacion json en objetos y viceversa. Ahorra ese paso.
Se ejecuta antes y despues de la solicitud
*/

// GET /rooms/:hotel_id/:number
routerRooms.get("/:hotel_id/:number", async (req, res) => {
  const { hotel_id, number } = req.params;

  try {
    const sql = `
      SELECT *
      FROM rooms
      WHERE hotel_id = ? AND number = ?
      LIMIT 1
    `;

    db.query(sql, [hotel_id, number], (err, results) => {
      if (err) {
        return res.status(500).json({
          error: "Error del servidor",
          details: err,
        });
      }

      if (results.length === 0) {
        return res.status(404).json({
          message: "Habitación no encontrada",
        });
      }

      res.json(results[0]);
    });
  } catch (error) {
    res.status(500).json({
      error: "Error inesperado",
    });
  }
});

// PATCH /api/rooms/update
routerRooms.patch("/update", async (req, res) => {
  try {
    const { id_room, state } = req.body;

    // validaciones básicas
    if (!id_room || !state) {
      return res.status(400).json({
        ok: false,
        message: "id_room y state son requeridos",
      });
    }

    // ejemplo MYSQL
    const sql = `
      UPDATE rooms
      SET state = ?
      WHERE id = ?
    `;

    db.query(sql, [state, id_room], (err, result) => {
      if (err) {
        console.error(err);

        return res.status(500).json({
          ok: false,
          message: "Error del servidor con la DB",
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          ok: false,
          message: "Room no encontrada",
        });
      }

      res.status(200).json({
        ok: true,
        message: "Estado actualizado",
      });

      //IMPLEMENTAR ACTUALIZACION MQTT
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      ok: false,
      message: "Error del servidor no identificado",
    });
  }
});
//RETORNA EL ID DE  LA HABITACION
routerRooms.get("/idroom", (req, res) => {
  console.log("endpoint room/idroom");
  const num = req.query.num;
  const idHotel = req.query.idHotel;
  const sql = "SELECT id FROM rooms WHERE number=? AND hotel_id=?";
  db.query(sql, [num, idHotel], (err, dbres) => {
    if (err) {
      return res.status(500).json({ error: `${err}` });
    }
    if (dbres.length === 0) {
      return res.status(404).json({ error: "Habitación no encontrada" });
    } else {
      console.log(dbres);
      return res.status(200).json(dbres[0]);
    }
  });
});
// RETORNA TODAS LAS HABITACIONES DEL HOTEL
routerRooms.get("/:hotel_id", (req, res) => {
  const hotel_id = Number(req.params.hotel_id);
  // console.log(hotel_id);

  if (isNaN(hotel_id)) {
    return res.status(400).json({
      error: "hotel_id inválido",
    });
  }

  const sql = "SELECT * FROM rooms WHERE hotel_id = ?";

  db.query(sql, [hotel_id], (err, results) => {
    if (err) return res.status(500).json(err);

    res.json(results);
  });
});
//solicita todas las habitaciones
routerRooms.post("/", (req, res) => {
  const { number, name, price, features, hotel_id } = req.body;
  const sql =
    "INSERT INTO rooms (number,name,price,features,hotel_id) VALUES (?,?,?,?,?)";
  db.query(sql, [number, name, price, features, hotel_id], (err, result) => {
    if (err) return res.status(500).json(err);
    console.log("posteado de habitacion realizado");
    res.status(201).json({ message: "room added", id: result.insertId });
    //TODO implementar mejor los estados
    // res.json();
  });
});

//actualizar todos los campos de la room con 'id'
routerRooms.patch("/:id", (req, res) => {
  const room = req.body;
  const campos = Object.keys(room);
  const valores = Object.values(room);
  const setClause = campos.map((c) => `${c}=?`).join(", ");
  const id = parseInt(req.params.id);
  // console.log(value, id);
  const sql = `UPDATE rooms SET ${setClause} WHERE id=?`;
  db.query(sql, [...valores, id], (err, results) => {
    if (err) return res.status(500).json(err);
    hotelmqtt.sendRoomCommand(room.number, "set_state_room", {
      roomState: room.state,
    });
    res.json(results);
  });
});

//parcha solo el campo 'item' de la room con 'id'
routerRooms.patch("/item/:id", async (req, res) => {
  const item = req.body;
  const key = Object.keys(item)[0];
  const value = item[key];
  const id = parseInt(req.params.id);
  const sql = `UPDATE rooms SET ${key}=? WHERE id=?`;
  const sqln = `SELECT number FROM rooms WHERE id=?`;

  let n_room;

  try {
    const [results] = await dbPromise.query(sql, [value, id]);

    const [rows] = await dbPromise.query(sqln, [id]);

    if (rows.length === 0) {
      return res.status(404).json({
        error: "room no encontrada",
      });
    }

    n_room = rows[0].number;

    // MQTT
    if (key === "state") {
      hotelmqtt.sendRoomCommand(n_room, "set_state_room", { roomState: value });
    }
    if (key === "device" && value === null) {
      hotelmqtt.sendUnpairingDevice(n_room);
    }
    return res.status(200).json(results);
  } catch (e) {
    console.log(e);

    return res.status(500).json(e);
  }
});

routerRooms.delete("/:id", (req, res) => {
  // var value=req.body['state'];
  const id = parseInt(req.params.id);
  // console.log(id);
  const sql = "DELETE FROM rooms WHERE id=?";
  db.query(sql, [id], (err, results) => {
    if (err) {
      console.log(err);
      return res.status(500).json(err);
    }
    res.json(results);
  });
});

//agrega un nuevo hotel
routerRooms.post("/hotel", (req, res) => {
  const { hotelname, owner, rooms, code } = req.body;
  const sql =
    "INSERT INTO hoteles (hotelname,owner,rooms,code) VALUES (?,?,?,?)";
  db.query(sql, [hotelname, owner, rooms, code], (err, result) => {
    if (err) return res.status(500).json(err);
    console.log("posteado de hotel realizado");
    res.status(201).json({ message: "hotel added", id: result.insertId });
    //TODO implementar mejor los estados
    // res.json();
  });
});

module.exports = routerRooms;
