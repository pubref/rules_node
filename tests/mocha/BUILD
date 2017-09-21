package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_module", "mocha_test")

mocha_test(
    name = "test",
    main = "test.js",
)

# Can one test a bazel test?  I'm getting 'fork: Resource temporarily unavailable' when I try to run this.
# sh_test(
#     name = "test_test",
#     size = "small",
#     srcs = ["test.sh"],
#     data = [":test"],
# )
