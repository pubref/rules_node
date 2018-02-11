# Ref Example

This example demonstrates the `install_tools` option.

In this case, `yarn install` of the `ref` package triggers `node-gyp`,
which in this case uses tools in `/bin` and `/usr/bin`.  We normally
take these for granted as being on the path but bazel runs the yarn
install script in the bare environment, so we need to specify these
explicitly to build up the appropriate `PATH`.
