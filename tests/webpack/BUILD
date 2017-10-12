package(default_visibility = ["//visibility:public"])

sh_test(
    name = "webpack_bin_test",
    size = "small",
    srcs = ["webpack_bin_test.sh"],
    data = ["@yarn_modules//:webpack_bin"],
)

genrule(
    name = "webpack_compile",
    # Not found (only webpack_bin.runfiles here).  Why?
    #tools = ["@yarn_modules//:webpack_bin"],
    tools = ["@yarn_modules//:webpack_bin"],
    srcs = [
        "input.js",
    ],
    outs = [
        "bundle.js",
    ],
    cmd = " ".join([
        "pwd && ls -al ./bazel-out/host/bin/external/yarn_modules/webpack_bin.runfiles/__main__/external/yarn_modules/ &&",
        "./bazel-out/host/bin/external/yarn_modules/webpack_bin.runfiles/__main__/external/yarn_modules/webpack_bin",
        #"$(location @yarn_modules//:webpack_bin)",
        "--output-filename=bundle.js",
        #"$(SRCS)",
        "input.js",
    ]),
)
