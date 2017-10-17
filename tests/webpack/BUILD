package(default_visibility = ["//visibility:public"])

sh_test(
    name = "webpack_bin_test",
    size = "small",
    srcs = ["webpack_bin_test.sh"],
    data = ["@yarn_modules//:webpack_bin"],
)

genrule(
    name = "webpack_compile",
    tools = [
        "@yarn_modules//:webpack_bin",
        #"webpack.config.js",
    ],
    srcs = [
        "input.js",
    ],
    outs = [
        "bundle.js",
    ],
    cmd = " ".join([
        #"pwd && ls -al ./bazel-out/host/bin/external/yarn_modules/webpack_bin.runfiles/__main__/external/yarn_modules/ &&",
        #"pwd && cat ./external/bazel_tools/tools/genrule/genrule-setup.sh &&",
        #"./bazel-out/host/bin/external/yarn_modules/webpack_bin.runfiles/__main__/external/yarn_modules/webpack_bin",
        "$(locations @yarn_modules//:webpack_bin)",
        #"--help",
        #"--config=$(location webpack.config.js)",
        #"--output-filename=bundle.js",
        "$(SRCS)",
        "$@",
    ]),
)

# In a genrule context, $(location //:my_node_binary_rule) does not
# work as expected.  The executable script
# `bazel-out/host/bin/my_node_binary` does not exist in the bazel
# sandbox, but rather
# `bazel-out/host/bin/my_node_binary.runfiles/__main__/ny_node_binary'
# is the only file exposed in the sandbox.

# If I take out the fles provider from the node_binary rule, it forced
# bazel to complain about $(location ...), insisting on $(locations
# ...)  instead!

genrule(
    name = "compile",
    # Not found (only webpack_bin.runfiles here).  Why?
    #tools = ["@yarn_modules//:webpack_bin"],
    tools = [
        "//src:compiler",
    ],
    srcs = [
        #"//src:compiler",
        "input.js",
    ],
    outs = [
        "out.js",
    ],
    local = 0,
    cmd = " ".join([
        # /bin/bash: bazel-out/host/bin/src/compiler: No such file or directory
        #"find . &&",
        "$(locations //src:compiler)",
        "$(SRCS)",
        ">",
        "$@",
    ]),
)
