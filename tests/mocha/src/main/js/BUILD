
package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_module", "mocha_test")

node_module(
    name = "greeter",
    main = "greeter.js",
)

mocha_test(
    name = "greeter_test",
    main = "greeter_test.js",
    deps = [":greeter"],
)
