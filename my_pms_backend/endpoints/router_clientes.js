const express = require("express");
const { db, dbPromise } = require("../utils/db");

const routerClients = express.Router();
routerClients.use(express.json());
/*
Intermediario. Convierte la informacion json en objetos y viceversa. Ahorra ese paso.
Se ejecuta antes y despues de la solicitud
*/

// ESTADISTICAS DE CLIENTE
// ESTADISTICAS DE CLIENTE
routerClients.get("/statics/:id", (req, res) => {
  const { id } = req.params;

  let sql = `
    SELECT

      COUNT(
        CASE 
          WHEN e.date_in >= NOW() - INTERVAL 30 DAY 
          THEN 1 
        END
      ) AS rec_30,

      COALESCE(SUM(
        CASE 
          WHEN e.date_in >= NOW() - INTERVAL 30 DAY 
          THEN e.tarifa 
          ELSE 0 
        END
      ), 0) AS ing_30,

      COUNT(
        CASE 
          WHEN e.date_in >= NOW() - INTERVAL 90 DAY 
          THEN 1 
        END
      ) AS rec_90,

      COALESCE(SUM(
        CASE 
          WHEN e.date_in >= NOW() - INTERVAL 90 DAY 
          THEN e.tarifa 
          ELSE 0 
        END
      ), 0) AS ing_90,

      COUNT(
        CASE 
          WHEN e.date_in >= NOW() - INTERVAL 365 DAY 
          THEN 1 
        END
      ) AS rec_365,

      COALESCE(SUM(
        CASE 
          WHEN e.date_in >= NOW() - INTERVAL 365 DAY 
          THEN e.tarifa 
          ELSE 0 
        END
      ), 0) AS ing_365

    FROM cls_in_sts cs
    JOIN estancias e ON e.id = cs.id_sty
    WHERE cs.id_cl = ?
  `;

  db.query(sql, [id], (err, result) => {
    if (err) {
      return res.status(500).json({
        error: "Error obteniendo estadísticas",
      });
    }

    const r = {
      stats: {
        30: [result[0].rec_30, Number(result[0].ing_30)],
        90: [result[0].rec_90, Number(result[0].ing_90)],
        365: [result[0].rec_365, Number(result[0].ing_365)],
      },
    };

    sql = `
      SELECT 
        r.cat,
        COUNT(*) AS n
      FROM cls_in_sts cs
      JOIN estancias e ON e.id = cs.id_sty
      JOIN rooms r ON r.id = e.id_room
      WHERE cs.id_cl = ?
      GROUP BY r.cat
    `;

    db.query(sql, [id], (err, result) => {
      if (err) {
        return res.status(500).json({
          error: "Error obteniendo estadísticas",
        });
      }

      const v = {
        ESTANDAR: 0,
        SUPERIOR: 0,
        DELUX: 0,
        SUITE: 0,
      };

      result.forEach((x) => {
        v[x.cat] = x.n;
      });

      r.cats = v;
      console.log(r);
      return res.status(200).json(r);
    });
  });
});

routerClients.get("/fullstays", (req, res) => {
  console.log("fullstays endpoint");
  const n = req.query.n;
  const id_hotel = req.query.id_hotel;

  let stays = [];
  let clients = [];
  let cltin = [];
  let lastid = null;

  db.query(
    `
    SELECT 
      e.*, 
      c.*,
      e.id AS id_sty,
      c.id AS id_cl,
      r.id AS id_room,
      r.number
    FROM estancias e 
    JOIN cls_in_sts cis ON e.id = cis.id_sty
    JOIN clients c ON cis.id_cl = c.id 
    JOIN rooms r ON e.id_room = r.id 
    WHERE r.hotel_id = ?
    ORDER BY e.id DESC
    LIMIT ${n}
  `,
    [id_hotel],
    (dberr, dbres) => {
      if (dberr) return res.status(500).json(dberr);

      dbres.forEach((e) => {
        if (e.id_sty !== lastid) {
          if (lastid !== null) {
            clients.push(cltin);
            cltin = [];
          }

          stays.push({
            id_stay: e.id_sty,
            id_room: e.id_room,
            number: e.number,
            mode: e.mode,
            tarifa: e.tarifa,
            pay_method: e.pay_method,
            date_in: e.date_in,
            date_out: e.date_out,
          });

          lastid = e.id_sty;
        }

        cltin.push({
          id_cl: e.id_cl,
          name: e.name,
          birth: e.birth,
          ci: e.ci,
          addr: e.addr,
          phone: e.phone,
        });
      }); //for each

      if (cltin.length > 0) {
        clients.push(cltin);
      }
      console.log({ stays: stays, clients: clients });
      console.dir(clients, { depth: null });
      res.status(200).json({ stays: stays, clients: clients });
    },
  );
});

//agregar nuevo cliente
routerClients.post("/", (req, res) => {
  const { name, birth, ci, addr, phone } = req.body;
  console.log(`formato de fecha enviado a la db ${birth}`);
  const sql =
    "INSERT INTO clients (name,birth,ci,addr,phone) VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id), name=VALUES(name), birth=VALUES(birth), ci=VALUES(ci), addr=VALUES(addr), phone=VALUES(phone)";
  db.query(sql, [name, birth, ci, addr, phone], (err, result) => {
    if (err) return res.status(500).json(err);
    res.json({ message: "User added", id: result.insertId });
  });
});

//busqueda de clientes coincidentes con parametros query
routerClients.get("/search", (req, res) => {
  const query = req.query.query || "";
  // console.log('from endpoint clientes-get-search'+query);
  // const sql=' SELECT DISTINCT id,name FROM clients WHERE LOWER(name) LIKE LOWER(?) LIMIT 5';
  const sql =
    "SELECT MIN(id) AS id, name FROM clients WHERE LOWER(name) LIKE LOWER(?) GROUP BY name LIMIT 5";
  db.query(sql, [`%${query}%`], (err, results) => {
    if (err) {
      console.log(err);
      return res.status(500).json(err);
    }
    res.json(results);
  });
});

//busqueda de clientes por query fecha, devuelve toda la info
routerClients.get("/bydate", (req, res) => {
  const { date } = req.query || "2025-09-20";
  console.log(date);
  if (!date) {
    return res.status(400).json({ error: "Parametro query no encontrado" });
  }
  const sql = " SELECT * FROM clients WHERE datein LIKE ?";
  db.query(sql, [`${date}%`], (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
});

//busqueda de cliente, devuelve toda la info
routerClients.get("/:name", (req, res) => {
  const name = req.params.name;
  const sql = " SELECT * FROM clients WHERE name=? LIMIT 1";
  db.query(sql, [name], (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
});

//busqueda de cliente por ci, devuelve toda la info
routerClients.get("/", (req, res) => {
  const query = req.query.ci;
  const sql = " SELECT * FROM clients WHERE ci=? LIMIT 1";
  db.query(sql, [query], (err, results) => {
    if (err) return res.status(500).json(err);
    if (results.length > 0) {
      var row = results[0];
      if (row.birth == null) {
        row.birth = "nulo";
      }
      // console.log(results);
      return res.status(201).json(results);
    } else {
      return res.status(404).json({ info: "no existe el cliente" });
    }
  });
});

routerClients.post("/writeCiS", (req, res) => {
  const { id_stay, id_clients } = req.body;
  if (!Array.isArray(id_clients) || id_clients.length === 0) {
    return res.status(400).json({ error: "id_clients inválido" });
  }
  let data = id_clients.map((e) => {
    return [id_stay, e];
  });
  const sql = "INSERT INTO cls_in_sts (id_sty, id_cl) VALUES ?";
  db.query(sql, [data], (dberr, dbres) => {
    if (dberr) return res.status(500).json(dberr);
    return res.status(201).json(dbres);
  });
});

module.exports = routerClients;
