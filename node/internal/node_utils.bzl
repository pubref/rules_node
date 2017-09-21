node_attrs = {
    "node": attr.label(
        default = Label("@node//:node"),
        single_file = True,
        allow_files = True,
        executable = True,
        cfg = "host",
    ),
}

def execute(ctx, cmds, **kwargs):
    result = ctx.execute(cmds, **kwargs)
    if result.return_code:
        fail(" ".join(cmds) + "failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (result.stdout, result.stderr))
    return result
