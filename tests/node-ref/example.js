const ref = require("ref");

const buf = new Buffer(4)

buf.writeInt32LE(12345, 0)
buf.type = ref.types.int

console.log(buf.deref())  // ← 12345

