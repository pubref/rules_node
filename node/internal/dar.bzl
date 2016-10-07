load("//node:internal/node_utils.bzl", "execute")

dar_attrs = {
    "dar": attr.label(
        default = Label("//node:tools/dar.py"),
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
    "dar_filename": attr.string(
        default = "node_modules",
    ),
    "dar_root": attr.string(
        default = "lib/node_modules",
    ),
}

def dar_execute(ctx, dar_root=None):
    python = ctx.which("python")
    if not python:
        fail("python not found (is it present in your PATH?)")

    dar_filename = ctx.attr.dar_filename
    dar_file = "%s.tar" % ctx.attr.dar_filename
    dar_py = ctx.path(ctx.attr.dar)
    if not dar_root:
        dar_root=ctx.attr.dar_root
    tarfile = "%s.tar" % dar_filename

    cmd = [
        python,
        dar_py,
        "--output", tarfile,
        "--file", "%s=%s" % (dar_filename, dar_root),
    ]

    print("dar: %s" % cmd)
    return execute(ctx, cmd)
