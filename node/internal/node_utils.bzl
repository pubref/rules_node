node_attrs = {
    "node": attr.label(
        default = Label("@org_pubref_rules_node_toolchain//:bin/node"),
        single_file = True,
        allow_files = True,
        executable = True,
        cfg = "host",
    ),
}

def execute(ctx, cmds):
    result = ctx.execute(cmds)
    if result.return_code:
        fail(" ".join(cmds) + "failed: %s" %(result.stderr))
    return result
