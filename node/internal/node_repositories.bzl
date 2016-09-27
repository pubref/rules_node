load("//node:internal/node_repository.bzl", "node_repository")

def node_repositories():

    node_repository(
        name = "nodejs_linux_amd64",
        version = "v6.6.0",
        arch = "linux-x64",
        sha256 = "",
        type = "tar.gz",
    )

    node_repository(
        name = "nodejs_darwin_amd64",
        version = "v6.6.0",
        arch = "darwin-x64",
        sha256 = "c8d1fe38eb794ca46aacf6c8e90676eec7a8aeec83b4b09f57ce503509e7a19f",
        type = "tar.gz",
    )
