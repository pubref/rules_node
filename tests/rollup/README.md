# Rollup Example

This test verifies that `NODE_PATH` is set to the node_modules directory while executing `node_binary` rules. The test uses a [rollup configuration file](https://rollupjs.org/guide/en#configuration-files) supplied to a genrule that includes `node_module` depenendencies supplied to a `node_binary` target.

```
$ bazel test :test
```

