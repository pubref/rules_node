_node_filetype = FileType([".js", ".node"])

def _relname(ctx, root_file, file):
    #print("getting relative name for %s rel %s" % (file.path, root_file.path))
    # If file is in the workspace root, just return the name
    if file.dirname == ".":
        return file.short_path
    parts = file.path.partition(root_file.dirname)
    # If the file.path does not contain root_file.dirname, try the
    # label.package...
    if not len(parts[2]):
        # However, if the label.package is empty, file is in the
        # workspace root (so just use the basename)
        if not ctx.label.package:
            return file.basename
        parts = file.path.partition(ctx.label.package)
    if not len(parts[2]):
        print("failed relative name for %s rel %s" % (file.path, root_file.path))
    return parts[2]


def _get_package_dependencies(module_deps):
    dependencies = {}
    for dep in module_deps:
        module = dep.node_module
        dependencies[module.name] = module.version
    return struct(**dependencies)


def _get_module_name(ctx):
    parts = []
    # namespace attribute takes precedence...
    if ctx.attr.namespace:
        parts.append(ctx.attr.namespace)
    # else use the package name, but only if non-empty
    elif ctx.label.package:
        parts += ctx.label.package.split("/")
    # finally, use the module_name or label name
    parts.append(ctx.attr.module_name or ctx.label.name)
    return ctx.attr.separator.join(parts)


def _create_package_json(ctx, name, files, executables):
    output_file = ctx.new_file("%s/package.json" % name)

    json = {
        "name": name,
        "version": ctx.attr.version,
        "description": ctx.attr.description,
        "url": ctx.attr.url,
        "sha1": ctx.attr.sha1,
    }

    if len(files) > 0:
        json["files"] = depset([_get_path_for_module_file(ctx, output_file, file, {}) for file in files]).to_list()

    if executables:
        json["bin"] = executables
        
    if ctx.attr.main:
        json["main"] = ctx.file.main.basename


    # Add dependencies if they exist
    if (ctx.attr.deps):
        json["dependencies"] = _get_package_dependencies(ctx.attr.deps)
    if (ctx.attr.dev_deps):
        json["devDependencies"] = _get_package_dependencies(ctx.attr.dev_deps)

    content = struct(**json)

    ctx.file_action(
        output = output_file,
        content = content.to_json(),
    )

    return output_file


def _get_transitive_modules(deps, key):
    modules = depset()
    for dep in deps:
        module = dep.node_module
        modules += [module]
        modules += getattr(module, key, [])
    return modules


def _get_path_for_module_file(ctx, root_file, file, sourcemap):
    """Compute relative output path for file relative to root_file Return
    the return ad as side-effect store the mapping of file.path -->
    relative_path in the given sourcemap dict.
    """

    path = None
    if ctx.attr.layout == 'relative':
        path = _relname(ctx, root_file, file)
    elif ctx.attr.layout == 'workspace':
        path = file.short_path
    elif ctx.attr.layout == 'flat':
        path = file.basename
    else:
        fail("Unexpected layout: " + ctx.attr.layout)
    sourcemap[file.path] = path
    return path


def _copy_file(ctx, src, dst):
    ctx.action(
        mnemonic = "CopyFileToNodeModule",
        inputs = [src],
        outputs = [dst],
        command = "cp '%s' '%s'" % (src.path, dst.path),
    )
    return dst


def _node_module_impl(ctx):
    name = _get_module_name(ctx)
    outputs = []

    files = [] + ctx.files.srcs
    if ctx.file.main:
        files.append(ctx.file.main)

    executables = ctx.attr.executables
        
    package_json = ctx.file.package_json

    # The presence of an index file suppresses creation of the
    # package.json file, if not already provided and no 'main' file is
    # provided.
    if len(files) > 0 and not package_json:
        if ctx.attr.main or not ctx.file.index:
            package_json = _create_package_json(ctx, name, files, executables)
    if package_json:
        outputs.append(package_json)

    root_file = package_json or ctx.file.index
    if len(files) > 0 and not root_file:
        fail("A module with source files must be created from (1) a package.json file, (2) a 'main' file, or (3) an 'index' file.  None of these were present.")

    index_file = None
    if ctx.file.index:
        dst = ctx.new_file("%s/index.%s" % (name, ctx.file.index.extension))
        outputs.append(_copy_file(ctx, ctx.file.index, dst))
        index_file = dst

    sourcemap = {}
    for src in files:
        dst = ctx.new_file("%s/%s" % (name, _get_path_for_module_file(ctx, root_file, src, sourcemap)))
        outputs.append(_copy_file(ctx, src, dst))

    return struct(
        files = depset(outputs),
        node_module = struct(
            identifier = name.replace(ctx.attr.separator, '_'),
            name = name,
            version = ctx.attr.version,
            url = ctx.attr.url,
            sha1 = ctx.attr.sha1,
            description = ctx.attr.description,
            executables = executables,
            package_json = package_json,
            root = root_file,
            sourcemap = sourcemap,
            index = index_file,
            files = depset(outputs),
            sources = depset(files),
            transitive_deps = _get_transitive_modules(ctx.attr.deps, "transitive_deps"),
            transitive_dev_deps = _get_transitive_modules(ctx.attr.dev_deps, "transitive_dev_deps"),
        ),
    )


node_module = rule(
    implementation = _node_module_impl,
    attrs = {
        # An organizational prefix for the module, for example
        # '@types' in '@types/node'.
        "namespace": attr.string(
        ),

        # A string that, if present, will be used for the module name.
        # If absent, defaults the the ctx.label.name.
        "module_name": attr.string(
        ),

        # separator used to create the scoped module name.  For
        # example, if you have a node_module rule 'fs-super' in
        # src/main/js with separator '-' (the default), the module
        # name will be 'src-main-js-fs-super' UNLESS you specify a
        # namespace '@bazel', in which case it becomes
        # '@bazel/fs-super'.
        "separator": attr.string(
            default = "/",
        ),

        # A string that determines how files are placed within the
        # module.  With 'flat', all files are copied into the root of
        # the module using File.basename.  With 'relative', files are
        # copied into the module relative to the BUILD file containing
        # the node_module rule (this is the default).  With
        # 'workspace', files are copied into the module using
        # File.short_path, causing them to be relative to the
        # WORKSPACE.
        "layout": attr.string(
            values = ["relative", "workspace"],
            default = "relative",
        ),

        # A set of source files to include in the module.
        "srcs": attr.label_list(
            allow_files = True,
        ),

        # A file that will be used for the package.json at the root of
        # the module.  If not present, one will be generated UNLESS an
        # index file is provided.
        "package_json": attr.label(
            allow_files = FileType(["package.json"]),
            single_file = True,
        ),

        # Additional data files to be included in the module, but
        # excluded from the package.json 'files' attribute.
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),

        # Module dependencies.
        "deps": attr.label_list(
            providers = ["node_module"],
        ),

        # Development-only module dependencies.
        "dev_deps": attr.label_list(
            providers = ["node_module"],
        ),

        # 'Binary' scripts, to be named in the 'package_json.bin' property.
        # This uses the plain 'string_dict' attribute since bazel does not
        # have the more intuitive 'string_keyed_label_dict'-type attribute.
        "executables": attr.string_dict(
        ),

        # Module version
        "version": attr.string(
            default = "1.0.0",
        ),

        # Module URL (location where the modeule was originally loaded
        # from)
        "url": attr.string(
        ),

        # Sha1 hash for the tgz that it was loaded from.
        "sha1": attr.string(
        ),

        # Package description.
        "description": attr.string(
            default = "No description provided",
        ),

        # File that should be named as the package.json 'main'
        # attribute.
        "main": attr.label(
            allow_files = True,
            mandatory = False,
            single_file = True,
        ),

        # File that should be copied to the module root as 'index.js'.
        # If the index file is present and no 'main' is provided, a
        # package.json file will not be generated.
        "index": attr.label(
            allow_files = _node_filetype,
            single_file = True,
        ),
    },
)
