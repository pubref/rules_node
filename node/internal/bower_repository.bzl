load("//node:internal/dar.bzl", "dar_attrs", "dar_execute")
load("//node:internal/dson.bzl", "dson_attrs", "dson_execute")
load("//node:internal/sha256.bzl", "sha256_attrs", "sha256_execute")
load("//node:internal/node_utils.bzl", "execute", "node_attrs")

BUILD_FILE = """package(default_visibility = ["//visibility:public"])
filegroup(
  name = "components",
  srcs = glob(["{components_path}/**/*"]),
)
exports_files(["{components_path}"])
"""


_bower_repository_attrs = node_attrs + dar_attrs + dson_attrs + sha256_attrs + {
    "bower": attr.label(
        default = Label("@npm_bower//:node_modules/bower/bin/bower"),
        single_file = True,
        allow_files = True,
        executable = True,
        cfg = "host",
    ),

    # dar_attrs redefines
    "dar_filename": attr.string(
        default = "bower_components",
    ),
    "dar_root": attr.string(
        default = "bower_components",
    ),

    # dson_attrs redefines
    "dson_path": attr.string(
        default = "bower_components",
    ),
    "dson_filenames": attr.string_list(
        default = ["bower.json", ".bower.json"],
    ),
    "dson_exclude_keys": attr.string_list(
        default = [
            "__dummy_entry_to_prevent_empty_list__",
        ],
    ),

    "registry": attr.string(),
    "deps": attr.string_dict(mandatory = True),
}

def _bower_repository_impl(ctx):
    node = ctx.path(ctx.attr.node)
    nodedir = node.dirname.dirname
    bower = ctx.path(ctx.attr.bower)

    bower_json = ['{']
    bower_json.append('"name": "%s"' % ctx.name)
    if ctx.attr.registry:
        bower_json.append('"registry": "%s"' % ctx.attr.registry)
    bower_json.append('}')
    ctx.file("bower.json", "\n".join(bower_json))

    cmd = [
        node,
        bower,
        "install",
    ]

    modules = []
    for k, v in ctx.attr.deps.items():
        if v:
            modules.append("%s#%s" % (k, v))
        else:
            modules.append(k)
    cmd += modules

    output = execute(ctx, cmd).stdout

    if ctx.attr.sha256:
        dson_execute(ctx, dson_path = "bower_components")
        dar_execute(ctx, dar_root = "bower_components")
        sha256_execute(ctx, "bower_components.tar")

    ctx.file("BUILD", BUILD_FILE.format(
        components_path = "bower_components",
    ))

bower_repository = repository_rule(
    implementation = _bower_repository_impl,
    attrs = _bower_repository_attrs,
)
