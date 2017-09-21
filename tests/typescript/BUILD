package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_module")

load("//:ts_module.bzl", "ts_module")

# Demonstration consuming compiled output from traditional javascript.
node_binary(
    name = "trad_report",
    main = "trad_report.js",
    deps = [
        ":zoo",
        "@yarn_modules//:typescript",
    ]
)

# shell script that runs 'node node_modules/report', which has a
# compiled index.js file, so this gets loaded by the intrinsic node
# module resolution algorithm.
node_binary(
    name = "ts_report",
    entrypoint = ":report",
)

# Build node_modules/report/{package.json,index.js,index.d.ts}
# and a correspoding node_modules tree for the compilation with
# node_modules/taxonomy and node_modules/zoo in it.
ts_module(
    name = "report",
    srcs = ["index.ts"],
    deps = [
        ":zoo",
    ]
)

# Build node_modules/zoo/{package.json,animal.js,animal.d.ts}
# and a correspoding node_modules tree for the compilation with
# node_modules/taxonomy in it.
ts_module(
    name = "zoo",
    srcs = ["animal.ts"],
    deps = [
        ":taxonomy",
    ]
)

# Build node_modules/taxonomy/{package.json,phyla.js,phyla.d.ts}
ts_module(
    name = "taxonomy",
    srcs = ["phyla.ts"],
)

# Run the test
sh_test(
    name = "typescript_test",
    size = "small",
    srcs = ["typescript_test.sh"],
    data = [":ts_report"],
)


# Note to self: genrule way to call typescript (too simple for real usage)
# genrule(
#     name = "tsc",
#     srcs = ["hello.ts"],
#     outs = ["hello.js"],
#     cmd = "external/yarn_modules/node_modules/.bin/tsc --outDir $(@D) $(SRCS)",
#     tools = ["@yarn_modules//:tsc"],
# )
