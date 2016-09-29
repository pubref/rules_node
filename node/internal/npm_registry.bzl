def _npm_registry_impl(ctx):
    scope = ctx.label.name
    url = ctx.attr.url
    node = ctx.executable.node
    npm = ctx.executable.npm
    registration_file = ctx.new_file(scope + ".npm-registry-config")

    cmds = ["touch " + registration_file.path]

    cmds.append(" ".join([
        node.path,
        npm.path,
        "config",
        "set",
        "@%s=%s" % (scope, url),
    ]))

    ctx.action(
        mnemonic = "NpmConfig",
        inputs = [node, npm],
        outputs = [registration_file],
        command = " && ".join(cmds)
    )
    return struct(
        files = set([registration_file]),
        npm_registry = struct(
            url = url,
            scope = scope,
        ),
    )

npm_registry = rule(
    implementation = _npm_registry_impl,
    attrs = {
        "url": attr.string(mandatory = True),
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
