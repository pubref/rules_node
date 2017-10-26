var greet = require('src/main/js/greeter');
var assert = require('assert');

describe('#greet()', function() {
  it('should say hello', function() {
    assert.equal('Hello World!', greet('World'));
  });
});
