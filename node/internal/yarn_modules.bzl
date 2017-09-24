def execute(ctx, cmds, **kwargs):
    result = ctx.execute(cmds, **kwargs)
    if result.return_code:
        fail(" ".join(cmds) + "failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (result.stdout, result.stderr))
    return result

def _create_package_json_content(ctx):
    content = {
        "name": ctx.name,
        "version": "1.0.0",
    }
    dependencies = {}
    for name, version in ctx.attr.deps.items():
        dependencies[name] = version
    content["dependencies"] = struct(**dependencies)
    return struct(**content)


def _download_and_extract_module(ctx, entry):
    name = entry["name"]
    url = entry["url"]
    print("downloading %s to node_modules/%s, stripping '%s'" % (url, name, 'package'))
    ctx.download_and_extract(
        url,
        output = "node_modules/" + name,
        stripPrefix = "package",
    )


def _yarn_modules_impl(ctx):

    # Preconditions
    if not (ctx.attr.package_json or ctx.attr.deps):
        fail("You must provide either a package.json file OR specify deps (got none!)")
    if ctx.attr.package_json and ctx.attr.deps:
        fail("You must specify a package.json file OR deps (not both!)")

    # Gather required resources
    node_label = ctx.attr._node
    if ctx.os.name.lower().find("windows") != -1:
        node_label = ctx.attr._node_exe
    node = ctx.path(node_label)

    parse_yarn_lock_js = ctx.path(ctx.attr._parse_yarn_lock_js)
    yarn_js = ctx.path(ctx.attr._yarn_js)

    # Copy over or create the package.json file
    if ctx.attr.package_json:
        package_json_file = ctx.path(ctx.attr.package_json)
        execute(ctx, ["cp", package_json_file, "package.json"])
    else:
        ctx.file("package.json", _create_package_json_content(ctx).to_json())

    # Copy the parse_yarn_lock script and yarn.js over here.
    execute(ctx, ["cp", parse_yarn_lock_js, "parse_yarn_lock.js"])
    execute(ctx, ["cp", yarn_js, "yarn.js"])

    # Build node_modules via 'yarn install'
    execute(ctx, [node, yarn_js, "install"], quiet = True)

    # Build a node_modules with this single dependency
    ctx.download_and_extract(
        url = "https://registry.yarnpkg.com/@yarnpkg/lockfile/-/lockfile-1.0.0.tgz",
        output = "node_modules/@yarnpkg/lockfile",
        sha256 = "472add7ad141c75811f93dca421e2b7456045504afacec814b0565f092156250",
        stripPrefix = "package",
    )

    # Run the script and save the stdout to our BUILD file(s)
    result = execute(ctx, [node, "parse_yarn_lock.js"], quiet = True)
    ctx.file("BUILD", result.stdout)
    ctx.file("BUILD.bazel", result.stdout)


yarn_modules = repository_rule(
    implementation = _yarn_modules_impl,
    attrs = {
        "_node": attr.label(
            # FIXME(pcj): This is going to invalid for windows
            default = Label("@node//:bin/node"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "_node_exe": attr.label(
            default = Label("@node//:node.exe"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "_parse_yarn_lock_js": attr.label(
            default = Label("//node:internal/parse_yarn_lock.js"),
            single_file = True,
        ),
        "_yarn_js": attr.label(
            default = Label("@yarn//:bin/yarn.js"),
            single_file = True,
        ),
        "package_json": attr.label(
            mandatory = False,
            allow_files = FileType(["package.json"]),
        ),
        "deps": attr.string_dict(mandatory = False),
    }
)
