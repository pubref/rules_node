load("//node:internal/node_repository.bzl", "node_repository")

NODE_TOOLCHAIN_BUILD_FILE = """
package(default_visibility = [ "//visibility:public" ])
exports_files([
  "bin/node",
  "bin/npm",
])
filegroup(
  name = "node_tool",
  srcs = [ "bin/node" ],
)
filegroup(
  name = "npm_tool",
  srcs = [ "bin/npm" ],
)
"""

def _node_toolchain_impl(ctx):
  os = ctx.os.name
  if os == 'linux':
    noderoot = ctx.path(ctx.attr._linux).dirname
  elif os == 'mac os x':
    noderoot = ctx.path(ctx.attr._darwin).dirname
  else:
    fail("Unsupported operating system: " + os)

  ctx.symlink(noderoot, ctx.path(''))
  ctx.file("WORKSPACE", "workspace(name = '%s')" % ctx.name)
  ctx.file("BUILD", NODE_TOOLCHAIN_BUILD_FILE)

_node_toolchain = repository_rule(
    _node_toolchain_impl,
    attrs = {
        "_linux": attr.label(
            default = Label("@nodejs_linux_amd64//:BUILD"),
            allow_files = True,
            single_file = True,
        ),
        "_darwin": attr.label(
            default = Label("@nodejs_darwin_amd64//:BUILD"),
            allow_files = True,
            single_file = True,
        ),
    },
)

def node_repositories():

    native.new_http_archive(
        name = "nodejs_linux_amd64",
        url = "https://nodejs.org/dist/v6.6.0/node-v6.6.0-linux-x64.tar.gz",
        type = "tar.gz",
        strip_prefix = "node-v6.6.0-linux-x64",
        sha256 = "c22ab0dfa9d0b8d9de02ef7c0d860298a5d1bf6cae7413fb18b99e8a3d25648a",
        build_file_content = "",
    )

    native.new_http_archive(
        name = "nodejs_darwin_amd64",
        url = "https://nodejs.org/dist/v6.6.0/node-v6.6.0-darwin-x64.tar.gz",
        type = "tar.gz",
        strip_prefix = "node-v6.6.0-darwin-x64",
        sha256 = "c8d1fe38eb794ca46aacf6c8e90676eec7a8aeec83b4b09f57ce503509e7a19f",
        build_file_content = "",
    )

    _node_toolchain(
        name = "org_pubref_rules_node_toolchain",
    )
