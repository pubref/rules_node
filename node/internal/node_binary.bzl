load("//node:internal/node_library.bzl", "node_library")

_js_filetype = FileType([".js"])
_modules_filetype = FileType(["node_modules"])


def node_binary_impl(ctx):
    srcs = set()
    script = ctx.file.main
    node = ctx.file._node
    node_module_paths = []

    for dep in ctx.attr.modules:
        #print("dep: %r" % dep)
        module = dep.node_module
        srcs += module.transitive_srcs
        for path in module.transitive_dirs:
            node_module_paths.append("%s/node_modules" % path)

    #print("node_module_paths: %r" % node_module_paths)

    ctx.template_action(
        template=ctx.file._launcher_template,
        output=ctx.outputs.executable,
        substitutions={
            "TEMPLATED_workspace": ctx.workspace_name,
            "TEMPLATED_node": node.path,
            "TEMPLATED_args": " ".join(ctx.attr.args),
            "TEMPLATED_paths": " ".join(node_module_paths),
            "TEMPLATED_script_path": script.short_path,
        },
        executable=True,
    )

    return struct(
        runfiles = ctx.runfiles(
            files = [node] + [script] + srcs.to_list(),
            collect_data = True,
        ),
    )

node_binary = rule(
    node_binary_impl,
    attrs = {
        "main": attr.label(
            single_file = True,
            allow_files = True,
            mandatory = True,
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
        "deps": attr.label_list(
            providers = ["node_library"],
        ),
        "modules": attr.label_list(
            allow_files = True,
            cfg = "data",
            providers = ["node_module"],
        ),
        "_node": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "_launcher_template": attr.label(
            default = Label("//node/internal:node_launcher.sh"),
            allow_files = True,
            single_file = True,
        ),
    },
    executable = True,
)
