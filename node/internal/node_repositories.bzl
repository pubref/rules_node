# The node_repository_impl taken from Alex Eagle's rules_nodejs :)
#
# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Install NodeJS when the user runs node_repositories() from their WORKSPACE.

We fetch a specific version of Node, to ensure builds are hermetic.
We then create a repository @nodejs which provides the
node binary to other rules.
"""

YARN_BUILD_FILE_CONTENT = """
package(default_visibility = [ "//visibility:public" ])
exports_files([
  "bin/yarn",
  "bin/yarn.js",
])
"""

YARN_LOCKFILE_BUILD_FILE_CONTENT = """
package(default_visibility = [ "//visibility:public" ])
exports_files([
  "index.js",
])
"""

NODE_BUILD_FILE_CONTENT = """
package(default_visibility = ["//visibility:public"])
exports_files([
  "{0}",
  "{1}",
])
alias(name = "node", actual = "{0}")
alias(name = "npm", actual = "{1}")
"""


def _node_repository_impl(repository_ctx):
  version = repository_ctx.attr.node_version
  sha256 = repository_ctx.attr.linux_sha256
  arch = "linux-x64"
  node = "bin/node"
  npm = "bin/npm"
  compression_format = "tar.xz"

  os_name = repository_ctx.os.name.lower()
  if os_name.startswith("mac os"):
    arch = "darwin-x64"
    sha256 = repository_ctx.attr.darwin_sha256
  elif os_name.find("windows") != -1:
    arch = "win-x64"
    node = "node.exe"
    npm = "npm.cmd"
    compression_format = "zip"
    sha256 = repository_ctx.attr.windows_sha256

  prefix = "node-v%s-%s" % (version, arch)
  url = "https://nodejs.org/dist/v{version}/{prefix}.{compression_format}".format(
    version = version,
    prefix = prefix,
    compression_format = compression_format,
  )

  repository_ctx.download_and_extract(
    url = url,
    stripPrefix = prefix,
    sha256 = sha256,
  )

  repository_ctx.file("BUILD.bazel", content = NODE_BUILD_FILE_CONTENT.format(node, npm))


_node_repository = repository_rule(
  _node_repository_impl,
  attrs = {
    "node_version": attr.string(
      default = "7.10.1",
    ),
    "linux_sha256": attr.string(
      default = "7b0e9d1af945671a0365a64ee58a2b0d72b3632a1cebe6b5bd75094b93627bf3",
    ),
    "darwin_sha256": attr.string(
      default = "d67d2eb9456aab925416ad58aa18b9680e66a4bcc243a89b22e646f7fffc4ff9",
    ),
    "windows_sha256": attr.string(
      default = "617590f06f9a0266ceecb3fd17120fc2fbf8669980974f339a83f3b56ed05f7b",
    ),
  },
)


def node_repositories(yarn_version="v1.0.1",
                      yarn_sha256="6b00b5e0a7074a512d39d2d91ba6262dde911d452617939ca4be4a700dd77cf1",
                      **kwargs):

    native.new_http_archive(
      name = "yarn",
      url = "https://github.com/yarnpkg/yarn/releases/download/{yarn_version}/yarn-{yarn_version}.tar.gz".format(
        yarn_version = yarn_version,
      ),
      sha256 = yarn_sha256,
      strip_prefix="yarn-%s" % yarn_version,
      build_file_content = YARN_BUILD_FILE_CONTENT,
    )

    native.new_http_archive(
      name = "yarnpkg_lockfile",
      url = "https://registry.yarnpkg.com/@yarnpkg/lockfile/-/lockfile-1.0.0.tgz",
      sha256 = "472add7ad141c75811f93dca421e2b7456045504afacec814b0565f092156250",
      strip_prefix="package",
      build_file_content =  YARN_LOCKFILE_BUILD_FILE_CONTENT,
    )

    _node_repository(
      name = "node",
      **kwargs
    )
