var qux = require("./qux.js");

module.exports = function() {
  return "Baz!! (and " + qux() + ")";
};
