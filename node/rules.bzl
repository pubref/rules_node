load("//node:internal/node_repositories.bzl", _node_repositories = "node_repositories")
load("//node:internal/yarn_modules.bzl", _yarn_modules = "yarn_modules")
load("//node:internal/node_module.bzl", _node_module = "node_module")
load("//node:internal/node_modules.bzl", _node_modules = "node_modules")
load("//node:internal/node_binary.bzl", _node_binary = "node_binary")
load("//node:internal/node_binary.bzl", _node_test = "node_test")
load("//node:internal/node_bundle.bzl", _node_bundle = "node_bundle")
load("//node:internal/mocha_test.bzl", _mocha_test = "mocha_test")

node_repositories = _node_repositories
yarn_modules = _yarn_modules
node_module = _node_module
node_modules = _node_modules
node_binary = _node_binary
node_test = _node_test
mocha_test = _mocha_test