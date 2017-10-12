# Webpack Example

This folder demonstrates that the generated `BUILD` file for
`@yarn_modules` contains a `node_binary` rule for the webpack module
executable.  It tests that the target is callable and that the help
message is output.

Webpack is a fairly complex dependency that contains a cycle in
`es5-ext`, `es6-iterator`, `es6-symbol`, `d` dependency cluster.  It
breaks this strongly connected component into a separate pseudo
`node_module`.
