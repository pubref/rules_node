load("@org_pubref_rules_node//node/internl:node_module.bzl", "node_module", "NodeModuleInfo")

# Note: this is not by any means production quality support for
# typescript.  It's more of an experiment to exercise the
# behavior/utility of the node_module rule in various circumstances.

def _build_node_module(ctx, compilation_dir, node_module):
    """Copy the given node_module into the specified compilation dir"""
    
    outputs = []
    for src in node_module.sources:
        relpath = node_module.sourcemap[src.path]
        dst = ctx.actions.declare_file("%s/node_modules/%s/%s" % (compilation_dir, node_module.name, relpath))
        outputs.append(dst)

        ctx.action(
            mnemonic = "CopyNodeModuleForTs",
            inputs = [src],
            outputs = [dst],
            command = "cp %s %s" % (src.path, dst.path),
        )
    return outputs


def _get_relative_path(file, rel):
    """Get the path of a file relative to to rel.
    
    For example, if rel is the bazel-bin/foo/tsconfig.json and 'file'
    is bazel-bin/foo/a/b/c.ts, return 'a/b/c.ts'
    """
    
    return file.path[len(rel.dirname) + 1:]


def _create_tsconfig(ctx, compilation_dir, srcs):
    """Create the tsconfig.json file"""
    
    # The tsconfig file to be generated
    tsconfig_file = ctx.actions.declare_file("%s/tsconfig.json" % compilation_dir)

    # The files that we want to compile
    files = [_get_relative_path(file, tsconfig_file) for file in srcs]

    # Todo: add all the necessary attributes for the tsconfig
    json = {
        "name": ctx.label.name,
        "files": files
    }

    # Generate a struct from the map
    content = struct(**json)

    # Create a file action to generate it...
    ctx.actions.write(
        output = tsconfig_file,
        content = content.to_json(),
    )

    return tsconfig_file

    
def _ts_module_impl(ctx):
    # Location where we'll copy all the needed files for the ts compilation.
    compilation_dir = ctx.label.name
    # Compilation inputs
    inputs = []
    # Compilation outputs
    outputs = []

    # list of module output files (building a custom node_modules tree
    # for the compilation)
    node_modules = [] 
    for dep in ctx.attr.deps:
        node_modules += _build_node_module(ctx, compilation_dir, dep.node_module)

    # Copy the source files into the compilation dir.
    srcs = [] 
    for src in ctx.files.srcs:
        copied_src = ctx.actions.declare_file("%s/%s" % (compilation_dir, src.short_path))
        ctx.action(
            inputs = [src],
            outputs = [copied_src],
            command = "cp %s %s" % (src.path, copied_src.path),
        )
        srcs.append(copied_src)

    # Generate a *.js, *.d.ts, and *.js.map file foreach source *.ts file.
    for src in srcs:
        inputs.append(src)
        basefile = src.short_path[0:-len(src.extension) - 1]
        if ctx.label.package:
            basefile = ctx.label.package + "/" + basefile
        js_out = ctx.actions.declare_file("%s.js" % (basefile))
        outputs.append(js_out)
        d_ts_out = ctx.actions.declare_file("%s.d.ts" % (basefile))
        outputs.append(d_ts_out)
        if (ctx.attr.sourcemap):
            js_map_out = ctx.actions.declare_file("%s.js.map" % (basefile))
            outputs.append(js_map_out)

    # Generate a tsconfig.json file
    tsconfig = _create_tsconfig(ctx, compilation_dir, srcs)

    # Setup args for tsc
    arguments = [
        "--moduleResolution", "node",
        "--declaration",
        "--project", tsconfig.path,
    ] + ctx.attr.args

    if ctx.attr.sourcemap:
        arguments += ["--sourceMap"]

    # Run the compilation
    ctx.action(
        mnemonic = "TypescriptCompile",
        inputs = inputs + node_modules + [tsconfig],
        outputs = outputs,
        executable = ctx.executable._tsc,
        arguments = arguments,
    )

    return struct(
        files = depset(outputs + [tsconfig]),
        ts_module = struct(
            files = outputs,
            tsconfig = tsconfig,
            srcs = srcs,
        )
    )


_ts_module = rule(
    implementation = _ts_module_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".ts", ".tsx"],
            mandatory = True,
        ),
        "deps": attr.label_list(
            providers = [NodeModuleInfo],
        ),
        "sourcemap": attr.bool(
            default = True,
        ),
        "args": attr.string_list(),
        "_tsc": attr.label(
            default = "@yarn_modules//:typescript_tsc_bin",
            executable = True,
            cfg = "host",
        ),
    },
)


def ts_module(name = None, srcs = [], deps = [], **kwargs):
    _ts_module(
        name = name + "_ts",
        srcs = srcs,
        deps = deps,
    )
    node_module(
        name = name,
        srcs = [name + "_ts"],
        deps = deps,
        # It's a bit of a hack to use the 'flat' layout here, but it
        # makes the import of generated modules simpler.
        layout = "flat",
        **kwargs
    )
