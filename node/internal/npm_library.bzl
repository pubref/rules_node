def _npm_library_impl(ctx):
    node = ctx.executable.node
    npm = ctx.executable.npm
    package_marker = ctx.new_file("%s.package.json" % ctx.label.name)

    cmds = []
    cmds.append("touch %s" % package_marker.path)

    cmd = [
        node.path,
        npm.path,
        "install",
        "--global",
    ]

    if ctx.attr.deps:
        for k, v in ctx.attr.deps.items():
            cmd += [k + "@" + v]
    else:
        cmd += [ctx.label.name]

    cmds.append(" ".join(cmd))

    ctx.action(
        mnemonic = "NpmInstall",
        command = " && ".join(cmds),
        inputs = [npm, node],
        outputs = [package_marker],
    )

    return struct(
        files = set([package_marker]),
        npm_library = struct(
            name = ctx.label.name,
            deps = ctx.attr.deps,
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
    },
)
