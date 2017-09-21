const Animal = require("zoo/animal").Animal;

const animal = new Animal("Bear");
console.log(`animal "${animal.name}" has taxonomy ${animal.getKingdom()}/${animal.getPhylum()}`);
