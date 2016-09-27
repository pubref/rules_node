# `rules_node` [![Build Status](https://travis-ci.org/pubref/rules_node.svg?branch=master)](https://travis-ci.org/pubref/rules_node)

# Installation

Put `rules_node` in your `WORKSPACE` and load the main repository
dependencies.  This will download the nodejs toolchain including
`node` and `npm`.

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
| [npm_library](#npm_library) | Declare an npm dependency. |
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

BUILD rule.  Declares a set of npm dependencies.  Functionally
equivalent to `npm install --global` (global being relative to the npm
toolchain installed in your WORKSPACE.

Takes two forms:

1. **Single import**: uses the name of the rule (see `glob` above).

1. **Multiple import**: uses a string_dict declaring the
   `name@version` dependency. (see `react-stack` above).

## node_binary

BUILD rule.  Create an executable script that will run the file named
in the `main_script` attribute.


> **WARNING**: these rules are not hermetic or secure!  It trusts that
> the `npm install` command does what is it supposed to do.  There is
> no current support for valdating that a particular npm package(s)
> matches a sha256 (this is the the norm for npm, but it is
> sub-standard for bazel).
