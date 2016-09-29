_js_filetype = FileType([".js"])


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
    node = ctx.executable.node
    npm = ctx.executable.npm
    lib_name = _get_lib_name(ctx)
    stage_name = lib_name + ".npmfiles"

    srcs = ctx.files.srcs
    main = ctx.file.main_script
    if not main and len(srcs) > 0:
        main = srcs[0]

    package_json_template_file = ctx.file.package_json_template_file
    package_json_file = ctx.new_file(stage_name + "/package.json")
    npm_package_json_file = ctx.new_file("lib/node_modules/%s/package.json" % lib_name)

    transitive_srcs = []

    npm_deps = []
    transitive_npm_deps = {}

    files = []
    for d in ctx.attr.data:
        for file in d.files:
            files.append(file)

    for dep in ctx.attr.deps:
        lib = dep.node_library
        transitive_srcs += lib.transitive_srcs

    for dep in ctx.attr.npm_deps:
        npm_deps.append(dep)
        npm_lib = dep.npm_library
        transitive_npm_deps += npm_lib.deps

    #print("transitive_npm_deps: %s" % transitive_npm_deps)
    deps_entries = ['"%s": "%s"' % (k, v) for k, v in transitive_npm_deps.items()]
    deps_str = "{" + ",".join(deps_entries) + "}"

    #print("deps_str: %s" % deps_str)

    ctx.template_action(
        template = package_json_template_file,
        output = package_json_file,
        substitutions = {
            "%{name}": lib_name,
            "%{main}": main.short_path if main else "",
            "%{version}": ctx.attr.semver,
            "%{description}": ctx.attr.d,
            "%{dependencies}": deps_str,
        },
    )

    npm_prefix_parts = _get_node_modules_dir(package_json_file, False).split("/")
    npm_prefix = "/".join(npm_prefix_parts[0:-1])
    staging_dir = "/".join([npm_prefix, stage_name])

    cmds = []
    cmds += ["mkdir -p %s" % staging_dir]

    if main:
        cmds += _copy_to_namespace(staging_dir, main)
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

    if ctx.attr.registry:
        install_cmd.append("--registry")
        install_cmd.append(ctx.attr.registry.npm_registry.url)

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
            npm_deps = npm_deps,
            transitive_npm_deps = transitive_npm_deps,
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
        "semver": attr.string(
            default = "0.0.0",
        ),
        "main_script": attr.label(
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
        "npm_deps": attr.label_list(
            providers = ["npm_library"],
        ),
        "node": attr.label(
            default = Label("//node/toolchain:node_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "npm": attr.label(
            default = Label("//node/toolchain:npm_tool"),
            single_file = True,
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "registry": attr.label(
            single_file = True,
            allow_files = False,
            providers = ["npm_registry"],
        ),
        "package_json_template_file": attr.label(
            single_file = True,
            allow_files = True,
            default = Label("//node:package.json.tpl"),
        ),
        "prefix": attr.string(default = "workspace"),
        "use_prefix": attr.bool(default = False),
    },
)
