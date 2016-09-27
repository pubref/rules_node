load("//node:rules.bzl", "node_binary", "npm_library")

npm_library(
    name = "glob",
)

npm_library(
    name = "react-stack",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
)

node_binary(
    name = "foo",
    main_script = "foo.js",
    npm_deps = ["glob", "react-stack"],
)
