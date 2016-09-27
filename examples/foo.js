var process = require("process");
var bar = require("./bar.js");
var glob = require("glob");

console.log('Hello, ' + bar());
console.log("filename:", __filename);
console.log("dirname:", __dirname);
console.log("process.versions:", process.versions);
console.log("process.argv ", process.argv);
console.log("require paths:", module.paths);
console.log("env:", process.env);
