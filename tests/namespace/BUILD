package(default_visibility = ["//visibility:public"])

load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "question",
    main = "question.js",
    deps = [
        "//src/javascript/answer",
    ],
)

sh_test(
    name = "question_test",
    size = "small",
    srcs = ["question_test.sh"],
    data = [":question"],
)
