load("//node:internal/node_module.bzl", "node_module")
load("//node:internal/node_binary.bzl", "copy_modules", "binary_attrs")


def _create_launcher(ctx, output_dir, node, mocha):
    entry_module = ctx.attr.entrypoint.node_module
    entrypoint = '%s_test/node_modules/%s' % (ctx.label.name, entry_module.name)

    cmd = [
        node.short_path,
    ] + ctx.attr.node_args + [
        mocha.short_path,
    ] + ctx.attr.mocha_args + [
        entrypoint,
    ] + ctx.attr.script_args + [
        '$@',
    ]

    lines = [
        '#!/usr/bin/env bash',
        'set -e',
        ' '.join(cmd)
    ]

    ctx.file_action(
        output = ctx.outputs.executable,
        executable = True,
        content =  '\n'.join(lines),
    )


def mocha_test_impl(ctx):
    output_dir = ctx.label.name + '_test'
    node = ctx.executable._node
    mocha = ctx.executable._mocha_bin

    all_deps = ctx.attr.deps + [ctx.attr.entrypoint]
    files = copy_modules(ctx, output_dir, all_deps)

    _create_launcher(ctx, output_dir, node, mocha)

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


_mocha_test = rule(
    mocha_test_impl,
    attrs = binary_attrs + {
        "_mocha_bin": attr.label(
            default = Label("@mocha_modules//:mocha_bin"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "_mocha_deps": attr.label(
            providers = ["node_module"],
            default = Label("@mocha_modules//:_all_"),
        ),
        "mocha_args": attr.string_list(),
    },
    test = True,
)


def mocha_test(name = None, main = None, entrypoint = None, node_args = [], mocha_args = [], deps = [], visibility = None, size = "small", **kwargs):

    if not entrypoint:
        if not main:
            fail('Either an entrypoint node_module or a main script file must be specified')
        entrypoint = name + '_module'
        node_module(
            name = entrypoint,
            main = main,
            deps = [],
            visibility = visibility,
            **kwargs
        )

    _mocha_test(
        name = name,
        entrypoint = entrypoint,
        deps = deps,
        size = size,
        node_args = node_args,
        mocha_args = mocha_args,
        visibility = visibility,
    )
