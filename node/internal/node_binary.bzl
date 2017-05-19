load("//node:internal/node_library.bzl", "node_library")

_js_filetype = FileType([".js"])
_modules_filetype = FileType(["node_modules"])

BASH_TEMPLATE = """#!/usr/bin/env bash
set -e

# Resolve to 'this' node instance if other scripts
# have '/usr/bin/env node' shebangs
export PATH={node_bin_path}:$PATH

# Run it but wrap all calls to paths in a call to find. The call to find will
# search recursively through the filesystem to find the appropriate runfiles
# directory if that is necessary.
cd $(find . | grep -m 1 "{node_bin}" | sed 's|{node_bin}$||') && exec "{node_bin}" "{script_path}" $@
"""


def _get_node_modules_dir_from_package_json(file):
    filename = str(file)
    parts = filename.split("]")
    prefix = parts[0][len("Artifact:[["):]
    middle = parts[1]
    suffix = parts[2].split("/")
    d = "/".join([prefix, middle] + suffix[0:-3] + ["node_modules"])
    return d


def _get_node_modules_dir_from_sourcefile(file):
    bin = str(file)
    parts = bin.partition("[source]]")
    prefix = parts[0][len("Artifact:["):]
    suffix_parts = parts[2].split("/")
    return "/".join([prefix] + suffix_parts)


def node_binary_impl(ctx):
    inputs = []
    srcs = []
    script = ctx.file.main
    node = ctx.file._node

    for dep in ctx.attr.deps:
        lib = dep.node_library
        srcs += lib.transitive_srcs
        #inputs += [lib.node_module]
        for file in lib.transitive_node_modules:
            inputs.append(file)

    ctx.file_action(
        output = ctx.outputs.executable,
        executable = True,
        content = BASH_TEMPLATE.format(
            node_bin = node.path,
            script_path = script.path,
            node_bin_path = node.dirname,
        ),
    )

    runfiles = [node, script] + inputs + srcs

    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
            collect_data = True,
        ),
    )

_node_binary = rule(
    node_binary_impl,
    attrs = {
        "main": attr.label(
            single_file = True,
            allow_files = True,
            #allow_files = _js_filetype,
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
        "deps": attr.label_list(
            providers = ["node_library"],
        ),
        "_node": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    executable = True,
)


def node_binary(name, main = "index.js", data = [], deps = [], modules = []):
    node_library(
        name = name + '_lib',
        deps = deps,
        modules = modules,
    )

    _node_binary(
        name = name,
        main = main,
        data = data,
        deps = [name + '_lib'],
    )
