package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_module", "node_modules", "mocha_test")

mocha_test(
    name = "test",
    main = "test.js",
    args = [
    ],
    deps = ["//src/main/js:greeter"],
)
