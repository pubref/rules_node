package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "server",
    main = "server.js",
    deps = [
        "@yarn_modules//:_all_",
    ]
)

sh_test(
    name = "server_test",
    size = "small",
    srcs = ["server_test.sh"],
    data = [":server"],
)
