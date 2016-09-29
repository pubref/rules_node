<table><tr>
<td><img src="https://github.com/pubref/rules_protobuf/blob/master/images/bazel.png" width="120"/></td>
<td><img src="https://node-os.com/images/nodejs.png" width="120"/></td>
<td><img src="https://www.npmjs.com/static/images/npm-logo.svg" width="120"/></td>
</tr><tr>
<td>Bazel</td>
<td>NodeJs</td>
<td>npm</td>
</tr></table>

# `rules_node` [![Build Status](https://travis-ci.org/pubref/rules_node.svg?branch=master)](https://travis-ci.org/pubref/rules_node)

Put `rules_node` in your `WORKSPACE` and load the main repository
dependencies.  This will download the nodejs toolchain including
`node` (6.6.x) and `npm`.

```python
git_repository(
    name = "org_pubref_rules_node",
    tag = "v0.1.0",
    remote = "https://github.com/pubref/rules_node.git",
)

load("@org_pubref_rules_node//node:rules.bzl", "node_repositories")

node_repositories()
```

# Rules

| Rule | Description |
| ---: | :---------- |
| [node_repositories](#node_repositories) | Install node toolchain. |
| [npm_library](#npm_library) | Declare an external npm dependency. |
| [node_library](#node_library) | Define a local npm module. |
| [node_binary](#node_binary) | Build or execute a nodejs script. |

# Example

```python
load("@org_pubref_rules_node//node:rules.bzl", "node_binary", "npm_library")

npm_library(
    name = "glob",
)

npm_library(
    name = "react-stack",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
)

node_binary(
    name = "foo",
    main_script = "foo.js",
    npm_deps = ["glob", "react-stack"],
)
```

## node_repositories

WORKSPACE rule.  No current options.

## npm_library

Declares a set of npm dependencies.  Functionally equivalent to `npm
install ...`.

Takes two forms:

1. **Single import**: uses the name of the rule (see `glob` above).

1. **Multiple import**: uses a string_dict declaring the
   `name@version` dependency. (see `react-stack` above).

## node_library

This rule accepts a list of `srcs` (`*.js`) and other configuration
attributes. When depended upon, it generates a `package.json` file
describing the module and the `npm install`'s it in a local
`node_modules` folder.  The name of the module is the package label,
substituting `/` (slash) with `-` (dash). For example:

```python
load("//node:rules.bzl", "node_library")

node_library(
    name = "baz",
    main_script = "index.js",
    srcs = [
        "qux.js"
    ],
    npm_deps = ["glob"],
    use_prefix = False,
)
```

Is installed as:

```sh
INFO: From NpmInstallLocal examples/baz/lib/node_modules/examples-baz/package.json:
/private/var/tmp/_bazel_user/178d7438552046b1be3cba61fe7b75a8/execroot/rules_node/bazel-out/local-fastbuild/bin/examples/baz/lib
`-- examples-baz@0.0.0
  `-- glob@7.1.0
    +-- fs.realpath@1.0.0
    +-- inflight@1.0.5
    | `-- wrappy@1.0.2
    +-- inherits@2.0.3
    +-- minimatch@3.0.3
    | `-- brace-expansion@1.1.6
    |   +-- balanced-match@0.4.2
    |   `-- concat-map@0.0.1
    +-- once@1.4.0
    `-- path-is-absolute@1.0.0
```

And can be `require()`'d in another module as follows:

```js
var baz = require("examples-baz");
console.log('Hello, ' + baz());
```

This packaging/install cycle occurs on demand and is a nicer way to
develop nodejs applications with clear dependency requirements.  Bazel
makes this very clean and convenient.

## node_binary

Creates an executable script that will run the file named in the
`main_script` attribute.  Paths to dependent `node_library` and
`npm_library` rules (each one having a `node_modules` subdirectory)
are used to construct a `NODE_PATH` environment variable that the
`node` executable will use to fulfill `require` dependencies.

---

> **WARNING**: these rules are not hermetic (or by that measure,
> secure)!  It trusts that the `npm install` command does what is it
> supposed to do, and there is no current support for validating that
> a particular npm package(s) matches a sha256 (this is the the norm
> for npm, but it's sub-standard for bazel).
