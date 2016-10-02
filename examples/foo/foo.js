// stdlib dependency
var process = require("process");
// npm_repository module dependency
var glob = require("glob");
// local module dependency
var baz = require("examples-baz");
// relative file dependency
var bar = require("../bar/bar.js");

console.log('****************************************************************');
console.log('Hello, Foo and ' + bar() + " and " + baz());
console.log('****************************************************************');

// console.log("filename:", __filename);
// console.log("dirname:", __dirname);
// console.log("process.versions:", process.versions);
// console.log("process.argv ", process.argv);
// console.log("require paths:", module.paths);
// console.log("env:", process.env);
