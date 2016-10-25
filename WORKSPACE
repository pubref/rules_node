workspace(name = "org_pubref_rules_node")

load("//node:rules.bzl", "node_repositories", "npm_repository", "bower_repository", "node_modules")
node_repositories()

_YARN_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])
filegroup(
  name = "modules",
  srcs = ["node_modules"],
)
exports_files(["node_modules"])
exports_files(glob(["bin/*"]))
"""
new_http_archive(
    name = "com_github_yarnpkg_yarn",
    url = "https://github.com/yarnpkg/yarn/releases/download/v0.16.1/yarn-v0.16.1.tar.gz",
    sha256 = "73be27c34ef1dd4217fec23cdfb6b800cd995e9079d4c4764724ef98e98fec07",
    build_file_content = _YARN_BUILD_FILE,
    strip_prefix = "dist",
)

node_modules(
    name = "glob_modules",
    deps = {
        "glob": "7.1.0",
    },
)

node_modules(
    name = "npm_glob",
    deps = {
        "glob": "7.1.0",
    },
    #sha256 = "0d694720f9d942d334a45230fdf55ff20e4c78bff8adb67fba99d6d62e27df84",
)

node_modules(
    name = "npm_react_stack",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
    sha256 = "778536638ba37e08fe926acf282f16f1a2876d1aed2e70515fe2f6b484ca9e8e",
)

node_modules(
    name = "npm_mocha",
    deps = {
        "mocha": "3.1.0",
    },
    sha256 = "3cce1dd3917f9e115577f9f5a00dd03604218c044f5c7cc841d4a7592159343c",
)

node_modules(
    name = "npm_underscore",
    deps = {
        "underscore": "1.8.3",
    },
    sha256 = "8bae906fca9d192bc67bb51d8e22382aea8d86df609181b2d2f8b9bd2aed8864",
)

node_modules(
    name = "npm_bower",
    deps = {
        "bower": "1.7.9",
    },
    sha256 = "7f85a05c00a86b0f9cfd8d58ad61d0447bd9235d13a743ede87af1ca5509403f",
)

bower_repository(
    name = "bower_react_stack",
    deps = {
        "react": "15.3.2",
    },
    sha256 = "9779fcd247213b898d53473d4cc884f8b2d64b7d8021f56dd54a6dcd5f1bf845",
)
