const cors = require("cors"); // para permitir peticiones de distintos puertos desde el frontend
const multer = require("multer"); // para manejar uploads (comprobantes)
// dónde guardar archivos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/proofs/"); // carpeta temporal para archivos subidos
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  },
});
const upload = multer({ storage }); // carpeta temporal para archivos subidos

const QRCode = require("qrcode"); // para generar QR de pago
const { v4: uuidv4 } = require("uuid"); // para generar IDs únicos (referencias de pago)
const express = require("express"); // framework web
const { db, dbPromise } = require("../utils/db"); // conexión a la base de datos (MySQL) con promesas

const routerHotel = express.Router();
routerHotel.use(express.json());
routerHotel.use(express.urlencoded({ extended: true }));
routerHotel.use(cors());

//MODIFICAR ESTADO DE RESERVA
routerHotel.put("/reservas/:cod/estado", (req, res) => {
  const { cod } = req.params;
  const { estado } = req.body;
  const { observaciones } = req.body; // opcional, para registrar motivo de cancelación o no-show

  const sql = `UPDATE reservas SET estado = ?, observaciones = ? WHERE cod_reserva = ?`;

  db.query(sql, [estado, observaciones, cod], (err, result) => {
    if (err) return res.status(500).json({ error: err });

    res.json({ message: "Estado actualizado" });
  });
});

//OBTENER RESERVA POR CÓDIGO
routerHotel.get("/reservas/:cod", (req, res) => {
  const { cod } = req.params;

  const sql = `
    SELECT 
      r.id AS reserva_id,
      r.cod_reserva,
      r.fecha_reserva,
      r.fecha_in,
      r.fecha_out,
      r.estado,
      r.total,
      r.anticipo,
      r.metodo_pago,
      r.n_personas,
      r.observaciones,
      r.proof_url,

      c.id AS client_id,
      c.name,
      c.ci,
      c.phone,
      c.addr,
      c.birth,

      rm.id AS room_id,
      rm.number,
      rm.cat,
      rm.price,
      rm.slots,
      rm.features

    FROM reservas r
    JOIN clients c ON r.id_client = c.id
    LEFT JOIN rmsinrs rr ON rr.reserva_id = r.id
    LEFT JOIN rooms rm ON rm.id = rr.room_id

    WHERE r.cod_reserva = ?
  `;

  db.query(sql, [cod], (err, results) => {
    if (err) {
      console.log(err);
      return res.status(500).json({ error: "Error en servidor" });
    }

    if (results.length === 0) {
      return res.status(404).json({ msg: "Reserva no encontrada" });
    }
    const reservData = results[0];

    // construir respuesta
    const reserva = {
      id: reservData.reserva_id,
      cod_reserva: reservData.cod_reserva,
      fecha_reserva: reservData.fecha_reserva,
      fecha_in: reservData.fecha_in,
      fecha_out: reservData.fecha_out,
      estado: reservData.estado,
      total: reservData.total,
      anticipo: reservData.anticipo,
      metodo_pago: reservData.metodo_pago,
      n_personas: reservData.n_personas,
      observaciones: reservData.observaciones,
      proof_url: reservData.proof_url,

      client: {
        id: reservData.client_id,
        name: reservData.name,
        ci: reservData.ci,
        birth: reservData.birth,
        addr: reservData.addr,
        phone: reservData.phone,
      },

      rooms: [],
    };

    results.forEach((r) => {
      if (r.room_id) {
        reserva.rooms.push({
          id: r.room_id,
          number: r.number,
          cat: r.cat,
          price: r.price,
          slots: r.slots,
          features: r.features,
        });
      }
    });

    res.json(reserva);
  });
});

//OBTENER RESERVAS CON FILTROS DEFECTO N=10 & POR ESTADO
routerHotel.get("/reservas", (req, res) => {
  const { estado, n, fecha_inicio, fecha_fin } = req.query;

  const limit = !n || isNaN(n) || n === "0" ? 10 : parseInt(n);

  let baseSql = `
    SELECT
      r.id,
      r.cod_reserva,
      r.fecha_in,
      r.fecha_out,
      r.fecha_reserva,
      r.id_client,
      r.estado,
      r.total,
      r.anticipo,
      r.metodo_pago,
      r.n_personas,
      r.observaciones,
      r.proof_url,

      c.id AS client_id,
      c.name AS client_name,
      c.birth AS client_birth,
      c.ci AS client_ci,
      c.addr AS client_addr,
      c.phone AS client_phone

    FROM reservas r
    LEFT JOIN clients c ON r.id_client = c.id
    WHERE 1=1
  `;

  const params = [];

  // filtros
  if (estado === "0") {
    if (!fecha_inicio || !fecha_fin) {
      return res.status(400).json({
        message: "Debe enviar fecha_inicio y fecha_fin cuando estado=0",
      });
    }
    baseSql += " AND r.fecha_in BETWEEN ? AND ?";
    params.push(fecha_inicio, fecha_fin);
  }

  if (estado === "1") {
    baseSql += `
      ORDER BY
        CASE r.estado
          WHEN 'PENDIENTE' THEN 1
          WHEN 'CONFIRMADA' THEN 2
          WHEN 'CHECK_IN' THEN 3
          WHEN 'NO_SHOW' THEN 4
          WHEN 'REJECTED' THEN 5
          WHEN 'CHECK_OUT' THEN 6
          WHEN 'CANCELADA' THEN 7
          ELSE 7
        END,
        r.fecha_in ASC
    `;
  } else {
    baseSql += " ORDER BY r.fecha_in DESC";
  }

  baseSql += " LIMIT ?";
  params.push(limit);

  // 1. obtener reservas primero (SIN rooms)
  db.query(baseSql, params, (err, reservas) => {
    if (err) return res.status(500).json(err);

    const ids = reservas.map((r) => r.id);
    if (ids.length === 0) return res.json([]);

    // 2. traer rooms relacionados
    const roomsSql = `
      SELECT
        rr.reserva_id,
        rm.id,
        rm.number,
        rm.cat,
        rm.slots,
        rm.state,
        rm.price,
        rm.features,
        rm.hotel_id
      FROM rmsinrs rr
      JOIN rooms rm ON rr.room_id = rm.id
      WHERE rr.reserva_id IN (?)
    `;

    db.query(roomsSql, [ids], (err2, roomsRows) => {
      if (err2) return res.status(500).json(err2);

      const roomsMap = {};

      roomsRows.forEach((r) => {
        if (!roomsMap[r.reserva_id]) roomsMap[r.reserva_id] = [];
        roomsMap[r.reserva_id].push({
          id: r.id,
          number: r.number,
          cat: r.cat,
          slots: r.slots,
          state: r.state,
          price: r.price,
          features: r.features,
          hotel_id: r.hotel_id,
        });
      });

      const data = reservas.map((r) => ({
        id: r.id,
        cod_reserva: r.cod_reserva,
        fecha_in: r.fecha_in,
        fecha_out: r.fecha_out,
        fecha_reserva: r.fecha_reserva,
        id_client: r.id_client,
        estado: r.estado,
        total: r.total,
        anticipo: r.anticipo,
        metodo_pago: r.metodo_pago,
        n_personas: r.n_personas,
        observaciones: r.observaciones,
        proof_url: r.proof_url,

        client: r.client_id
          ? {
              id: r.client_id,
              name: r.client_name,
              birth: r.client_birth,
              ci: r.client_ci,
              addr: r.client_addr,
              phone: r.client_phone,
            }
          : null,

        rooms: roomsMap[r.id] || [],
      }));

      return res.json(data);
    });
  });
});
//CONFIRMAR RESERVA
routerHotel.post(
  "/reservas/confirm",
  upload.single("comprobante"),
  async (req, res) => {
    const datos = req.body.data;
  },
);

//CONSULTAR HABITACIONES LIBRES
routerHotel.post("/reservas/free", (req, res) => {
  const data = req.body;

  const sql = `
  SELECT * FROM rooms r
  WHERE r.hotel_id = ?
    AND r.cat = ?
    AND r.slots >= ?
    AND r.id NOT IN (
      SELECT rr.room_id
      FROM rmsinrs rr
      JOIN reservas res ON res.id = rr.reserva_id
      WHERE res.estado IN ('CONFIRMADA','CHECK_IN')
      AND (
        res.fecha_in < ?
        AND res.fecha_out > ?
      )
    )
  `;

  const params = [
    data.id_hotel,
    data.tipo_habitacion,
    data.numero_personas,
    data.fecha_salida,
    data.fecha_ingreso,
  ];

  db.query(sql, params, (err, results) => {
    if (err) {
      console.log("Error querying free rooms:", err);
      return res.status(500).json(err);
    }

    res.status(200).json(results);
  });
});

//RESERVAR HABITACION
routerHotel.post(
  "/reservas/pendiente",
  upload.single("comprobante"),
  async (req, res) => {
    const data = JSON.parse(req.body.data);
    console.log("Datos recibidos para reserva pendiente:", data);
    const { estancia, habitaciones, titular } = data;

    const conn = await dbPromise.getConnection();

    try {
      await conn.beginTransaction();

      // 1. BUSCAR CLIENTE
      let [rows] = await conn.execute("SELECT id FROM clients WHERE ci = ?", [
        titular.ci,
      ]);

      let clientId;

      if (rows.length === 0) {
        // 2. INSERTAR CLIENTE
        const [result] = await conn.execute(
          `INSERT INTO clients (name, ci, birth, addr, phone)
         VALUES (?, ?, ?, ?, ?)`,
          [
            titular.name,
            titular.ci,
            titular.birth,
            titular.addr,
            titular.phone,
          ],
        );
        clientId = result.insertId;
      } else {
        clientId = rows[0].id;
      }

      // 4. INSERTAR RESERVA
      const codReserva = "R-" + Date.now();

      const [reservaResult] = await conn.execute(
        `INSERT INTO reservas 
      (cod_reserva, fecha_in, fecha_out, id_client, estado, total, anticipo, metodo_pago, n_personas, proof_url)
      VALUES (?, ?, ?, ?, 'PENDIENTE', ?, ?, ?, ?, ?)`,
        [
          codReserva,
          estancia.fecha_in,
          estancia.fecha_out,
          clientId,
          estancia.total,
          estancia.anticipo,
          estancia.metodo_pago,
          estancia.n_personas,
          req.file.filename,
        ],
      );

      const reservaId = reservaResult.insertId;

      // 5. INSERTAR RELACIÓN N:M (habitaciones)
      for (let roomId of habitaciones) {
        await conn.execute(
          `INSERT INTO rmsinrs (reserva_id, room_id)
         VALUES (?, ?)`,
          [reservaId, roomId],
        );
      }

      // 6. COMMIT
      await conn.commit();

      res.json({
        ok: true,
        reserva_id: reservaId,
        cod_reserva: codReserva,
      });
      console.log("Reserva creada con ID:", reservaId);
    } catch (err) {
      // ROLLBACK
      await conn.rollback();

      res.status(400).json({
        ok: false,
        error: err.message,
      });
      console.error("Error processing reservation:", err);
    } finally {
      conn.release();
    }
  },
);

routerHotel.get("/fullstaysByRange", (req, res) => {
  console.log("fullstaysByRange endpoint");

  const { start, end, id_hotel } = req.query;

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
      AND e.date_in <= ?
      AND (e.date_out IS NULL OR e.date_out >= ?)
    ORDER BY e.id DESC
  `,
    [id_hotel, end, start],
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
      });

      if (cltin.length > 0) clients.push(cltin);

      res.status(200).json({ stays, clients });
    },
  );
});
//GET CATEGORIA POR ID
routerHotel.get("/categoria/:catId", (req, res) => {
  const { catId } = req.params;
  const sql = "SELECT * FROM categorias WHERE id = ?";
  db.query(sql, [catId], (err, results) => {
    if (err) return res.status(500).json(err);
    res.status(200).json(results);
  });
});
//GET CATEGORIAS TODAS
routerHotel.get("/categorias", (req, res) => {
  // const query=req.query.ci;
  const sql = " SELECT * FROM categorias ";
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json(err);
    res.status(200).json(results);
  });
});
//POST NUEVO FLUJO DE CAJA
routerHotel.post("/cashFlow", (req, res) => {
  const data = req.body;

  const sql = "INSERT INTO cashflow SET ?";
  db.query(sql, data, (err, results) => {
    if (err) return res.status(500).json(err);
    res.status(201).json(results);
  });
});
//GET FLUJO DE CAJA
routerHotel.get("/cashFlow", (req, res) => {
  const filter = req.query.filter;
  let condition = "";

  if (filter === "Dia") {
    condition = "DATE(fecha) = CURDATE()";
  } else if (filter === "Semana") {
    condition = "YEARWEEK(fecha, 1) = YEARWEEK(CURDATE(), 1)";
  } else if (filter === "Mes") {
    condition =
      "MONTH(fecha) = MONTH(CURDATE()) AND YEAR(fecha)=YEAR(CURDATE())";
  } else if (filter === "Año") {
    condition = "YEAR(fecha) = YEAR(CURDATE())";
  }

  const sql = `SELECT * FROM cashflow WHERE ${condition} ORDER BY fecha DESC`;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json(err);
    res.status(200).json(results);
  });
});
//GET INGRESOS DE ESTANCIAS
routerHotel.get("/estancias/ingresos", (req, res) => {
  const filtro = req.query.filtro;
  const hotel_id = req.query.hotel_id;
  const sql =
    'SELECT SUM(tarifa) AS total FROM estancias WHERE tipo = "ingreso"';
});
//POSTEAR NUEVA ESTANCIA
routerHotel.post("/stay", (req, res) => {
  const { id_room, mode, tarifa, pay_method } = req.body;
  const sql =
    "INSERT INTO estancias (id_room, mode, tarifa, pay_method)  VALUES (?,?,?,?)";
  // const sql2 ='INSERT INTO cls_in_sts (id_sty, id_cl) VALUES ?';

  db.query(sql, [id_room, mode, tarifa, pay_method], (err, dbres) => {
    if (err) {
      res.status(500).json({ error: err });
    } else {
      res.status(201).json({ message: "stay added", id: dbres.insertId });
    }
  });
});
//SETEAR CHECKOUT
routerHotel.patch("/checkout", (req, res) => {
  const id_stay = req.query.id_stay;
  const sql = "UPDATE estancias SET date_out=NOW() WHERE id=?";

  db.query(sql, [id_stay], (err, dbres) => {
    if (err) {
      return res.status(500).json({ error: err });
    } else {
      return res.status(200).json({ message: "checkout successful" });
    }
  });
});

//devuelve el id del hotel que coincida con el parametro hotelCode
routerHotel.get("/unirse/:hotelCode", (req, res) => {
  const hotelCode = req.params.hotelCode;
  const sql = "SELECT id FROM hoteles WHERE code=?";
  db.query(sql, hotelCode, (err, dbRes) => {
    if (err) {
      res.status(500).json({ error: err });
      console.log(err);
    } else {
      //dbRes es usualemnte un array de objetos, donde cada objeto representa una fila de la tabla
      res.status(200).json({ id: dbRes[0]?.id });
    }
  });
});
//GET ALL INGRESOS
routerHotel.get("/ingresos", (req, res) => {
  const { dias, date1, date2 } = req.query;

  let conditionEstancias = "";
  let conditionCashflow = "";
  let conditionReservas = "";

  let params = [];

  // FILTRO POR ULTIMOS N DIAS
  if (dias && dias !== "null") {
    conditionEstancias = `date_in >= NOW() - INTERVAL ? DAY`;
    conditionCashflow = `fecha >= NOW() - INTERVAL ? DAY`;
    conditionReservas = `fecha_reserva >= NOW() - INTERVAL ? DAY`;

    params = [dias, dias, dias];
  }

  // FILTRO POR RANGO DE FECHAS
  else if (date1 && date2) {
    conditionEstancias = `DATE(date_in) BETWEEN ? AND ?`;
    conditionCashflow = `DATE(fecha) BETWEEN ? AND ?`;
    conditionReservas = `DATE(fecha_reserva) BETWEEN ? AND ?`;

    params = [date1, date2, date1, date2, date1, date2];
  } else {
    return res.status(400).json({
      ok: false,
      msg: "Debe enviar dias o date1 y date2",
    });
  }

  const sql = `
    SELECT
      (
        SELECT IFNULL(SUM(tarifa), 0)
        FROM estancias
        WHERE ${conditionEstancias}
      ) AS ingresos_estancias,

      (
        SELECT IFNULL(SUM(monto), 0)
        FROM cashflow
        WHERE tipo = 'Ingreso'
        AND ${conditionCashflow}
      ) AS ingresos_cashflow,

      (
        SELECT IFNULL(SUM(anticipo), 0)
        FROM reservas
        WHERE estado = 'CONFIRMADA'
        AND ${conditionReservas}
      ) AS ingresos_anticipos
  `;

  db.query(sql, params, (err, results) => {
    if (err) {
      console.log(err);

      return res.status(500).json({
        ok: false,
        msg: "Error del servidor",
      });
    }

    const data = results[0];

    const total =
      Number(data.ingresos_estancias) +
      Number(data.ingresos_cashflow) +
      Number(data.ingresos_anticipos);

    res.status(200).json({
      ok: true,
      filtro: dias != "null" ? { dias } : { desde: date1, hasta: date2 },

      ingresos: {
        estancias: data.ingresos_estancias,
        cashflow: data.ingresos_cashflow,
        anticipos: data.ingresos_anticipos,
        total,
      },
    });
  });
});
//GET ALL EGRESOS
routerHotel.get("/egresos", (req, res) => {
  const { dias, date1, date2 } = req.query;

  let condition = "";
  let params = [];

  // ULTIMOS N DIAS
  if (dias && dias !== "null") {
    condition = `fecha >= NOW() - INTERVAL ? DAY`;

    params = [dias];
  }

  // RANGO DE FECHAS
  else if (date1 && date2) {
    condition = `DATE(fecha) BETWEEN ? AND ?`;

    params = [date1, date2];
  } else {
    return res.status(400).json({
      ok: false,
      msg: "Debe enviar dias o date1 y date2",
    });
  }

  const sql = `
    SELECT IFNULL(SUM(monto), 0) AS total_egresos
    FROM cashflow
    WHERE tipo = 'Egreso'
    AND ${condition}
  `;

  db.query(sql, params, (err, results) => {
    if (err) {
      console.log(err);

      return res.status(500).json({
        ok: false,
        msg: "Error del servidor",
      });
    }

    res.status(200).json({
      ok: true,

      filtro: dias ? { dias } : { desde: date1, hasta: date2 },

      egresos: {
        total: results[0].total_egresos,
      },
    });
  });
});
//GET SALDO ANTERIOR A: X
routerHotel.get("/saldo", (req, res) => {
  const { dias, date1, date2 } = req.query;

  let fechaInicio;

  // ULTIMOS N DIAS
  if (dias && dias !== "null") {
    fechaInicio = new Date();
    fechaInicio.setDate(fechaInicio.getDate() - Number(dias));
  }

  // RANGO DE FECHAS
  else if (date1 && date2) {
    fechaInicio = new Date(date1).toISOString().slice(0, 19).replace("T", " ");

    // console.log(fechaInicio);
  } else {
    return res.status(400).json({
      ok: false,
      msg: "Debe enviar dias o date1 y date2",
    });
  }

  // Buscar checkpoint mas cercano anterior
  const sqlBalance = `
    SELECT *
    FROM balance_mensual
    WHERE fecha_cierre <= ?
    ORDER BY fecha_cierre DESC
    LIMIT 1
  `;

  db.query(sqlBalance, [fechaInicio], (err, balanceRes) => {
    if (err) {
      console.log(err);

      return res.status(500).json({
        ok: false,
        msg: "Error del servidor",
      });
    }

    let saldoBase = 0;

    let fechaBase = new Date(0);

    if (balanceRes.length > 0) {
      saldoBase = Number(balanceRes[0].saldo);

      fechaBase = balanceRes[0].fecha_cierre;
    }
    // console.log(`saldo base=${saldoBase}  fecha base=${fechaBase}`);
    // Ajustar desde checkpoint hasta antes del periodo solicitado
    const sqlMovimientos = `
        SELECT
          (
            (
              SELECT IFNULL(SUM(tarifa), 0)
              FROM estancias
              WHERE date_in > ?
              AND date_in < ?
            )

            +

            (
              SELECT IFNULL(SUM(monto), 0)
              FROM cashflow
              WHERE tipo = 'Ingreso'
              AND fecha > ?
              AND fecha < ?
            )

            +

            (
              SELECT IFNULL(SUM(anticipo), 0)
              FROM reservas
              WHERE estado = 'CONFIRMADA'
              AND fecha_reserva > ?
              AND fecha_reserva < ?
            )
          ) AS ingresos,

          (
            SELECT IFNULL(SUM(monto), 0)
            FROM cashflow
            WHERE tipo = 'Egreso'
            AND fecha > ?
            AND fecha < ?
          ) AS egresos
      `;

    db.query(
      sqlMovimientos,
      [
        fechaBase,
        fechaInicio,

        fechaBase,
        fechaInicio,

        fechaBase,
        fechaInicio,

        fechaBase,
        fechaInicio,
      ],
      (err2, results) => {
        if (err2) {
          console.log(err2);

          return res.status(500).json({
            ok: false,
            msg: "Error del servidor",
          });
        }

        const ingresos = Number(results[0].ingresos);

        const egresos = Number(results[0].egresos);

        const saldo = saldoBase + ingresos - egresos;

        res.json({
          ok: true,

          filtro: dias
            ? { dias }
            : {
                desde: date1,
                hasta: date2,
              },

          saldo,
        });
      },
    );
  });
});
module.exports = routerHotel;
