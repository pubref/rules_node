'use strict';

const assert = require('assert');

const testproto = require('proto-test-module/test_pb');

describe('Protobuf', function () {

  var msg;
  var code;

  var bytes;

  before(function () {
    msg = 'TESTING';
    code = 1000;
  });

  it('should serialize successfully', function () {
    var msg1 = new testproto.TestMessage();
    msg1.setMsg(msg);
    msg1.setCode(code);

    bytes = msg1.serializeBinary();
  });

  it('should deserialize successfully', function () {
    var msg2 = testproto.TestMessage.deserializeBinary(bytes);
    assert.equal(msg, msg2.getMsg());
    assert.equal(code, msg2.getCode());
  });
});
