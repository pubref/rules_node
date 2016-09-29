var process = require("process");
var bar = require("../bar/bar.js");
var glob = require("glob");
var baz = require("workspace-examples-baz");


console.log('****************************************************************');
//console.log('Hello, ' + bar());
console.log('Hello, ' + bar() + " and " + baz());
console.log('****************************************************************');
console.log("filename:", __filename);
console.log("dirname:", __dirname);
console.log("process.versions:", process.versions);
console.log("process.argv ", process.argv);
console.log("require paths:", module.paths);
//console.log("env:", process.env);
