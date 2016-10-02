BUILD_FILE = """package(default_visibility = ["//visibility:public"])
filegroup(
  name = "modules",
  srcs = ["{node_modules_path}"],
)
#exports_files(["node_modules"])
"""

def _execute(ctx, cmds):
    result = ctx.execute(cmds)
    if result.return_code:
        fail(" ".join(cmds) + "failed: %s" %(result.stderr))
    return result.stdout


def _dnode_modules(ctx, node_modules_path):
    script_path = ctx.path(ctx.attr.dnode_modules)
    python = ctx.which("python")
    if not python:
        fail("python not found (is it present in your PATH?)")

    cmd = [
        python,
        script_path,
        "--path", "%s/%s" % (ctx.path(""), node_modules_path),
        #"--verbose", "--verbose",
    ]

    if ctx.attr.exclude_package_json_keys:
        cmd.append("--exclude")
        cmd += ctx.attr.exclude_package_json_keys

    output = _execute(ctx, cmd)
    print(output)


def _check_sha256(ctx, node_modules_path):

    dar_path = ctx.path(ctx.attr.dar)
    tarfile = "node_modules.tar"

    python = ctx.which("python")
    if not python:
        fail("python not found (is it present in your PATH?)")

    sha256 = None
    os = ctx.os.name
    if os == 'linux':
        sha256sum = ctx.which("sha256sum")
        if not sha256sum:
            fail("sha256sum not found (is it present in your PATH?)")
        sha256 = [sha256sum]
    elif os == 'mac os x':
        shasum = ctx.which("shasum")
        if not shasum:
            fail("shasum not found (is it present in your PATH?)")
        sha256 = [shasum, "-a256"]
    else:
        fail("Unsupported operating system: " + os)

    _execute(ctx, [
        python,
        dar_path,
        "--output", tarfile,
        "--file", "%s=node_modules" % node_modules_path,
    ])

    expected = ctx.attr.sha256
    actual = _execute(ctx, sha256 + [tarfile]).split(" ")[0]
    if actual != expected:
        fail(ctx.name + " node_modules archive sha256 [%s] does not match expected value [%s]" %(actual, expected))


def _npm_repository_impl(ctx):
    node = ctx.path(ctx.attr.node)
    npm = ctx.path(ctx.attr.npm)
    node_modules_path = ctx.attr.node_modules_path

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
        "--prefix", ctx.path(""),
        "--global"
    ]

    if ctx.attr.registry:
        cmd += ["--registry", ctx.attr.registry]

    cmd += modules

    _execute(ctx, cmd)

    if ctx.attr.sha256:
        _dnode_modules(ctx, node_modules_path)
        _check_sha256(ctx, node_modules_path)

    if str(node_modules_path) != "node_modules":
        _execute(ctx, ["ln", "-s", node_modules_path, "node_modules"])

    ctx.file("BUILD", BUILD_FILE.format(
        node_modules_path = node_modules_path,
    ))

npm_repository = repository_rule(
    implementation = _npm_repository_impl,
    attrs = {
        "node": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:bin/node"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "npm": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:bin/npm"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "dar": attr.label(
            default = Label("//node:tools/dar.py"),
            single_file = True,
            allow_files = True,
            cfg = "host",
        ),
        "dnode_modules": attr.label(
            default = Label("//node:tools/dnode_modules.py"),
            single_file = True,
            allow_files = True,
            cfg = "host",
        ),
        "node_modules_path": attr.string(
            default = "lib/node_modules",
        ),
        "registry": attr.string(),
        "sha256": attr.string(),
        "exclude_package_json_keys": attr.string_list(
            # Not all these are proven to be non-deterministic, but
            # looking through sample data they look somewhat
            # suspicious.  Does not appear to be harmful to remove
            # them (but that's why its configurable).
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
        "deps": attr.string_dict(mandatory = True),
    }
)
