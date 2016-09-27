_js_filetype = FileType([".js"])

SCRIPT_TEMPLATE = """
#!/usr/bin/env bash
set -e
export NODE_PATH={node_paths}
"{node_bin}" "{script_path}" $@
"""


def _get_global_node_modules_dir(ctx):
    node_bin = str(ctx.file.node_tool)
    node_parts = node_bin.partition("[source]]")
    node_prefix = node_parts[0][len("Artifact:["):]
    node_suffix_parts = node_parts[2].split("/")
    node_lib = "/".join([node_prefix] + node_suffix_parts[0:-2] + ["lib", "node_modules"])
    return node_lib


def node_binary_impl(ctx):
    inputs = []
    node_paths = [_get_global_node_modules_dir(ctx)]
    for dep in ctx.attr.npm_deps:
        lib = dep.npm_library
        inputs.append(lib.package_marker)

    script = SCRIPT_TEMPLATE.format(
        node_bin = ctx.file.node_tool.short_path,
        script_path = ctx.file.main_script.short_path,
        node_paths = ":".join(node_paths),
    )

    ctx.file_action(
        output = ctx.outputs.executable,
        content = script,
        executable = True,
    )

    runfiles = [ctx.file.node_tool, ctx.file.main_script] + inputs

    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
        ),
    )


node_binary = rule(
    node_binary_impl,
    attrs = {
        "main_script": attr.label(
            single_file = True,
            allow_files = _js_filetype,
        ),
        "node_tool": attr.label(
            default = Label("//node/toolchain:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        # "deps": attr.label_list(
        #     providers = ["node_library"],
        # ),
        "npm_deps": attr.label_list(
            providers = ["npm_library"],
        ),
    },
    executable = True,
)
