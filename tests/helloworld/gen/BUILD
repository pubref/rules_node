
load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "node_test")

# A binary rule that emits a helloworld program
node_binary(
    name = "compiler",
    main = "compiler.js",
    deps = [],
    visibility = ["//visibility:public"],
)

# A genrule that invokes the compiler, generating the program file
genrule(
    name = "compile",
    tools = [":compiler"],
    srcs = [
        "input.js",
    ],
    outs = [
        "helloworld.js",
    ],
    local = 0,
    cmd = " ".join([
        "$(locations :compiler)",
        "$(SRCS)",
        ">",
        "$@",
    ]),
)

# If the test passes, we probably emitted hello world
node_test(
    name = "helloworld_test",
    size = "small",
    main = "helloworld.js",
    visibility = ["//visibility:public"],
)

# But let's make sure...
sh_test(
    name = "generated_helloworld_test",
    size = "small",
    srcs = ["generated_helloworld_test.sh"],
    data = [":helloworld.js"],
)
