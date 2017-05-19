_js_filetype = FileType([".js"])
_modules_filetype = FileType(["node_modules"])


def _copy_to_namespace(base, file):
    steps = []
    src = file.path
    dst = file.basename
    short_parts = file.short_path.split('/')
    if short_parts:
        dst_dir = "/".join(short_parts[0:-1])
        dst = dst_dir + "/" + dst
        steps.append("mkdir -p %s/%s" % (base, dst_dir))
    steps.append("cp -f %s %s/%s" % (src, base, dst))
    return steps


def node_library_impl2(ctx):
    node = ctx.executable._node
    modules = ctx.attr.modules

    staging_dir = "%s/%s.dir" % (ctx.label.package, ctx.label.name)

    srcs = ctx.files.srcs
    script = ctx.file.main
    if not script and len(srcs) > 0:
        script = srcs[0]

    package_json_file = ctx.new_file("%s/package.json" % staging_dir)
    package_manifest_file = ctx.new_file("package.manifest")

    transitive_srcs = []
    transitive_node_modules = []

    files = []
    for d in ctx.attr.data:
        for file in d.files:
            files.append(file)

    for dep in ctx.attr.deps:
        lib = dep.node_library
        transitive_srcs += lib.transitive_srcs
        transitive_node_modules += lib.transitive_node_modules

    # Inputs to prepare the staging directory
    inputs = []

    cmds = []
    cmds += ["pwd"]
    cmds += ["mkdir foo"]
    cmds += ["mkdir -p %s" % staging_dir]
    cmds += ["ls -al ."]
    cmds += ["find ."]
    cmds += ["touch %s" % package_manifest_file.short_path]

    if script:
        cmds += _copy_to_namespace(staging_dir, script)
    for src in srcs:
        cmds += _copy_to_namespace(staging_dir, src)
    for file in files:
        cmds += _copy_to_namespace(staging_dir, file)
    for filegroup in modules:
        print("module %r" % filegroup.label.workspace_root)
        cmds += ["ln -s %s/node_modules/* %s/node_modules" % (filegroup.label.workspace_root, ctx.label.package)]

    print("cmds: \n%s" % "\n".join(cmds))

    ctx.action(
        mnemonic = "NodeLibraryManifest",
        inputs = srcs + [script] + files,
        outputs = [package_manifest_file],
        command = " && ".join(cmds),
    )


    package = struct(
        name = ctx.label.name,
        main = script.short_path if script else "",
        version = ctx.attr.version,
        description = ctx.attr.d,
    )

    ctx.file_action(package_json_file, package.to_json())

    return struct(
        files = set(srcs + [package_manifest_file, package_json_file]),
        runfiles = ctx.runfiles(
            files = srcs,
            collect_default = True,
        ),
        node_library = struct(
            name = package.name,
            label = ctx.label,
            srcs = srcs,
            transitive_srcs = srcs + transitive_srcs,
            transitive_node_modules = ctx.files.modules + transitive_node_modules,
            package_json = package_json_file,
        ),
    )


def node_library_impl(ctx):
    node = ctx.executable._node
    modules = ctx.attr.modules

    # What is the goal here?  All you want to do is create a node_module, no?
    staging_dir = "%s/%s.dir" % (ctx.label.package, ctx.label.name)

    script = ctx.file.main

    package_json_file = ctx.new_file("%s/package.json" % staging_dir)
    package_manifest_file = ctx.new_file("package.manifest")

    transitive_srcs = []
    transitive_node_modules = []

    files = []
    for d in ctx.attr.data:
        for file in d.files:
            files.append(file)

    for dep in ctx.attr.deps:
        lib = dep.node_library
        transitive_srcs += lib.transitive_srcs
        transitive_node_modules += lib.transitive_node_modules

    # Inputs to prepare the staging directory
    inputs = []

    cmds = []
    cmds += ["pwd"]
    cmds += ["mkdir foo"]
    cmds += ["mkdir -p %s" % staging_dir]
    cmds += ["ls -al ."]
    cmds += ["find ."]
    cmds += ["touch %s" % package_manifest_file.short_path]

    srcs = []
    if script:
        cmds += _copy_to_namespace(staging_dir, script)
    for src in srcs:
        cmds += _copy_to_namespace(staging_dir, src)
    for file in files:
        cmds += _copy_to_namespace(staging_dir, file)
    for filegroup in modules:
        print("module %r" % filegroup.label.workspace_root)
        cmds += ["ln -s %s/node_modules/* %s/node_modules" % (filegroup.label.workspace_root, ctx.label.package)]

    print("cmds: \n%s" % "\n".join(cmds))

    ctx.action(
        mnemonic = "NodeLibraryManifest",
        inputs = srcs + [script] + files,
        outputs = [package_manifest_file],
        command = " && ".join(cmds),
    )

    package = struct(
        name = ctx.label.name,
        main = script.short_path if script else "",
        version = ctx.attr.version,
        description = ctx.attr.d,
    )

    ctx.file_action(package_json_file, package.to_json())

    return struct(
        files = set(srcs + [package_manifest_file, package_json_file]),
        runfiles = ctx.runfiles(
            files = srcs,
            collect_default = True,
        ),
        node_library = struct(
            name = package.name,
            label = ctx.label,
            srcs = srcs,
            transitive_srcs = srcs + transitive_srcs,
            transitive_node_modules = ctx.files.modules + transitive_node_modules,
            package_json = package_json_file,
        ),
    )

node_library = rule(
    node_library_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = _js_filetype,
        ),
        "version": attr.string(
            default = "0.0.0",
        ),
        "main": attr.label(
            mandatory = False,
            single_file = True,
            allow_files = _js_filetype,
        ),
        "d": attr.string(
            default = "No description provided.",
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
        "package_json_template_file": attr.label(
            single_file = True,
            allow_files = True,
            default = Label("//node:package.json.tpl"),
        ),
        "prefix": attr.string(default = "workspace"),
        "use_prefix": attr.bool(default = False),
        "_node": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
)
