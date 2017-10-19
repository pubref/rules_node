load("//node:internal/node_modules.bzl", "node_modules")
load("//node:internal/node_module.bzl", "node_module")
load("//node:internal/node_bundle.bzl", "node_bundle")

def create_launcher(ctx, output_dir, node, manifest):
    path = manifest.short_path.split('/')
    dirname = "/".join(path[0:-1])
    entry_module = ctx.attr.entrypoint.node_module
    
    # Module name is always present
    entrypoint = entry_module.name
    # Suffix with the executable path if present
    if ctx.attr.executable:
        entrypoint += "/" + entry_module.executables[ctx.attr.executable]

    package_path = [ctx.label.package]
    if ctx.label.workspace_root:
        package_path.append(ctx.label.workspace_root)
    
    cmd = [
        'exec',
        '"${TARGET_PATH}${NODE_EXE}"',
    ] + ctx.attr.node_args + [
        '"${TARGET_PATH}node_modules/${ENTRYPOINT}"',
    ] + ctx.attr.script_args + [
        '$@',
    ]

    lines = [
        '#!/usr/bin/env bash', # TODO(user): fix for windows
        'set -eux',

        #'pwd',
        #'echo "script: $0"',
        #'find . >&2',
        #'ls -al $(dirname $0) >&2',

        '# Looking for node as the marker for where everything else is...',
        'NODE_EXE="%s"' % node.basename,
        'PACKAGE_PATH="%s"' % "/".join(package_path),
        'TARGET_NAME="%s"' % ctx.attr.target,
        'BASENAME="$(basename $0)"',
        'TARGET_PATH=""' ,
        'ENTRYPOINT="%s"' % entrypoint,
        
        '',        
        'if [[ -e "${0}.runfiles/__main__/${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${0}.runfiles/__main__/${PACKAGE_PATH}/${TARGET_NAME}/"', 
        '  echo "Matched [bazel run] context [${TARGET_PATH}]"',
        '',
        'elif [[ -e "${0}_files/${NODE_EXE}" ]]; then',
        #'elif [[ -e "${PACKAGE_PATH}${TARGET_NAME}_files/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${0}_files/"',
        #'  TARGET_PATH="${PACKAGE_PATH}${TARGET_NAME}_files/"',
        '  echo "Matched [standalone script] or [bazel test] context [${TARGET_PATH}]"',
        '',
        'elif [[ -e "${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${PACKAGE_PATH}/${TARGET_NAME}/"',
        '  echo "Matched [bazel test TESTRULE] context [${TARGET_PATH}]"',
        '',
        'else',
        '  echo "Failed to find target execution path! Aborting" >&2',
        '  exit 1',
        'fi',

        #'find "${TARGET_PATH}"',
        # '',        
        # '# Attempt 1: try node_bundle dir (true for genrule context)',
        # 'if [[ -e "${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        # '  TARGET_PATH="${PACKAGE_PATH}/${TARGET_NAME}/"',
        # '  echo "Matched [bazel build GENRULE] context [${TARGET_PATH}]"',
        # '',
        # '# Attempt 2: try runfiles dir (true for run context)',
        # 'elif [[ -e "${PACKAGE_PATH}/${TARGET_NAME}.runfiles/__main__/${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        # '  TARGET_PATH="${PACKAGE_PATH}/${TARGET_NAME}.runfiles/__main__/${PACKAGE_PATH}/${TARGET_NAME}/"', #${0}.runfiles/__main__/${TARGET_NAME}/"',
        # '  echo "Matched [bazel run BINRULE] context [${TARGET_PATH}]"',
        # '',
        # '# Attempt 3: try runfiles dir (true for run context)',
        # 'elif [[ -e "${0}.runfiles/__main__/${PACKAGE_PATH}/{TARGET_NAME}/${NODE_EXE}" ]]; then',
        # '  TARGET_PATH="${0}.runfiles/__main__/${PACKAGE_PATH}/{TARGET_NAME}/"',
        # '  echo "Matched [bazel run BINRULE] context [${TARGET_PATH}]"',
        # '',
        # '# Attempt 4: try target dir (true for test/script/tgz (and run) context)',
        # 'elif [[ -e "./${0}.files/${NODE_EXE}" ]]; then',
        # '  TARGET_PATH="${0}.files/"',
        # '  echo "Matched [bazel test TESTRULE] or [standalone script] context [${TARGET_PATH}]"',
        # '',
        # 'else',
        # '  echo "Failed to find node! Aborting" >&2',
        # '  exit 1',
        # 'fi',
        
        # TODO: fix for windows
        '# Modify path such that embedded scripts with /usr/bin/env node shebangs',
        '# Resolve to the bundled node executable',
        'export PATH="${TARGET_PATH}:$PATH"',

        ' '.join(cmd)
    ]

    #print("\n".join(lines))
    
    ctx.file_action(
        output = ctx.outputs.executable,
        executable = True,
        content =  '\n'.join(lines),
    )

    
def node_binary_impl(ctx):
    #output_dir = ctx.label.name + '_bundle'
    output_dir = ctx.attr.target

    node = ctx.new_file('%s/%s' % (output_dir, ctx.executable._node.basename))
    ctx.action(
        mnemonic = 'CopyNode',
        inputs = [ctx.executable._node],
        outputs = [node],
        command = 'cp %s %s' % (ctx.executable._node.path, node.path),
    )
    
    files = ctx.attr.node_modules.node_modules.files
    create_launcher(ctx, output_dir, node, ctx.attr.node_modules.node_modules.manifest)

    runfiles = [node, ctx.outputs.executable] + files
        
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
    'node_modules': attr.label(
        mandatory = True,
        providers = ['node_modules'],
    ),
    'target': attr.string(
        mandatory = True,
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


def node_binary(name = None,
                main = None,
                executable = None,
                entrypoint = None,
                version = None,
                node_args = [],
                deps = [],
                deploy = 'tar.gz',
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

    node_modules(
        name = name + '_modules',
        deps = deps + [entrypoint],
        target = name + '_files',
    )

    _node_binary(
        name = name,
        entrypoint = entrypoint,
        executable = executable,
        node_modules = name + '_modules',
        target = name + '_files',
        node_args = node_args,
        visibility = visibility,
    )

    node_bundle(
        name = name + '_bundle',
        node_binary = name,
        extension = deploy,
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
              size = None,
              visibility = None,
              **kwargs):

    if not entrypoint:
        if not main:
            fail('Either an entrypoint node_module or a main script file must be specified')
        entrypoint = name + '_module'
        node_module(
            name = entrypoint,
            main = main,
            deps = deps,
            version = version,
            visibility = visibility,
            **kwargs
        )


    node_modules(
        name = name + '_modules',
        deps = deps + [entrypoint],
        target = name + '_files',
    )
        
    _node_test(
        name = name,
        entrypoint = entrypoint,
        executable = executable,
        node_modules = name + '_modules',
        target = name + '_files',
        node_args = node_args,
        visibility = visibility,
        size = size,
    )
