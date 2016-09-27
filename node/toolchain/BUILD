package(default_visibility = ["//visibility:public"])

config_setting(
    name = "darwin",
    values = {"host_cpu": "darwin"},
)

config_setting(
    name = "k8",
    values = {"host_cpu": "k8"},
)

alias(
    name = "node_tool",
    actual = select({
        ":k8": "@nodejs_linux_amd64//:node_tool",
        ":darwin": "@nodejs_darwin_amd64//:node_tool",
    }),
    visibility = ["//visibility:public"],
)

alias(
    name = "npm_tool",
    actual = select({
        ":k8": "@nodejs_linux_amd64//:npm_tool",
        ":darwin": "@nodejs_darwin_amd64//:npm_tool",
    }),
    visibility = ["//visibility:public"],
)

# alias(
#     name = "nodejs",
#     actual = select({
#         ":k8": "@nodejs_linux_amd64//:nodejs",
#         ":darwin": "@nodejs_darwin_amd64//:nodejs",
#     }),
#     visibility = ["//visibility:public"],
# )
