const mysql = require("mysql2");
const mysqlPromise = require("mysql2/promise");

const db = mysql.createConnection({
  host: "localhost",
  user: "oci_server",
  password: "server_pass",
  database: "mypms",
  port: 3306,
  dateStrings: true,
});

const dbPromise = mysqlPromise.createPool({
  host: "localhost",
  user: "oci_server",
  password: "server_pass",
  database: "mypms",
  port: 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true,
});

db.connect((err) => {
  if (err) throw err;
  console.log("conectado a la db");
});

module.exports = { db, dbPromise };
