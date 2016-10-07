load("//node:internal/dar.bzl", "dar_attrs", "dar_execute")
load("//node:internal/dson.bzl", "dson_attrs", "dson_execute")
load("//node:internal/sha256.bzl", "sha256_attrs", "sha256_execute")
load("//node:internal/node_utils.bzl", "execute", "node_attrs")

BUILD_FILE = """package(default_visibility = ["//visibility:public"])
filegroup(
  name = "modules",
  srcs = ["{modules_path}"],
)
exports_files(["{modules_path}"])
exports_files(glob(["bin/*"]))
"""

_npm_repository_attrs = node_attrs + dar_attrs + dson_attrs + sha256_attrs + {
    "npm": attr.label(
        default = Label("@org_pubref_rules_node_toolchain//:bin/npm"),
        single_file = True,
        allow_files = True,
        executable = True,
        cfg = "host",
    ),
    "registry": attr.string(),
    "deps": attr.string_dict(mandatory = True),
}

def _npm_repository_impl(ctx):
    node = ctx.path(ctx.attr.node)
    nodedir = node.dirname.dirname
    npm = ctx.path(ctx.attr.npm)
    modules_path = ctx.attr.dar_root

    modules = []
    for k, v in ctx.attr.deps.items():
        if v:
            modules.append("%s@%s" % (k, v))
        else:
            modules.append(k)

    cmd = [
        node,
        npm,
        "install",
        #"--loglevel", "silly", # info
        "--prefix", ctx.path(""),
        "--nodedir=%s" % nodedir,
        "--global"
    ]

    if ctx.attr.registry:
        cmd += ["--registry", ctx.attr.registry]

    cmd += modules

    output = execute(ctx, cmd).stdout
    #print("npm install output: %s" % output)

    if str(modules_path) != "node_modules":
        execute(ctx, ["ln", "-s", modules_path, "node_modules"])

    if ctx.attr.sha256:
        dson_execute(ctx, dson_path = "node_modules")
        dar_execute(ctx, dar_root = "node_modules")
        sha256_execute(ctx, "node_modules.tar")
    else:
        print("no sha, skipping determistic steps...")

    ctx.file("BUILD", BUILD_FILE.format(
        modules_path = modules_path,
    ))

npm_repository = repository_rule(
    implementation = _npm_repository_impl,
    attrs = _npm_repository_attrs,
)
