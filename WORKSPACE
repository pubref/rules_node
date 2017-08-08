workspace(name = "org_pubref_rules_node")

load("//node:rules.bzl", "node_repositories", "npm_repository", "bower_repository", "yarn_repository", "node_modules")
node_repositories()

yarn_repository(
    name = "yarn_glob",
    deps = {
        "glob": "7.1.0",
    },
    sha256 = "15b4a5f09609affff1bc4338dd2d53653311f840d33fcf14d8cc47f40384d380",
)

yarn_repository(
    name = "yarn_fs_utils",
    deps = {
        "fs-extra": "3.0.1",
        "klaw": "1.3.1",
    },
    sha256 = "73bd930fcca8dac440281d300c6322b4e1507009bb32340fe2a4eb1511cb2b35",
)

yarn_repository(
    name = "yarn_webpack",
    deps = {
        "webpack": "2.6.1",
    },
    sha256 = "9479b8089d27438396ed88acb8aa00443ec17d7e574a599a7338ad2acaa67a16",
)

npm_repository(
    name = "npm_glob",
    deps = {
        "glob": "7.1.0",
    },
    #sha256 = "0d694720f9d942d334a45230fdf55ff20e4c78bff8adb67fba99d6d62e27df84",
)

node_modules(
    name = "node_fs_utils",
    package_json = "//example/ex1:package.json",
)

npm_repository(
    name = "npm_react_stack",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
    #sha256 = "fa7f0306841e8f03de78bd4b80f0da525238cf95cb360d7072013ca5fe7215e0",
)

npm_repository(
    name = "npm_mocha",
    deps = {
        "mocha": "3.1.0",
    },
    #sha256 = "9b48987065bb42003bab81b4538afa9ac194d217d8e2e770a5cba782249f7dc8",
)

npm_repository(
    name = "npm_underscore",
    deps = {
        "underscore": "1.8.3",
    },
    #sha256 = "7c413345ad4f97024258e5d9fda40e26be0f2c2b73987d13f03352b5c489b1a8",
)

npm_repository(
    name = "npm_bower",
    deps = {
        "bower": "1.7.9",
    },
    #sha256 = "7f85a05c00a86b0f9cfd8d58ad61d0447bd9235d13a743ede87af1ca5509403f",
)

bower_repository(
    name = "bower_react_stack",
    deps = {
        "react": "15.3.2",
    },
    #sha256 = "9779fcd247213b898d53473d4cc884f8b2d64b7d8021f56dd54a6dcd5f1bf845",
)
