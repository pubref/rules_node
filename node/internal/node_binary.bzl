load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load("//node:internal/node_module.bzl", "node_module")

_node_filetype = FileType(['.js', '.node'])


def _get_filename_relative_to_module(module, file):
    parts = file.path.partition("/%s/" % module.name)
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
        dst_filename = _get_filename_relative_to_module(module, src)
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


def create_launcher(ctx, output_dir, node, manifest_file):

    path = manifest_file.short_path.split('/')
    dirname = "/".join(path[0:-1])
    entry_module = ctx.attr.entrypoint.node_module

    entrypoint = entry_module.name
    if ctx.attr.executable:
        entrypoint += "/" + entry_module.executables[ctx.attr.executable]
    entrypath = '%s/%s' % (dirname, entrypoint)
    

    # cd $(dirname $0)/bundle and exec node node_modules/foo
    cmd = [
        #'exec',
        '"$NODE_BIN"',
    ] + ctx.attr.node_args + [
        '"$ENTRYPOINT"',
    ] + ctx.attr.script_args + [
        '$@',
    ]

    # Next: Script should look to see if various conditions exist.
    # 1. If the file '../yarn_modules/webpack_bin_bundle/node' exists, assume bazel run context.
    # 2. If the file $(dirname $0)/whihc_bin_bundle/node exists, assume shell context.
    # 3. If the file ... exists, assume TEST context.
    # 4. If the file ... exists, assume GENFILE context (actually seems same as (2).
    
    lines = [
        '#!/usr/bin/env bash', # TODO(user): fix for windows
        'set -eu',
        #'echo $@',
        #'pwd',
        'ls -al .',
        #'find .',
        'ROOT=$(dirname $0)',
        '# Assume we are in bazel runfiles context to start...',
        'NODE_BIN="%s"' % node.short_path,
        'ENTRYPOINT="%s"' % entrypath,
        
        '# If expected location of node not exists, try looking within runfiles',
        '# will be present in genrule context',
        'if [[ ! -e $NODE_BIN ]]; then',
        '  NODE_BIN="$0.runfiles/__main__/%s"' % (node.short_path),
        '  ENTRYPOINT="$0.runfiles/__main__/%s"' % entrypath,
        '  echo "Trying runfiles!"',
        'fi',

        '# If this not exists, try looking for the bundle folder',
        'if [[ ! -e $NODE_BIN ]]; then',
        '  NODE_BIN="$(basename $0)_bundle/%s"' % (node.basename),
        '  ENTRYPOINT="$(basename $0)_bundle/node_modules/%s"' % entrypoint,
        '  echo "Trying bundle!"',
        'fi',

        # Resolve to this node instance if other scripts have
        # '/usr/bin/env node' shebangs
        # TODO: fix for windows
        'export PATH="$ROOT:$PATH"',

        #'echo "NODE_BIN: $NODE_BIN"',
        #'echo "ENTRYPOINT: $ENTRYPOINT"',
        ' '.join(cmd)
    ]

    #print("\n".join(lines))
    
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
    
    create_launcher(ctx, output_dir, node, manifest_file)

    runfiles = [node, manifest_file, ctx.outputs.executable] + files
        
    return struct(
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
    attrs = binary_attrs,
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


_node_test = rule(
    node_binary_impl,
    attrs = binary_attrs,
    test = True,
)


def node_test(name = None,
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

    _node_test(
        name = name,
        entrypoint = entrypoint,
        executable = executable,
        deps = deps,
        node_args = node_args,
        visibility = visibility,
    )
