const cron = require("node-cron");
const { db, dbPromise } = require("../db"); // conexión a la base de datos (MySQL) con promesas
function _balanceMensual() {
  console.log("Generando balance mensual...");

  const hoy = new Date();

  // Inicio del mes actual
  const inicioMesActual = new Date(hoy.getFullYear(), hoy.getMonth(), 1);

  // Inicio del mes anterior
  const inicioMesAnterior = new Date(hoy.getFullYear(), hoy.getMonth() - 1, 1);

  // Fin del mes anterior
  const finMesAnterior = new Date(
    hoy.getFullYear(),
    hoy.getMonth(),
    0,
    23,
    59,
    59,
  );

  // Obtener ultimo balance guardado
  const sqlBalance = `
    SELECT saldo
    FROM balance_mensual
    ORDER BY fecha_cierre DESC
    LIMIT 1
  `;

  db.query(sqlBalance, (err, balanceRes) => {
    if (err) {
      console.log(err);
      return;
    }

    const saldoAnterior =
      balanceRes.length > 0 ? Number(balanceRes[0].saldo) : 0;

    // SOLO movimientos del ultimo mes
    const sqlMovimientos = `
      SELECT
        (
          (
            SELECT IFNULL(SUM(tarifa), 0)
            FROM estancias
            WHERE date_in BETWEEN ? AND ?
          )

          +

          (
            SELECT IFNULL(SUM(monto), 0)
            FROM cashflow
            WHERE tipo = 'Ingreso'
            AND fecha BETWEEN ? AND ?
          )

          +

          (
            SELECT IFNULL(SUM(anticipo), 0)
            FROM reservas
            WHERE estado = 'CONFIRMADA'
            AND fecha_reserva BETWEEN ? AND ?
          )
        ) AS ingresos,

        (
          SELECT IFNULL(SUM(monto), 0)
          FROM cashflow
          WHERE tipo = 'Egreso'
          AND fecha BETWEEN ? AND ?
        ) AS egresos
    `;

    db.query(
      sqlMovimientos,
      [
        inicioMesAnterior,
        finMesAnterior,

        inicioMesAnterior,
        finMesAnterior,

        inicioMesAnterior,
        finMesAnterior,

        inicioMesAnterior,
        finMesAnterior,
      ],
      (err2, results) => {
        if (err2) {
          console.log(err2);
          return;
        }

        const ingresos = Number(results[0].ingresos);

        const egresos = Number(results[0].egresos);

        const saldo = saldoAnterior + ingresos - egresos;

        const insertSql = `
          INSERT INTO balance_mensual
          (fecha_cierre, ingresos, egresos, saldo)
          VALUES (?, ?, ?, ?)
        `;

        db.query(
          insertSql,
          [finMesAnterior, ingresos, egresos, saldo],
          (err3) => {
            if (err3) {
              console.log(err3);
              return;
            }

            console.log("Balance mensual guardado");
          },
        );
      },
    );
  });
}
_balanceMensual();
cron.schedule("0 0 1 * *", _balanceMensual);
