import { Animal } from "zoo/animal";

const animal = new Animal("Bear");

console.log(`animal "${animal.name}" has taxonomy ${animal.getKingdom()}/${animal.getPhylum()}`);
