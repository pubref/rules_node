workspace(name = "org_pubref_rules_node")

load("//node:rules.bzl", "node_repositories", "npm_repository", "bower_repository")
node_repositories()

npm_repository(
    name = "npm_glob",
    deps = {
        "glob": "7.1.0",
    },
    sha256 = "0d694720f9d942d334a45230fdf55ff20e4c78bff8adb67fba99d6d62e27df84",
)

npm_repository(
    name = "npm_react_stack",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
    sha256 = "dedabd07bf8399ef5bd6032e87a3ea17eef08183d8766ccedaef63d7707283b6",
)

npm_repository(
    name = "npm_webpack",
    deps = {
        "webpack": "1.13.2",
    },
    sha256 = "705fac8595a57368185ac25f0a54bac475f4646285b4bc4af650ae754ac56e2b",
)

npm_repository(
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
