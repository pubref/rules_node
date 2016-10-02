package(default_visibility = ["//visibility:public"])

load("//node:rules.bzl", "node_binary", "node_library")

node_library(
    name = "baz",
    main = "index.js",
    srcs = [
        "qux.js"
    ],
    modules = ["@npm_glob//:modules"],
)
