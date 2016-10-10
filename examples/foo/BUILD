load("//node:rules.bzl", "node_binary", "mocha_test")

node_binary(
    name = "foo",
    main = "foo.js",
    modules = [
        "@npm_react_stack//:modules",
    ],
    deps = [
        "//examples/baz",
    ]
)

mocha_test(
    name = "foo_test",
    main = "foo_test.js",
    modules = ["@npm_underscore//:modules"],
    deps = [
        "//examples/baz",
    ],
    mocha_args = [
        "--reporter=dot"
    ]
)
