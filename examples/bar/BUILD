load("//node:rules.bzl", "node_binary", "npm_library", "node_library")

npm_library(
    name = "glob",
)

node_binary(
    name = "bar",
    main_script = "bar.js",
    npm_deps = ["glob"],
)
