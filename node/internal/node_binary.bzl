load("//node:internal/npm_library.bzl", "npm_library")

_js_filetype = FileType([".js"])

SCRIPT_TEMPLATE = """
#!/usr/bin/env bash
set -e

# Resolve to 'this' node instance if other scripts
# have '/usr/bin/env node' shebangs
export PATH={node_bin_path}:$PATH

# Used by NPM
export NODE_PATH={node_paths}

# Run it
"{node_bin}" "{script_path}" $@
"""


def _get_global_node_modules_dir(ctx):
    bin = str(ctx.file.node_tool)
    parts = bin.partition("[source]]")
    prefix = parts[0][len("Artifact:["):]
    suffix_parts = parts[2].split("/")
    return "/".join([prefix] + suffix_parts[0:-2] + ["lib", "node_modules"])


def _get_node_modules_dir(file):
    filename = str(file)
    parts = filename.split("]")
    prefix = parts[0][len("Artifact:[["):]
    middle = parts[1]
    suffix = parts[2].split("/")
    d = "/".join([prefix, middle] + suffix[0:-1] + ["node_modules"])
    return d

def _get_node_modules_dir_from_package_json(file):
    filename = str(file)
    #print("file dir %s" % filename)
    parts = filename.split("]")
    prefix = parts[0][len("Artifact:[["):]
    middle = parts[1]
    suffix = parts[2].split("/")
    d = "/".join([prefix, middle] + suffix[0:-3] + ["node_modules"])
    #print("parts: %s" % parts)
    #print("prefix: %s" % prefix)
    #print("suffix: %s" % suffix)
    return d


def _get_workspace_node_modules_dir(ctx):
    bin = str(ctx.outputs.executable)
    #print("bin: %s" % bin)
    parts = bin.split("]")
    #print("parts: %s" % parts)
    prefix = parts[0].split("[[")[1]
    d = "/".join([prefix] + ["node_modules"])
    #print("ws dir: %s" % d)
    return d

    #_get_global_node_modules_dir(ctx),
    #_get_workspace_node_modules_dir(ctx),


def node_binary_impl(ctx):
    inputs = []
    srcs = []
    node_paths = []

    for dep in ctx.attr.npm_deps:
        lib = dep.npm_library
        inputs.append(lib.package_marker)
        node_paths += [_get_node_modules_dir(lib.package_marker)]

    for dep in ctx.attr.deps:
        lib = dep.node_library
        srcs += lib.transitive_srcs
        inputs += [lib.package_json]
        inputs += [lib.npm_package_json]
        node_paths += [_get_node_modules_dir_from_package_json(lib.package_json)]

    node_paths = list(set(node_paths))
    node = ctx.file.node_tool
    script = SCRIPT_TEMPLATE.format(
        node_bin = node.short_path,
        script_path = ctx.file.main_script.short_path,
        node_bin_path = node.dirname,
        node_paths = ":".join(node_paths),
    )

    ctx.file_action(
        output = ctx.outputs.executable,
        content = script,
        executable = True,
    )

    #print("node_paths %s" % "\n".join(node_paths))

    runfiles = [ctx.file.node_tool, ctx.file.main_script] + inputs + srcs

    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
        ),
    )

_node_binary = rule(
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
        "data": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            providers = ["node_library"],
        ),
        "npm_deps": attr.label_list(
            providers = ["npm_library"],
        ),
    },
    executable = True,
)

def node_binary(name = "", npm_libraries = {}, npm_deps = [], **kwargs):
    if npm_libraries:
        libname = name + ".npmlibs"
        npm_library(
            name = libname,
            deps = npm_libraries,
        )
        npm_deps += [libname]
    _node_binary(name = name, npm_deps = npm_deps, **kwargs)
