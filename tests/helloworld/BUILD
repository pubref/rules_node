package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_module", "node_test")

node_module(
    name = "helloworld",
    main = "helloworld.js",
)

node_binary(
    name = "helloworld_bin",
    entrypoint = ":helloworld",
)

sh_test(
    name = "helloworld_test",
    size = "small",
    srcs = ["helloworld_test.sh"],
    data = [":helloworld_bin"],
)

node_test(
    name = "require_test",
    size = "small",
    main = "require_test.js",
    deps = [":helloworld"],
)

