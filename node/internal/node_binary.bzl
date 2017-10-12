load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load("//node:internal/node_module.bzl", "node_module")

_node_filetype = FileType(['.js', '.node'])


def _get_filename_relative_to_module_name(name, file):
    parts = file.path.partition(name)
    return '/'.join(parts[1:])


def _copy_module(ctx, output_dir, module):

    if len(module.files) == 0:
        return []

    inputs = []
    outputs = []

    script_file = ctx.new_file('%s/copy_%s.sh' % (output_dir, module.identifier))
    script_lines = []

    for src in module.files:
        inputs.append(src)
        dst_filename = _get_filename_relative_to_module_name(module.name, src)
        dst = ctx.new_file('%s/node_modules/%s' % (output_dir, dst_filename))
        outputs.append(dst)
        script_lines.append("cp '%s' '%s'" % (src.path, dst.path))

    ctx.file_action(
        output = script_file,
        content = '\n'.join(script_lines),
        executable = True,
    )

    ctx.action(
        mnemonic = 'CopyModuleWith%sFiles' % len(outputs),
        inputs = inputs + [script_file],
        outputs = outputs,
        command = script_file.path,
    )

    return outputs


def copy_modules(ctx, output_dir, deps):
    outputs = []
    for dep in deps:
        module = dep.node_module
        outputs += _copy_module(ctx, output_dir, module)
        for module in module.transitive_deps:
            outputs += _copy_module(ctx, output_dir, module)
    return outputs


def _create_launcher(ctx, output_dir, node):
    
    entry_module = ctx.attr.entrypoint.node_module
    entrypoint = 'node_modules/%s' % entry_module.name

    if ctx.attr.executable:
        entrypoint += "/" + entry_module.executables[ctx.attr.executable]
        
    # cd $(dirname $0)/bundle and exec node node_modules/foo
    cmd = [
        'cd $ROOT/%s' % output_dir,
        '&&',
        'exec',
        './' + ctx.executable._node.basename,
    ] + ctx.attr.node_args + [
        entrypoint,
    ] + ctx.attr.script_args + [
        '$@',
    ]

    lines = [
        '#!/usr/bin/env bash', # TODO(user): fix for windows
        'set -e',

        #'pwd',
        #'ls -al .',
        #'find .',
        
        # Set the execution root to the same directory where the
        # script lives.  We know for sure that node executable and
        # node_modules dir will also be close to here since we
        # specifically built that here (this means we don't have to go
        # through backflips to figure out what run context we're in.
        'ROOT=$(dirname $0)',

        # Resolve to this node instance if other scripts have
        # '/usr/bin/env node' shebangs
        # TODO: fix for windows
        'export PATH="$ROOT:$PATH"',

        ' '.join(cmd)
    ]

    ctx.file_action(
        output = ctx.outputs.executable,
        executable = True,
        content =  '\n'.join(lines),
    )


def node_binary_impl(ctx):
    output_dir = ctx.label.name + '_bundle'

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

    ctx.file_action(
        output = manifest_file,
        content = manifest_content.to_json(),
    )

    node = ctx.new_file('%s/%s' % (output_dir, ctx.executable._node.basename))
    ctx.action(
        mnemonic = 'CopyNode',
        inputs = [ctx.executable._node],
        outputs = [node],
        command = 'cp %s %s' % (ctx.executable._node.path, node.path),
    )

    _create_launcher(ctx, output_dir, node)

    runfiles = [node, manifest_file, ctx.outputs.executable] + files
        
    files = runfiles if ctx.attr.export_files else []

    return struct(
        files = depset(files),
        runfiles = ctx.runfiles(
            files = runfiles,
            collect_data = True,
        ),
        node_binary = struct(
            files = runfiles,
        )
    )

binary_attrs = {
    # The main entrypoint module to run
    'entrypoint': attr.label(
        providers = ['node_module'],
        mandatory = False,
    ),
    # A named executable module script to run
    'executable': attr.string(
        mandatory = False,
    ),
    # node_module dependencies
    'deps': attr.label_list(
        providers = ['node_module'],
    ),
    # Raw Arguments to the node executable
    'node_args': attr.string_list(
    ),
    # Arguments to be included in the launcher script
    'script_args': attr.string_list(
    ),
    # The node executable
    '_node': attr.label(
        default = Label('@node//:node'),
        single_file = True,
        allow_files = True,
        executable = True,
        cfg = 'host',
    ),
}


_node_binary = rule(
    node_binary_impl,
    attrs = binary_attrs + {
        # Export as a files provider if True.
        'export_files': attr.bool(
            default = False,
        ),
    },
    executable = True,
)


def node_binary_files_impl(ctx):
    return struct(
        files = depset(ctx.attr.target.node_binary.files),
    )

_node_binary_files = rule(
    node_binary_files_impl,
    attrs = {
        'target': attr.label(
            providers = ['node_binary'],
            mandatory = True,
        ),
    },
)

def node_binary(name = None,
                main = None,
                executable = None,
                entrypoint = None,
                version = None,
                node_args = [],
                deps = [],
                extension = 'tgz',
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

    _node_binary(
        name = name,
        entrypoint = entrypoint,
        executable = executable,
        deps = deps,
        export_files = name.endswith('_bundle.tgz'),
        node_args = node_args,
        visibility = visibility,
    )

    _node_binary_files(
        name = name + '_files',
        target = name,
        visibility = visibility,
    )

    pkg_tar(
        name = name + '_bundle',
        extension = extension,
        package_dir = name,
        srcs = [name + '_files'],
        visibility = visibility,
        strip_prefix = '.',
    )
