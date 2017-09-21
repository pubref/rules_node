load("@org_pubref_rules_node//node:rules.bzl", "node_module")


def _get_d_ts_files(list):
    files = []
    for file in list:
        if file.path.endswith(".d.ts"):
            files.append(file)
    return files


def _build_node_module(ctx, compilation_dir, node_module):
    outputs = []
    for src in node_module.sources:
        relpath = node_module.sourcemap[src.path]
        dst = ctx.new_file("%s/node_modules/%s/%s" % (compilation_dir, node_module.name, relpath))
        outputs.append(dst)

        ctx.action(
            mnemonic = "CopyNodeModuleForTs",
            inputs = [src],
            outputs = [dst],
            command = "cp %s %s" % (src.path, dst.path),
        )
    return outputs


def _ts_module_impl(ctx):
    node = ctx.executable._node
    tsc = ctx.executable._tsc
    tsconfig = ctx.file.tsconfig
    inputs = [node, tsc]
    if tsconfig:
        inputs.append(tsconfig)

    compilation_dir = "package_" + ctx.label.name + ".tscompile"

    node_modules = [] # list of output files (building a custom node_modules tree for the compilation)
    for dep in ctx.attr.deps:
        node_modules += _build_node_module(ctx, compilation_dir, dep.node_module)

    output_js_files = []
    output_js_map_files = []
    output_d_ts_files = []

    srcs = []
    for src in ctx.files.srcs:
        copied_src = ctx.new_file("%s/%s" % (compilation_dir, src.short_path))
        ctx.action(
            inputs = [src],
            outputs = [copied_src],
            command = "cp %s %s" % (src.path, copied_src.path),
        )
        srcs.append(copied_src)

    for src in srcs:
        inputs.append(src)
        basefile = src.short_path[0:-len(src.extension) - 1]
        if ctx.label.package:
            basefile = ctx.label.package + "/" + basefile
        js_out = ctx.new_file("%s.js" % basefile)
        output_js_files.append(js_out)
        d_ts_out = ctx.new_file("%s.d.ts" % basefile)
        output_d_ts_files.append(d_ts_out)
        if (ctx.attr.sourcemap):
            js_map_out = ctx.new_file("%s.js.map" % basefile)
            output_js_map_files.append(js_map_out)

    arguments = [
        tsc.path,
        "--moduleResolution", "node",
        "--declaration",
    ] + ctx.attr.args

    if ctx.attr.sourcemap:
        arguments += ["--sourceMap"]

    if tsconfig:
        arguments += ["--project", tsconfig.path]

    for src in srcs:
        arguments.append(src.path)

    outputs = output_js_files + output_d_ts_files + output_js_map_files

    ctx.action(
        mnemonic = "TypescriptCompile",
        inputs = inputs + node_modules,
        outputs = outputs,
        executable = node,
        arguments = arguments,
    )

    return struct(
        files = depset(outputs),
        ts_module = struct(
            files = outputs,
            tsconfig = tsconfig,
            srcs = ctx.files.srcs,
        )
    )

_ts_module = rule(
    implementation = _ts_module_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = FileType([".ts", ".tsx"]),
            mandatory = True,
        ),
        "deps": attr.label_list(
            providers = ["node_module"],
        ),
        "tsconfig": attr.label(
            allow_files = FileType(["tsconfig.json"]),
            single_file = True,
            mandatory = False,
        ),
        "sourcemap": attr.bool(
            default = True,
        ),
        "args": attr.string_list(),
        "_tsc": attr.label(
            default = "@yarn_modules//:tsc_bin",
            executable = True,
            cfg = "host",
        ),
        "_node": attr.label(
            default = Label("@node//:node"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
)

def ts_module(name = None, srcs = [], tsconfig = None, deps = [], sourcemap = True, **kwargs):
    _ts_module(
        name = name + ".tsc",
        srcs = srcs,
        tsconfig = tsconfig,
        sourcemap = sourcemap,
        deps = deps,
    )
    node_module(
        name = name,
        srcs = [name + ".tsc"],
        deps = deps,
        **kwargs
    )
