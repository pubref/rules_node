package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "example",
    main = "example.js",
    deps = [
        "@yarn_modules//:_all_",
    ],
)

sh_test(
    name = "example_test",
    size = "small",
    srcs = ["example_test.sh"],
    data = [":example"],
)

