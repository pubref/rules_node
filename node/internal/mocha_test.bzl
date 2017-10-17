load("//node:internal/node_module.bzl", "node_module")
load("//node:internal/node_binary.bzl", "create_launcher", "copy_modules", "binary_attrs")

_node_filetype = FileType(['.js', '.node'])


def mocha_test_impl_old(ctx):
    output_dir = ctx.label.name + '_test'
    node = ctx.executable._node
    mocha = ctx.executable._mocha_bin

    all_deps = ctx.attr.deps + [ctx.attr.entrypoint]
    files = copy_modules(ctx, output_dir, all_deps)

    create_launcher(ctx, output_dir, node, mocha)

    mocha_deps_all = ctx.attr._mocha_deps.node_module
    transitive_mocha_files = mocha_deps_all.files.to_list()
    for dep in mocha_deps_all.transitive_deps:
        transitive_mocha_files += dep.files.to_list()

    runfiles = [
        node,
        mocha,
        ctx.outputs.executable
    ] + transitive_mocha_files + files

    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
            collect_data = True,
        ),
    )


def mocha_test_impl(ctx):
    output_dir = ctx.label.name + '_test'
    mocha_bin = ctx.executable.mocha_bin
    
    manifest_file = ctx.new_file('%s/node_modules/manifest.json' % output_dir)
    json = {}
    all_deps = [] + ctx.attr.deps
    if ctx.attr.entrypoint:
        all_deps.append(ctx.attr.entrypoint)
    
    files = copy_modules(ctx, output_dir, all_deps)

    dependencies = {}
    for dep in all_deps:
        module = dep.node_module
        dependencies[module.name] = module.version
        json['dependencies'] = struct(**dependencies)

    manifest_content = struct(**json)

    node = ctx.new_file('%s/%s' % (output_dir, ctx.executable._node.basename))
    ctx.action(
        mnemonic = 'CopyNode',
        inputs = [ctx.executable._node],
        outputs = [node],
        command = 'cp %s %s' % (ctx.executable._node.path, node.path),
    )


    ctx.file_action(
        output = manifest_file,
        content = manifest_content.to_json(),
    )
    
    create_launcher(ctx, output_dir, node, manifest_file)

    runfiles = [node, manifest_file, ctx.outputs.executable] + files
        
    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
            collect_data = True,
        ),
        mocha_test = struct(
            files = runfiles,
        )
    )


mocha_attrs = {
    'mocha_bin': attr.label(
        mandatory = True,
        cfg = "host",
        executable = True,
    ),
    'mocha_args': attr.string_list(
    ),
}


_mocha_test = rule(
    mocha_test_impl,
    attrs = binary_attrs + mocha_attrs,
    test = True,
)


def mocha_test(name = None,
               main = None,
               executable = None,
               entrypoint = None,
               version = None,
               node_args = [],
               deps = [],
               mocha_bin = "@mocha_modules//:mocha_bin",
               visibility = None,
               **kwargs):

    if not entrypoint:
        if not main:
            fail('Either an entrypoint node_module or a main script file must be specified')
        entrypoint = name + '_module'
        node_module(
            name = entrypoint,
            main = main,
            deps = [],
            version = version,
            visibility = visibility,
            **kwargs
        )

    _mocha_test(
        name = name,
        entrypoint = entrypoint,
        executable = executable,
        mocha_bin = mocha_bin,
        deps = deps,
        node_args = node_args,
        visibility = visibility,
    )
