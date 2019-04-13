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
        # Note: it is critical to use 'locations' and not 'location'
        # here, presumably as the tool dependency includes many files
        "$(locations @yarn_modules//:webpack_bin)",
        "$(SRCS)",
        "$@",
    ]),
)


sh_test(
    name = "webpack_compile_test",
    size = "small",
    srcs = ["webpack_compile_test.sh"],
    data = [":webpack_compile"], # data dependency on the bundle.js
                                 # file output implicitly invokes
                                 # webback to generate it
)
