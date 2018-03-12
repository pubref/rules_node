package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary")
load("@bazel_tools//tools/build_rules:test_rules.bzl", "file_test")

#
# Rollup bundling
#
node_binary(
    name = "rollup_with_plugins",
    entrypoint = "@yarn_modules//:rollup",
    executable = "rollup",
    deps = ["@yarn_modules//:_all_"],
)

genrule(
    name = "genrule_target",
    tools = [
        ":rollup_with_plugins",
        ":rollup.config.js",
    ],
    srcs = [
        "es6_src.js",
    ],
    outs = [
        "genrule_target.js",
    ],
    executable = 1,
    cmd = " ".join([
        "$(location :rollup_with_plugins)",
        "-c $(location :rollup.config.js)",
        "-i $(location :es6_src.js)",
        "-f cjs",
        "-o $(location :genrule_target.js)"
    ])
)


file_test(
    name = "test",
    size = "small",
    file = ":genrule_target",
    content = """'use strict';

function es6_src () { return "if I build, then all's good"; }

module.exports = es6_src;
"""
)
