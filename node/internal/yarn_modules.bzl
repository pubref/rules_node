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


    # Grab the @yarnpkg/lockfile dependency
    ctx.download_and_extract(
        url = "https://registry.yarnpkg.com/@yarnpkg/lockfile/-/lockfile-1.0.0.tgz",
        output = "internal/node_modules/@yarnpkg/lockfile",
        sha256 = "472add7ad141c75811f93dca421e2b7456045504afacec814b0565f092156250",
        stripPrefix = "package",
    )
    
    # Copy over or create the package.json file
    if ctx.attr.package_json:
        package_json_file = ctx.path(ctx.attr.package_json)
        execute(ctx, ["cp", package_json_file, "package.json"])
    else:
        ctx.file("package.json", _create_package_json_content(ctx).to_json())

        
    # Copy the parse_yarn_lock script and yarn.js over here.
    execute(ctx, ["cp", parse_yarn_lock_js, "internal/parse_yarn_lock.js"])
    execute(ctx, ["cp", yarn_js, "yarn.js"])

    install_path = [node.dirname]
    for tool in ctx.attr.install_tools:
        tool_path = ctx.which(tool)
        if not tool_path:
            fail("Required install tool '%s' is not in the PATH" % tool, "install_tools")
        install_path.append(tool_path.dirname)
    install_path.append("$PATH")
    
    # Build node_modules via 'yarn install'
    execute(ctx, [node, yarn_js, "install"], quiet = True, environment = {
        "PATH": ":".join(install_path),
    })

    # Run the script and save the stdout to our BUILD file(s)
    parse_args = ["--resolve=%s:%s" % (k, v) for k, v in ctx.attr.resolutions.items()]
    result = execute(ctx, [node, "internal/parse_yarn_lock.js"] + parse_args, quiet = True)
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
        # If specififed, augment the PATH environment variable with these
        # tools during 'yarn install'.  
        "install_tools": attr.string_list(),
        "package_json": attr.label(
            mandatory = False,
            allow_files = FileType(["package.json"]),
        ),
        "deps": attr.string_dict(mandatory = False),
        "resolutions": attr.string_dict(mandatory = False),
    }
)
