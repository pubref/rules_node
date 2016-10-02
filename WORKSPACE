workspace(name = "org_pubref_rules_node")

load("//node:rules.bzl", "node_repositories", "npm_repository")
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
