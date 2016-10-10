_js_filetype = FileType([".js"])
_modules_filetype = FileType(["node_modules"])

def _get_node_modules_dir(file, include_node_modules = True):
    filename = str(file)
    parts = filename.split("]")
    prefix = parts[0][len("Artifact:[["):]
    middle = parts[1]
    suffix = parts[2].split("/")
    components = [prefix, middle] + suffix[0:-1]
    if include_node_modules:
        components.append("node_modules")
    d = "/".join(components)
    return d


def _get_lib_name(ctx):
    name = ctx.label.name
    parts = ctx.label.package.split("/")
    if (len(parts) == 0) or (name != parts[-1]):
        parts.append(name)
    if ctx.attr.use_prefix:
        parts.insert(0, ctx.attr.prefix)
    return "-".join(parts)


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


def node_library_impl(ctx):
    node = ctx.executable._node
    npm = ctx.executable._npm
    modules = ctx.attr.modules

    lib_name = _get_lib_name(ctx)
    stage_name = lib_name + ".npmfiles"

    srcs = ctx.files.srcs
    script = ctx.file.main
    if not script and len(srcs) > 0:
        script = srcs[0]

    package_json_template_file = ctx.file.package_json_template_file
    package_json_file = ctx.new_file(stage_name + "/package.json")
    npm_package_json_file = ctx.new_file("lib/node_modules/%s/package.json" % lib_name)

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

    ctx.template_action(
        template = package_json_template_file,
        output = package_json_file,
        substitutions = {
            "%{name}": lib_name,
            "%{main}": script.short_path if script else "",
            "%{version}": ctx.attr.version,
            "%{description}": ctx.attr.d,
        },
    )

    npm_prefix_parts = _get_node_modules_dir(package_json_file, False).split("/")
    npm_prefix = "/".join(npm_prefix_parts[0:-1])
    staging_dir = "/".join([npm_prefix, stage_name])

    cmds = []
    cmds += ["mkdir -p %s" % staging_dir]

    if script:
        cmds += _copy_to_namespace(staging_dir, script)
    for src in srcs:
        cmds += _copy_to_namespace(staging_dir, src)
    for file in files:
        cmds += _copy_to_namespace(staging_dir, file)

    install_cmd = [
        node.path,
        npm.path,
        "install",
        #"--verbose",
        "--global", # remember you need --global + --prefix
        "--prefix",
        npm_prefix,
    ]

    install_cmd.append(staging_dir)
    cmds.append(" ".join(install_cmd))

    #print("cmds: \n%s" % "\n".join(cmds))

    ctx.action(
        mnemonic = "NpmInstallLocal",
        inputs = [node, npm, package_json_file] + srcs,
        outputs = [npm_package_json_file],
        command = " && ".join(cmds),
    )

    return struct(
        files = set(srcs),
        runfiles = ctx.runfiles(
            files = srcs,
            collect_default = True,
        ),
        node_library = struct(
            name = lib_name,
            label = ctx.label,
            srcs = srcs,
            transitive_srcs = srcs + transitive_srcs,
            transitive_node_modules = ctx.files.modules + transitive_node_modules,
            package_json = npm_package_json_file,
            npm_package_json = npm_package_json_file,
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
        "_npm": attr.label(
            default = Label("@org_pubref_rules_node_toolchain//:npm_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
)
