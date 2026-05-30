const express = require("express");
const { db, dbPromise } = require("../utils/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const routerUsers = express.Router();
routerUsers.use(express.json());
/*
Intermediario. Convierte la informacion json en objetos y viceversa. Ahorra ese paso.
Se ejecuta antes y despues de la solicitud
*/

//Crear nuevo usuario
routerUsers.post("/registerUser", async (req, res) => {
  try {
    const { email, user, password } = req.body;
    const passHash = await bcrypt.hash(password, 10);
    const sql = "INSERT INTO users (email,user,passHash) VALUES (?,?,?)";
    db.query(sql, [email, user, passHash], (error, result) => {
      if (error) {
        if (error.code === "ER_DUP_ENTRY") {
          if (error.message.includes("email")) {
            return res.status(400).json({ message: "email" });
          }

          if (error.message.includes("user")) {
            return res.status(400).json({ message: "user" });
          }
          return res.status(400).json({ message: "other" });
        }
        console.log(error);
        return res.status(500).json({ message: "error db" });
      }
      res.status(201).json({ message: "User added", id: result.insertId });
    });
  } catch (err) {
    res.status(500).json({ error: "error de servidor no especificado" });
  }
});

routerUsers.patch("/:username", (req, res) => {
  const { username } = req.params;
  const campos = { ...req.body };

  try {
    // Si viene "rol", obtener su id desde la tabla roles
    if (campos.rol) {
      const sqlRol = `SELECT id FROM roles WHERE rol = ?`;

      db.query(sqlRol, [campos.rol], (err, rolResults) => {
        if (err) {
          return res.status(500).json({ error: `${err}` });
        }

        if (rolResults.length === 0) {
          return res.status(404).json({ error: "Rol no encontrado" });
        }

        // Reemplazar rol por rol_id
        campos.id_rol = rolResults[0].id;
        delete campos.rol;

        actualizarUsuario(campos);
      });
    } else {
      actualizarUsuario(campos);
    }

    function actualizarUsuario(data) {
      const keys = Object.keys(data);
      const values = Object.values(data);

      if (keys.length === 0) {
        return res.status(400).json({ error: "No hay campos para actualizar" });
      }

      const setClause = keys.map((key) => `${key} = ?`).join(", ");
      const sql = `UPDATE users SET ${setClause} WHERE user = ?`;

      db.query(sql, [...values, username], (err, results) => {
        if (err) {
          res.status(500).json({ error: `${err}` });
        } else {
          res.status(200).json({
            message: "Actualizado correctamente",
          });
        }
      });
    }
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "Error al actualizar" });
  }
});

// LOGIN
routerUsers.post("/login", async (req, res) => {
  try {
    const SECRET_KEY = process.env.JWT_SECRET || "keydebeto";

    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        //bad request
        message: "faltan_datos",
      });
    }

    const sql = `
      SELECT 
        u.id,
        u.email,
        u.user,
        u.passHash,
        u.hotel_id,
        r.id AS rol_id,
        r.rol AS rol_nombre
      FROM users u
      LEFT JOIN roles r ON u.id_rol = r.id
      WHERE u.email = ?
      LIMIT 1
    `;

    db.query(sql, [email], async (err, result) => {
      if (err) {
        console.error(err);
        return res.status(500).json({
          message: "error_servidor_db",
        });
      }

      if (result.length === 0) {
        return res.status(404).json({
          message: "noExiste",
        });
      }

      const userData = result[0];

      const isValid = await bcrypt.compare(password, userData.passHash);

      if (!isValid) {
        return res.status(401).json({
          message: "contrasena",
        });
      }

      // OBTENER PERMISOS DEL ROL
      const sqlPermisos = `
        SELECT p.id, p.permiso
        FROM rol_permiso rp
        INNER JOIN permisos p 
          ON rp.id_permiso = p.id
        WHERE rp.id_rol = ?
      `;

      db.query(
        sqlPermisos,
        [userData.rol_id],
        (errPermisos, permisosResult) => {
          if (errPermisos) {
            console.error(errPermisos);
            return res.status(500).json({
              message: "error_permisos",
            });
          }

          // permisos en array string
          const permisos = permisosResult.map((p) => p.permiso);

          // JWT
          const token = jwt.sign(
            {
              userId: String(userData.id),
              email: String(userData.email),
              user: String(userData.user),
              rol: String(userData.rol_nombre),
              rol_id: String(userData.rol_id),
              hotel_id: String(userData.hotel_id),
              permisos,
            },
            SECRET_KEY,
            { expiresIn: "1h" },
          );

          let datafinal = {
            id: userData.id,
            email: String(userData.email),
            user: String(userData.user),
            rol: userData.rol_nombre,
            hotel_id: userData.hotel_id,
            token,
            permisos: permisos.map((p) => String(p)),
          };
          console.log(datafinal);
          return res.status(200).json(datafinal);
        },
      );
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "error_general",
    });
  }
});

routerUsers.get("/:userId", (req, res) => {
  const { userId } = req.params;
  const sql = "SELECT * FROM users WHERE id = ?";
  db.query(sql, [userId], (err, result) => {
    if (err) {
      res.status(500).json({ error: `${err}` });
    } else {
      res.status(200).json(result);
    }
  });
});

module.exports = routerUsers;
