<table><tr>
<td><img src="https://bazel.build/images/bazel-icon.svg" height="120"/></td>
<td><img src="https://nodejs.org/static/images/logo.svg" height="120"/></td>
<td><img src="https://yarnpkg.com/assets/feature-speed.png" height="120"/></td>
</tr><tr>
<td>Bazel</td>
<td>NodeJs</td>
<td>Yarn</td>
</tr></table>

# `rules_node` [![Build Status](https://cirrus-ci.com/github/pubref/rules_node.svg?branch=master)](https://cirrus-ci.com/github/pubref/rules_node) [![Build Status](https://travis-ci.org/pubref/rules_node.svg?branch=master)](https://travis-ci.org/pubref/rules_node)

# Rules

| Rule | Description |
| ---: | :---------- |
| [node_repositories](#node_repositories) | Install node toolchain. |
| [yarn_modules](#yarn_modules) | Install a set node module dependencies using yarn. |
| [node_module](#node_module) | Define a node module from a set of source files (having an optional main (or index) entry point). |
| [node_binary](#node_binary) | Run a node module. |
| [node_test](#node_test) | Run a node binary as a bazel test. |
| [mocha_test](#mocha_test) | Run a mocha test script. |

<table><tr>
<td><img src="https://www.kernel.org/theme/images/logos/tux.png" height="48"/></td>
<td><img src="https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg" height="48"/></td>
<td><img src="https://upload.wikimedia.org/wikipedia/commons/5/5f/Windows_logo_-_2012.svg" height="48"/></td>
</tr></table>

## node_repositories

WORKSPACE rule that downloads and configures node based on your
operating system.  Includes `node` (7.10.1) and `yarn` (1.0.1).

```python
RULES_NODE_COMMIT = '...' # Update to current HEAD
RULES_NODE_SHA256 = '...'

http_archive(
    name = "org_pubref_rules_node",
    url = "https://github.com/pubref/rules_node/archive/%s.zip" % RULES_NODE_COMMIT,
    strip_prefix = "rules_node-%s" % RULES_NODE_COMMIT,
    sha256 = RULES_NODE_SHA256,
)

load("@org_pubref_rules_node//node:rules.bzl", "node_repositories")

node_repositories()
```

## yarn_modules

Install a set of module dependencies into a `yarn_modules` folder as
an external workspace.  Requires either a `package.json` file or
`deps` as input.

```python
# In WORKSPACE
load("@org_pubref_rules_node//node:rules.bzl", "yarn_modules")

# Use a package.json file as input. Location of the package json
# is arbitrary.
yarn_modules(
    name = "yarn_modules",
    package_json = "//:package.json",
)

# Shortcut form without a separate package.json file
yarn_modules(
    name = "yarn_modules",
    deps = {
        "react": "15.3.2",
        "react-dom": "15.3.2",
    },
)
```

How It Works:

1. Create an external workspace `@yarn_modules` at `$(bazel info
output_base)/external/yarn_modules`.
2. Invoke `yarn install` to create a `node_modules` folder and
populate it with the necessary dependencies.

3. Read the generated `yarn.lock` file, parse it, and write out a
   `@yarn_modules//:BUILD` file.  This file contains a `node_module`
   rule foreach entry in the `yarn.lock` file, a `node_module` rule
   with the special name `_all_`, and a `node_binary` rule foreach
   executable script in the `node_modules/.bin` folder.

> Note 1: You can inspect all the targets by running `bazel query @yarn_modules//:*`.

> Note 2: The workspace name `yarn_modules` is arbitrary, choose
whatever you like (*other than* `node_modules` itself, that one
doesn't work).

At this point you can use these rule targets as `deps` for your
`node_module` rules.  *Example*:

```python
node_module(
    name = "my_module",
    package_json = "package.json",
    srcs = glob(["**/*.js"]),
    deps = [
        "@yarn_modules//:_all_",
    ],
)
```

### yarn_module attributes

| | Type | Name | Description |
| --- | --- | --- | --- |
| optional | `label` | `package_json` | A `package.json` file containing the dependencies that should be installed. |
| optional | `string_dict` | `deps` | A mapping of `name` --> `version` for the dependencies that should be installed. |

> Either `package_json` or `deps` must be present, but not both.

## node_module

BUILD file rule that creates a folder which conforms to the nodejs
[Folders as Modules](https://nodejs.org/api/modules.html#modules_folders_as_modules)
packaging structure.  *Example*:

```python
node_module(
    name = "my_module",
    main = "index.js",
    srcs = [
        "lib/util.js",
        "lib/math.js",
    ],
    version = "1.2.0",
    description = "Example node module",
    deps = [
        "@yarn_modules//:lodash",
        "@yarn_modules//:fs-extra",
    ],
```

When used in a `node_binary` rule, this ultimately materializes to:

```
node_modules/my_module
node_modules/my_module/package.json
node_modules/my_module/index.js
node_modules/my_module/lib/util.js
node_modules/my_module/lib/math.js
node_modules/lodash
node_modules/fs-extra
```

When used by other `node_module` rules, you can import the module as:

```javascript
const myModule = require("my_module");
```

There are three basic ways to create a `node_module` rule:

### 1. Creating a `node_module` with a `package.json` file

```python
node_module(
    name = "my_module_1",
    package_json = "package.json", # label to the 'package.json' file to use directly
)
```

In this scenario, assumes the package.json file has an entry that
specifies the `main` entrypoint (or not, if you follow the
[Files as Modules](https://nodejs.org/api/modules.html#modules_file_modules)
pattern).

### 2. Creating a `node_module` with a label to the `main` entrypoint source file

```python
node_module(
    name = "my_module_2",
    main = "app.js", # label to the entrypoint file for the module
    version = "1.0.0", # optional arguments to populate the generated package.json file
    ...
)
```

In this scenario, a `package.json` file will be generated for the
module that specifies the file you provide to the `main` attribute.

### 3. Creating a `node_module` with a label to the `index.js` entrypoint source file

```python
node_module(
    name = "my_module_3",
    index = "index.js", # label to the 'index.js' file to use as the index
)
```

> In this scenario, no `package.json` file is generated.

### Module dependencies

Build up a dependency tree via the `deps` attribute:

```
node_module(
    name = "my_module_3",
    ...
    deps = [
        "@yarn_modules//:_all_", # special token '_all_' to have access to all modules
        ":my_module_1",
    ],
)
```

### Core node_module attributes

|  | Type | Name | Default | Description |
| ---: | :--- | :--- | :--- | :--- |
| optional | `label` | `package_json` | `None` | Explicitly name a `package.json` file to use for the module.
| optional | `label` | `main` | `None` | Source file named in the generated package.json `main` property.
| optional | `label` | `index` | `None` | Source file to be used as the index file (supresses generation of a `package.json` file).
| optional | `label_list` | `srcs` | `[]` | Source files to be included in the module.
| optional | `label_list` | `deps` | `[]` | `node_module` rule dependencies.


### node_module attributes that affect the name of the module

For reference, by default a `node_module` rule `//src/js:my_module`
generates `node_modules/src/js/my_module`.

|  | Type | Name | Default | Description |
| ---: | :--- | :--- | :--- | :--- |
| optional | `string` | `namespace` | `None` | See <sup>1</sup>
| optional | `string` | `module_name` | `${ctx.label.package}/{ctx.label.name}` | See <sup>2</sup>
| optional | `string` | `separator` | `/` | See <sup>3</sup>

<sup>1</sup> Use to scope the module with some organization prefix.  *Example*: `namespace = '@foo'` generates `node_modules/@foo/src/js/my_module`.

<sup>2</sup> Override the module name.  *Example*: `name = 'barbaz'` with namespace (above) generates `node_modules/@foo/barbaz`

<sup>3</sup> *Example*: `separator = '-'` generates `node_modules/src-js-my_module`.

### node_module attributes that affect the generated `package.json`

These are only relevant if you don't explicitly name a `package.json` file.

|  | Type | Name | Default | Description |
| ---: | :--- | :--- | :--- | :--- |
| optional | `string` | `version` | `1.0.0` | Version string
| optional | `string` | `url` | `None` | Url where the module tgz archive was resolved
| optional | `string` | `sha1` | `None` | Sha1 hash of of the resolved tgz archive
| optional | `string` | `description` | `None` | Module description
| optional | `string_dict` | `executables` | `None` | A mapping from binary name to internal node module path.  Example `executables = { 'foo': 'bin/foo' }`.

### node_module attributes that affect the relative path of files included in the module

|  | Type | Name | Default | Description |
| ---: | :--- | :--- | :--- | :--- |
| optional | `string` | `layout` | `relative` | Changes the way files are included in the module.  One of `relative` or `workspace`.

Consider a file with the label `//src/js/my_module/app.js`.  With
`layout = 'relative'` (the default), the location of the file becomes
`node_modules/src/js/my_module/app.js` (skylark: `file.short_path`
relative to `module_name`).  Under `layout = 'workspace'`, the it
becomes `node_modules/src/js/my_module/src/js/my_module/app.js`
(skylark: `file.path`).  This is relevant only for protocol buffers
where the generated sources import their own dependencies relative to
the workspace, which needs to be preserved in the generated module.

## node_binary

The `node_binary` rule writes a script to execute a module entrypoint.

```python
load("@org_pubref_rules_node//node:rules.bzl", "node_binary")

node_binary(
    name = "foo",
    entrypoint = ":my_module_1",
)
```

In example above, we're specifying the name of a `node_module` to
use as the entrypoint.

```python
node_binary(
    name = "foo",
    main = "foo.js",
    deps = [
        ":my_module_1
    ],
)
```

In this second example, we're specifying the name of a file to use as
the entrypoint (under the hood, it will just build a `node_module`
(called `foo_module`) for your single `main` foo.js file entrypoint,
becoming equivalent to the first example).


```python
node_binary(
    name = "foo",
    entrypoint = ":my_module_2",
    executable = "baz",
)
```

In this third example (above), we're specifying the name of the node
module to start with (`my_module_2`) and the name of the executable
within `my_module_2` to run (`baz`).  In this case the `node_module`
rule definition for `my_module_2` must have a `string_dict` with an
entry for `baz` (like `executables = { 'baz': 'bin/baz' }`.

### Output structure of files generated for a `node_binary` rule

A `node_binary` rule named `foo` will create a folder having exactly
two entries:

1. An executable shell script named `foo`.
1. A folder which bundles up all the needed files in `foo_files/`.

Within `foo_files/`, there will also be exactly two entries:

1. The `node` executable itself.
1. The `node_modules/` folder with all the built/copied modules
   (including the entrypoint module).


### Building a deployable bundle

To generate a tarred/gzipped archive of the above example that you can
ship as a single 'executable' self-contained package, invoke `$ bazel
build :{target}_deploy.tar.gz`.  This is similar in intent to the java
`{target}_deploy.jar` implicit build rule.

```sh
$ bazel build :foo_deploy
Target //:foo_deploy.tar.gz up-to-date:
  bazel-bin/foo_bundle.tgz
$ du -h bazel-bin/foo_bundle.tgz
33M bazel-bin/foo_bundle.tgz
```

## node_test

The `node_test` rule is identical to node_binary, but sets the `test =
True` flag such that it can be used as a bazel test.

## mocha_test

Runs a mocha test identified by the start script given in `main` or
module given in `entrypoint`.

> Note: The mocha_test rule depends on `@mocha_modules//:_all_`, so
> you'll need to add this dependency in your `WORKSPACE` file:

```python
yarn_modules(
    name = "mocha_modules",
    deps = {
        "mocha": "3.5.3",
    }
)
```

```python
mocha_test(
    name = "test",
    main = "test.js",
)
```

## Conclusion

That's it!  Please refer to the various workspaces in `tests/` and the
source for more detail.
