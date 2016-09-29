def _npm_library_impl(ctx):
    node = ctx.executable.node
    npm = ctx.executable.npm
    package_marker = ctx.new_file("%s.package.json" % ctx.label.name)
    package_names = []

    cmds = []
    cmds.append("touch %s" % package_marker.path)

    cmd = [
        node.path,
        npm.path,
        "install",
        #"--global",
        "--prefix",
        package_marker.dirname,
    ]

    if ctx.attr.registry:
        cmd.append("--registry")
        cmd.append(ctx.attr.registry.npm_registry.url)

    deps = {}
    if ctx.attr.deps:
        deps = ctx.attr.deps
        for k, v in ctx.attr.deps.items():
            package_names.append(k)
            if v:
                cmd.append(k + "@" + v)
            else:
                cmd.append(k)
    else:
        deps = {}
        package_names.append(ctx.label.name)
        deps[ctx.label.name] = ""
        cmd += [ctx.label.name]

    cmds.append(" ".join(cmd))

    json_files = []
    for name in package_names:
        json_files.append(ctx.new_file("node_modules/%s/package.json" % name))

    ctx.action(
        mnemonic = "NpmInstall",
        command = " && ".join(cmds),
        inputs = [npm, node],
        outputs = [package_marker] + json_files,
    )

    return struct(
        files = set([package_marker]),
        npm_library = struct(
            name = ctx.label.name,
            deps = deps,
            json_files = json_files,
            package_marker = package_marker,
        ),
    )

npm_library = rule(
    implementation = _npm_library_impl,
    attrs = {
        "deps": attr.string_dict(),
        "node": attr.label(
            default = Label("//node/toolchain:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "npm": attr.label(
            default = Label("//node/toolchain:npm_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "registry": attr.label(
            single_file = True,
            allow_files = False,
            providers = ["npm_registry"],
        ),
    },
)
