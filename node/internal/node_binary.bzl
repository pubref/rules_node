load("//node:internal/node_modules.bzl", "node_modules")
load("//node:internal/node_module.bzl", "node_module")
load("//node:internal/node_bundle.bzl", "node_bundle")


def create_launcher(ctx, output_dir, node, manifest):
    """Create a launch bash script

    Given the ctx object, the name of the target output dir, the node
    executable, and a manifest file (whose 'dirname' points to the
    node_modules location), write out a script that runs node.  It
    looks for several directory layout patterns that may exist if
    invoked under various conditions (bazel run, bazel test, genrule,
    standalone script, within a standalone bundle).

    """

    entry_module = ctx.attr.entrypoint.node_module
    
    # Entrypoint is a string that is used in the script for the node
    # main start point.  It can be the name of the module itself (in
    # which case node looks for index.js or package.json), or an
    # executable 'bin' script path within the module.
    entrypoint = entry_module.name
    if ctx.attr.executable:
        entrypoint += "/" + entry_module.executables[ctx.attr.executable]

    # The package path is the path 
    package_path = []
    if ctx.label.workspace_root:
        package_path.append(ctx.label.workspace_root.replace("external/", "", 1))
    if ctx.label.package:
        package_path.append(ctx.label.package)
    
    cmd = [
        # Replace shell process with node process
        'exec "${TARGET_PATH}${NODE_EXE}"',
    ] + ctx.attr.node_args + [
        '"${TARGET_PATH}node_modules/${ENTRYPOINT}"',
    ] + ctx.attr.script_args + [
        '$@',
    ]

    lines = [
        '#!/usr/bin/env bash', 
        'set -eu', # -eux for debugging

        # Location of node
        'NODE_EXE="%s"' % node.basename,
        # Path to the node module
        'PACKAGE_PATH="%s"' % "/".join(package_path),
        # Namespace where node and node_modules assets have been
        # built.
        'TARGET_NAME="%s"' % ctx.attr.target,
        # Workspace name where this rule is defined
        'WORKSPACE_NAME="%s"' % ctx.workspace_name,
        # Based on the way the script has been invoked, $PACKAGE_PATH
        # can exist in various locations.  We need to discover this
        # and assign the value to $TARGET_PATH.
        'TARGET_PATH=""' ,

        'ENTRYPOINT="%s"' % entrypoint,

        'if [[ -e "${0}_files/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${0}_files/"',
        #'  echo "Matched [standalone script] or [bazel test] context [${TARGET_PATH}]"',
        '',
        'elif [[ -e "${0}.runfiles/__main__/${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${0}.runfiles/__main__/${PACKAGE_PATH}/${TARGET_NAME}/"',
        #'  echo "Matched [bazel run] context [${TARGET_PATH}]"',
        '',
        'elif [[ -e "${0}.runfiles/${WORKSPACE_NAME}/${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${0}.runfiles/${WORKSPACE_NAME}/${PACKAGE_PATH}/${TARGET_NAME}/"',
        #'  echo "Matched [bazel build] or [bazel run] context in a named workspace [${TARGET_PATH}]"',
        '',
        'elif [[ -e "${0}.runfiles/${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${0}.runfiles/${PACKAGE_PATH}/${TARGET_NAME}/"',
        #'  echo "Matched [bazel build] context [${TARGET_PATH}]"',
        '',
        'elif [[ -e "${PACKAGE_PATH}/${TARGET_NAME}/${NODE_EXE}" ]]; then',
        '  TARGET_PATH="${PACKAGE_PATH}/${TARGET_NAME}/"',
        #'  echo "Matched [bazel test TESTRULE] context [${TARGET_PATH}]"',
        '',
        'else',
        '  echo "Failed to find target execution path! Aborting" >&2',
        '  exit 1',
        'fi',

        '# Modify path such that embedded scripts with /usr/bin/env node shebangs',
        '# resolve to the bundled node executable',
        'export NODE_PATH="${TARGET_PATH}/node_modules"',
        'export PATH="${TARGET_PATH}:$PATH"',

        ' '.join(cmd)
    ]

    ctx.file_action(
        output = ctx.outputs.executable,
        executable = True,
        content =  '\n'.join(lines),
    )

    
def node_binary_impl(ctx):
    target_dir = ctx.attr.target

    node = ctx.new_file('%s/%s' % (target_dir, ctx.executable._node.basename))
    ctx.action(
        mnemonic = 'CopyNode',
        inputs = [ctx.executable._node],
        outputs = [node],
        command = 'cp %s %s' % (ctx.executable._node.path, node.path),
    )
    
    files = ctx.attr.node_modules.node_modules.files
    create_launcher(ctx, target_dir, node, ctx.attr.node_modules.node_modules.manifest)

    runfiles = [node, ctx.outputs.executable] + files
        
    return struct(
        runfiles = ctx.runfiles(
            files = runfiles,
            collect_data = True,
        ),
        node_binary = struct(
            files = runfiles,
            node = node,
        )
    )

binary_attrs = {
    # The main entrypoint module to run
    'entrypoint': attr.label(
        providers = ['node_module'],
        mandatory = False,
    ),
    # An optional named executable module script to run
    'executable': attr.string(
        mandatory = False,
    ),
    # node_module dependencies.  Given the entrypoint module must
    # exist within the node_modules tree, this is a mandatory
    # attribute.
    'node_modules': attr.label(
        mandatory = True,
        providers = ['node_modules'],
    ),
    # A namespace (string) within the package where assets are built.
    # This attribute value is also passed the node_modules such that
    # everything gets built in the same location.
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
                entrypoint = None,
                executable = None,
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
            visibility = visibility,
            **kwargs
        )

    node_modules(
        name = name + '_modules',
        target = name + '_files',
        deps = deps + [entrypoint],
        visibility = visibility,
    )

    _node_binary(
        name = name,
        target = name + '_files',
        entrypoint = entrypoint,
        executable = executable,
        node_modules = name + '_modules',
        node_args = node_args,
        visibility = visibility,
    )

    node_bundle(
        name = name + '_bundle',
        node_binary = name,
        extension = deploy,
        visibility = visibility,
    )


_node_test = rule(
    node_binary_impl,
    attrs = binary_attrs,
    test = True,
)


def node_test(name = None,
              main = None,
              entrypoint = None,
              executable = None,
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
