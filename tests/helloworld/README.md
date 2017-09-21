# Helloworld Example

This folder demonstrates the simplest use of node_binary.  To run the
example:

```sh
$ bazel run //:helloworld
```

Here are the available targets (with brief explanation):

```sh
$ bazel query //:*
//:helloworld_deploy.tgz # compressed archive file with node, script, and node_modules/**/*
//:helloworld_deploy     # rule that builds a compressed archive from all the files
//:helloworld_files      # rule that exposes all the files from a node_binary target
//:helloworld            # node_binary rule that builds a node_modules tree and writes a
                         # bash script that executes 'node node_modules/helloworld_module'
//:helloworld_module     # rule that builds a node_module using 'helloworld.js' as package.json main
//:helloworld.js         # javascript source file
```
