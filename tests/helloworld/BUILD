package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_module")

node_binary(
    name = "helloworld",
    main = "helloworld.js",
)

sh_test(
    name = "helloworld_test",
    size = "small",
    srcs = ["helloworld_test.sh"],
    data = [":helloworld"],
)
