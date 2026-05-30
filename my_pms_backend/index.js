require("./utils/db");
require("./mqtt/hotel_mqtt");
require("./utils/serverWS");
const express = require("express");

const app = express();
//routers
const routerClients = require("./endpoints/router_clientes");
const routerRooms = require("./endpoints/router_rooms");
const routerUsers = require("./endpoints/router_users");
const routerHotel = require("./endpoints/router_hotel");

app.use("/api/clientes", routerClients);
app.use("/api/rooms", routerRooms);
app.use("/api/users", routerUsers);
app.use("/api/hotel", routerHotel);

app.use("/uploads", express.static("uploads"));

const PUERTO = 3000;

app.listen(PUERTO, () => {
  console.log(`servidor backend en puerto ${PUERTO}`);
});
