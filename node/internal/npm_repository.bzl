BUILD_FILE = """package(default_visibility = ["//visibility:public"])
exports_files(glob(["*"]))
load("//node:internal/npm_package.bzl", "npm_package")
npm_package(
   name = "{name}",
   version = "{version}",
)
"""

def _npm_repository_impl(ctx):
    package = ctx.attr.package or "npm_" + ctx.name
    print("Installing npm package " + package)
    node = ctx.which("node")
    print("node path: %s" % node)
    result = ctx.execute([node, "install", ctx.attr.package])
    if result.return_code:
        fail("Failed trying to npm install %s: %s" %(ctx.attr.package, result.stderr))
    ctx.file("BUILD", BUILD_FILE.format(
        name = package,
        #version = result.stdout.trim(),
        version = "0.1",
    ))
    print("Installed npm package " + package)

npm_repository = repository_rule(
    implementation = _npm_repository_impl,
    attrs = {
        "node": attr.label(
            default = Label("//node/toolchain:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "package": attr.string(mandatory = False)
    }
)
