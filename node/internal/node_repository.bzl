NODE_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])

alias(
    name = "node_tool",
    actual = "//:bin/node",
)

alias(
    name = "npm_tool",
    actual = "//:bin/npm",
)

NODE_ROOT = '%s'
"""

def _node_repository_impl(ctx):
    version = ctx.attr.version
    arch = ctx.attr.arch
    sha256 = ctx.attr.sha256
    archive_type = ctx.attr.type

    url = "https://nodejs.org/dist/{version}/node-{version}-{arch}.{type}".format(
        version = version,
        arch = arch,
        type = archive_type)

    stripPrefix = "node-{version}-{arch}".format(
        version = version,
        arch = arch)

    ctx.download_and_extract(
        url,
        "",
        sha256,
        "",
        stripPrefix,
    )

    ctx.file("BUILD", NODE_BUILD_FILE % ctx.path("."))


node_repository = repository_rule(
    implementation = _node_repository_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "arch": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "type": attr.string(
            default = "tar.gz",
        ),
    }
)
