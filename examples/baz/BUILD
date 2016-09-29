package(default_visibility = ["//visibility:public"])

load("//node:rules.bzl", "node_binary", "npm_library", "node_library")

npm_library(name = "glob")

node_library(
    name = "baz",
    main_script = "index.js",
    srcs = [
        "qux.js"
    ],
    npm_deps = ["glob"],
    use_prefix = False,
)
