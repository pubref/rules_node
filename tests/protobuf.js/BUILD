package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "app",
    main = "app.js",
    deps = [
        "@yarn_modules//:protobuf.js",
    ],
)

sh_test(
    name = "protobuf_test",
    size = "small",
    srcs = ["protobuf_test.sh"],
    data = [":app"],
)
