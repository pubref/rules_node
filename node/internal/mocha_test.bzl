_js_filetype = FileType([".js"])
_modules_filetype = FileType(["node_modules"])

BASH_TEMPLATE = """
#!/usr/bin/env bash
set -e

# Resolve to 'this' node instance if other scripts
# have '/usr/bin/env node' shebangs
export PATH={node_bin_path}:$PATH

# Used by NPM
export NODE_PATH={node_paths}

# Run it
"{node}" "{mocha}" {mocha_args} "{script_path}" $@
"""


def _get_abs_sourcepath(file):
    filename = str(file)
    #print("filename: %s" % filename)
    parts = filename.partition("[source]]")
    prefix = parts[0][len("Artifact:["):]
    suffix = parts[2]
    d = "/".join([prefix, suffix])
    #print("abs filename: %s" % d)
    return d


def _get_node_modules_dir_from_binfile(file):
    bin = str(file)
    parts = bin.partition("[source]]")
    prefix = parts[0][len("Artifact:["):]
    suffix_parts = parts[2].split("/")
    #print("prefix: %s, suffix_parts: %s" % (prefix, suffix_parts))
    return "/".join([prefix] + suffix_parts[0:2] + ["node_modules"])


def _get_node_modules_dir_from_package_json(file):
    filename = str(file)
    parts = filename.split("]")
    prefix = parts[0][len("Artifact:[["):]
    middle = parts[1]
    suffix = parts[2].split("/")
    d = "/".join([prefix, middle] + suffix[0:-3] + ["node_modules"])
    return d



def mocha_test_impl(ctx):
    inputs = []
    srcs = []
    script = ctx.file.main
    node = ctx.file._node
    mocha = ctx.file.mocha
    node_paths = []
    node_paths.append(_get_node_modules_dir_from_binfile(mocha))

    mocha_path = _get_abs_sourcepath(mocha)

    for file in ctx.files.modules:
        #print("file: %s" % file)
        if not file.basename.endswith("node_modules"):
            fail("npm_dependency should be a path to a node_modules/ directory.")
        node_paths += [_get_node_modules_dir_from_binfile(file)]

    for dep in ctx.attr.deps:
        lib = dep.node_library
        srcs += lib.transitive_srcs
        inputs += [lib.package_json, lib.npm_package_json]
        node_paths += [_get_node_modules_dir_from_package_json(lib.package_json)]
        for file in lib.transitive_node_modules:
            node_paths += [file.path]
            inputs.append(file)

    node_paths = list(set(node_paths))

    ctx.file_action(
        output = ctx.outputs.executable,
        executable = True,
        content = BASH_TEMPLATE.format(
            node_paths = ":".join(node_paths),
            node = node.short_path,
            node_bin_path = node.dirname,
            script_path = script.short_path,
            mocha = mocha_path,
            mocha_args = " ".join(ctx.attr.mocha_args),
        ),
    )

    #print("node_paths %s" % "\n".join(node_paths))

    runfiles = [node, script] + inputs + srcs

    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
            collect_data = True,
        ),
    )


mocha_test = rule(
    mocha_test_impl,
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
        "modules": attr.label_list(
            allow_files = _modules_filetype,
        ),
        "_node": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "mocha": attr.label(
            default = Label("@npm_mocha//:bin/mocha"),
            allow_files = True,
            single_file = True,
        ),
        "mocha_modules": attr.label(
            default = Label("@npm_mocha//:modules"),
        ),
        "mocha_args": attr.string_list(),
    },
    test = True,
)
