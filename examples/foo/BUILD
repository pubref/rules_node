load("//node:rules.bzl", "node_binary")

node_binary(
    name = "foo",
    main = "foo.js",
    modules = [
        "@npm_react_stack//:modules",
        "@npm_glob//:modules",
    ],
    deps = [
        "//examples/baz",
    ]
)
