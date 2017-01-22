<table><tr>
<td><img src="https://github.com/pubref/rules_protobuf/blob/master/images/bazel.png" width="120"/></td>
<td><img src="https://node-os.com/images/nodejs.png" width="120"/></td>
</tr><tr>
<td>Bazel</td>
<td>NodeJs</td>
</tr></table>

# `rules_node` [![Build Status](https://travis-ci.org/pubref/rules_node.svg?branch=master)](https://travis-ci.org/pubref/rules_node)

Put `rules_node` in your `WORKSPACE` and load the main repository
dependencies.  This will download the nodejs toolchain including
`node` (6.6.x) and `npm`.

```python
git_repository(
    name = "org_pubref_rules_node",
    tag = "v0.3.1",
    remote = "https://github.com/pubref/rules_node.git",
)

load("@org_pubref_rules_node//node:rules.bzl", "node_repositories")

node_repositories()
```

# Rules

| Rule | Description |
| ---: | :---------- |
| [node_repositories](#node_repositories) | Install node toolchain. |
| [npm_repository](#npm_repository) | Install a set of npm dependencies. |
| [node_library](#node_library) | Define a local npm module. |
| [node_binary](#node_binary) | Build or execute a nodejs script. |
| [mocha_test](#mocha_test) |  Run a mocha test script. |


## node_repositories

WORKSPACE rule that downloads and configures the node toolchain.

## npm_repository

Install a set of npm dependencies into a `node_modules` folder as an
external workspace.  For example:

```python
# In WORKSPACE
load("@org_pubref_rules_node//node:rules.bzl", "npm_repository")

npm_repository(
    name = "npm_react_stack",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
    sha256 = "dedabd07bf8399ef5bd6032e87a3ea17eef08183d8766ccedaef63d7707283b6",
)
```

You can then refer to `@npm_react_stack//:modules` in the `modules`
attribute of a `node_binary` or `node_library` rule.

#### About the sha256 option

`sha256` is optional.  The expected value is the output of `sha256sum
node_modules.tar` (linux) or `shasum -a256 node_modules.tar` (osx),
where `node_modules.tar` is an archive file created from the aggregate
contents of the `node_modules` folder created by `npm install` (and
where (hopefully) all non-deterministic bits (timestamps, variable
data) have been stripped out).

There is no convenient way to determine this sha256 other than by
attempting to install it against a false value (for example: `sha256 =
"foo"`), at which point bazel will print the expected value.  You can
then copy-paste that output into your `WORKSPACE` file.

*This assumes you trust the network and the origin of the files* (only
you can determine this).  By setting a `sha256`, you can guard against
the code changing, but you are not guarding against a malicious
attacker sneaking in bogus code in the first place.

> Note: the `WORKSPACE` for `rules_node` itself is not yet using the
> sha256 option as there seems to be remaining non-determinism that
> renders it flaky.

#### What gets removed before determining the sha256?

In order to make npm deterministic it is necessary to:

1. Remove all file timestamps and user/group information from
   node_modules.

2. Make sure the keys in `package.json` are sorted.

3. Remove custom npm-related generated fields in `package.json` files
   that carry non-deterministic data.

If you find that the
[default list of blacklisted/excluded attributes](node/internal/npm_repository.bzl)
is either too aggressive or too lax, it can be configured via the
`exclude_package_json_keys` attribute.

## node_library

This rule accepts a list of `srcs` (`*.js`) and other configuration
attributes. When depended upon, it generates a `package.json` file
describing the module and the `npm install`'s it in a local
`node_modules` folder within `bazel-bin`.  The name of the module is
taken by munging the package label, substituting `/` (slash) with `-`
(dash). For example:

```python
load("//node:rules.bzl", "node_library")

node_library(
    name = "baz",
    main = "index.js",
    srcs = [
        "qux.js",
    ],
)
```

This will be installed as:

```sh
INFO: From NpmInstallLocal examples/baz/lib/node_modules/examples-baz/package.json:
/private/var/tmp/_bazel_user/178d7438552046b1be3cba61fe7b75a8/execroot/rules_node/bazel-out/local-fastbuild/bin/examples/baz/lib
`-- examples-baz@0.0.0
```

The local modules can be `require()`'d in another module as follows:

```js
var baz = require("examples-baz");
console.log('Hello, ' + baz());
```

This packaging/install cycle occurs on demand and is a nicer way to
develop nodejs applications with clear dependency requirements.  Bazel
makes this very clean and convenient.

## node_binary

Creates an executable script that will run the file named in the
`main` attribute.  Paths to dependent `node_library` and
`@npm_repository//:modules` labels are used to construct a `NODE_PATH`
environment variable that the `node` executable will use to fulfill
`require` dependencies.

```python
load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "foo",
    main = "foo.js",
    modules = [
        "@npm_react_stack//:modules",
    ],
)
```


## mocha_test

Runs a mocha test identified by the start script given in `main`.
External modules dependencies can be listed in the `modules`
attribute, while internal module dependencies are named in the `deps`
attribute.  Additional arguments to the `mocha` script runner can be
listed in the `mocha_args` attribute.

```python
load("@org_pubref_rules_node//node:rules.bzl", "mocha_test")

mocha_test(
    name = "foo_test",
    main = "foo_test.js",
    modules = [
        "@npm_underscore//:modules",
    ],
    deps = [
        "//examples/baz",
    ],
    mocha_args = [
        "--reporter=dot",
    ]
)
```
