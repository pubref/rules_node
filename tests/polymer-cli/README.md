# Polymer CLI Example

This folder demonstrates that the generated `BUILD` file for
`@yarn_modules` contains a `node_binary` rule for the polymer-cli module
executable.  It tests that the target is callable and that the help
message is output.

Polymer CLI is a fairly complex dependency that contains @-scoped dependencies
and complex cyclic dependencies.

```sh
# Should be able to run polymer-cli directly
$ bazel build @yarn_modules//:polymer-cli_polymer_bin -- --help

# Should be able to invoke polymer-cli as standalone script 
$ ./bazel-bin/external/yarn_modules/polymer-cli_polymer_bin --help
```

> NOTE: currently this example is not working.  When invoked,
> polymer-cli_polymer_bin fails due to a missing module dependency `cycle`.  It
> is currently unclear why 'cycle' is being included but not linked in the
> dependency tree.