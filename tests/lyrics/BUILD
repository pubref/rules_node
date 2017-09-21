package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "lyrics",
    main = "lyrics.js",
    deps = [
        "@yarn_modules//:underscore",
    ]
)

sh_test(
    name = "lyrics_test",
    size = "small",
    srcs = ["lyrics_test.sh"],
    data = [":lyrics"],
)
