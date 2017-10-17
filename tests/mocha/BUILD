package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_module", "node_modules", "mocha_test")

mocha_test(
    name = "test",
    main = "test.js",
)

node_modules(
    name = "mocha_deps",
    deps = [
        "@mocha_modules//:_all_",
    ]
)
