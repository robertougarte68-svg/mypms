//23=gerente, 24=housekeeping
const core = require("./utils/core");

//23=gerente, 24=housekeeping

async function main() {
  const res = await core.autenticarUserPin("101", "ESP32_200A21B7B3F8", "0023");

  console.log(res);
}

main();
