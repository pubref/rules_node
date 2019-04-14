# The node_repository_impl is mostly taken from rules_nodejs :)
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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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
      default = "8.15.1",
    ),
    "linux_sha256": attr.string(
      default = "5643b54c583eebaa40c1623b16cba4e3955ff5dfdd44036f6bafd761160c993d",
    ),
    "darwin_sha256": attr.string(
      default = "aacdc9d5d8bbeaf47c398815147e052aac53cf19319f4c140c1798a82d419e65",
    ),
    "windows_sha256": attr.string(
      default = "f636fa578dc079bacc6c4bef13284ddb893c99f7640b96701c2690bd9c1431f5",
    ),
  },
)


def node_repositories(yarn_version="v1.15.2",
                      yarn_sha256="c4feca9ba5d6bf1e820e8828609d3de733edf0e4722d17ed7ce493ed39f61abd",
                      **kwargs):

    http_archive(
      name = "yarn",
      url = "https://github.com/yarnpkg/yarn/releases/download/{yarn_version}/yarn-{yarn_version}.tar.gz".format(
        yarn_version = yarn_version,
      ),
      sha256 = yarn_sha256,
      strip_prefix="yarn-%s" % yarn_version,
      build_file_content = YARN_BUILD_FILE_CONTENT,
    )

    # http_archive(
    #   name = "yarnpkg_lockfile",
    #   url = "https://registry.yarnpkg.com/@yarnpkg/lockfile/-/lockfile-1.1.1.tgz",
    #   sha256 = "472add7ad141c75811f93dca421e2b7456045504afacec814b0565f092156251",
    #   strip_prefix="package",
    #   build_file_content =  YARN_LOCKFILE_BUILD_FILE_CONTENT,
    # )

    _node_repository(
      name = "node",
      **kwargs
    )
