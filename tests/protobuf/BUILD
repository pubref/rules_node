package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "mocha_test", "node_proto_module")

node_proto_module(
    name = "proto-test-module",
    srcs = ["test.proto"]
)

mocha_test(
    name = "proto-test",
    srcs = ["test.js"],
    deps = [":proto-test-module"],
    main = "test.js"
)
