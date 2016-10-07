load("//node:internal/node_utils.bzl", "execute")

dson_attrs = {
    "dson": attr.label(
        default = Label("//node:tools/dson.py"),
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
    "dson_path": attr.string(
        default = "lib/node_modules",
    ),
    "dson_filenames": attr.string_list(
        default = ["package.json"],
    ),
    "dson_exclude_keys": attr.string_list(
        default = [
            "_args",
            "_from",
            "_inCache",
            "_installable",
            "_nodeVersion",
            "_npmOperationalInternal",
            "_npmUser",
            "_npmVersion",
            "_phantomChildren",
            "_resolved",
            "_requested",
            "_requiredBy",
            "_where",
        ],
    ),
}

def dson_execute(ctx, dson_path=None):
    python = ctx.which("python")
    if not python:
        fail("python not found (is it present in your PATH?)")
    dson_py = ctx.path(ctx.attr.dson)
    if not dson_path:
        dson_path = ctx.attr.dson_path
    cmd = [
        python,
        dson_py,
        "--path", "%s/%s" % (ctx.path(""), dson_path),
        "--verbose", "--verbose",
    ]

    for filename in ctx.attr.dson_filenames:
        cmd += ["--filename", filename]

    for key in ctx.attr.dson_exclude_keys:
        cmd += ["--exclude", key]

    #print("dson: %s" % cmd)

    result = execute(ctx, cmd)

    #print("dson-out: %s" % result.stdout)

    return result
