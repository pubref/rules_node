'use strict';

const fs = require('fs');
const lockfile = require('@yarnpkg/lockfile');

let file = fs.readFileSync('yarn.lock', 'utf8');
let json = lockfile.parse(file);

if (json.type !== 'success') {
  throw new Error('Lockfile parse failed: ' + JSON.stringify(json, null, 2));
}

const entries = Object.keys(json.object).map(key => makeEntry(key, json.object[key]));
const cache = new Map();

print("");
print("package(default_visibility = ['//visibility:public'])");
print("load('@org_pubref_rules_node//node:rules.bzl', 'node_module', 'node_binary')");

entries.forEach(entry => printNodeModule(entry));

printNodeModules(cache);

cache.forEach(entry => parsePackageJson(entry));

print("");
print("# EOF");

function makeEntry(key, entry) {
  parseName(key, entry);
  parseResolved(entry);
  return entry;
}

function parseName(key, entry) {
  // can be 'foo@1.0.0' or something like '@types/foo@1.0.0'
  const at = key.lastIndexOf('@');
  entry.id = key;
  entry.name = key.slice(0, at);

  const label = entry.name.replace('@', 'at-');
  entry.label = label;
}

function parseResolved(entry) {
  const resolved = entry.resolved;
  if (resolved) {
    const tokens = resolved.split("#");
    entry.url = tokens[0];
    entry.sha1 = tokens[1];
  }
}

function printDownloadMeta(entry) {
  print("# <-- " + [entry.sha1,entry.name,entry.url].join("|"));
}

function printJson(entry) {
  JSON.stringify(entry, null, 2).split("\n").forEach(line => print("# " + line));
}

function printNodeModule(entry) {
  print(``);
  printJson(entry);
  const prev = cache.get(entry.name);
  if (prev) {
    print(`## Skipped ${entry.id} (${entry.name} resolves to ${prev.id})`);
    return;
  }
  print(`node_module(`);
  print(`    name = "${entry.name}",`);
  print(`    version = "${entry.version}",`);
  print(`    url = "${entry.url}",`);
  print(`    sha1 = "${entry.sha1}",`);
  print(`    package_json = "node_modules/${entry.name}/package.json",`);
  print(`    srcs = glob(["node_modules/${entry.name}/**/*"], exclude = ["node_modules/${entry.name}/package.json"]),`);

  if (entry.dependencies) {
    print(`    deps = [`);
    Object.keys(entry.dependencies).forEach(module => {
      print(`        ":${module}",`);
    });
    print(`    ],`);
  }
  print(`)`);

  cache.set(entry.name, entry);
}

function printNodeModules(map) {
  print(``);
  print(`# Pseudo-module that basically acts as a module collection for the entire set`);
  print(`node_module(`);
  print(`    name = "_all_",`);
  print(`    deps = [`);
  for (let entry of map.values()) {
    print(`        ":${entry.name}",`);
  }
  print(`    ],`);
  print(`)`);
}

function parsePackageJson(entry) {
  const pkg = require(`./node_modules/${entry.name}/package.json`);
  if (Array.isArray(pkg.bin)) {
    // should not happen: throw new Error('Hmm, I didn\'t realize pkg.bin could be an array.');
  } else if (typeof pkg.bin === 'string') {
    printNodeModuleShBinary(entry, pkg, entry.name, pkg.bin);
  } else if (typeof pkg.bin === 'object') {
    Object.keys(pkg.bin).forEach(key => printNodeModuleShBinary(entry, pkg, key, pkg.bin[key]));
  }
}

function printNodeModuleShBinary(entry, pkg, name, path) {
  print(``);
  print(`sh_binary(`);
  print(`    name = "${name}_bin",`); // dont want sh_binary 'mkdirp' to conflict
  print(`    srcs = [":node_modules/.bin/${name}"],`);
  print(`    data = [`);
  print(`        ":${entry.name}",`); // must always depend on self
  if (pkg.dependencies) {
    Object.keys(pkg.dependencies).forEach(dep_name => {
      const dep_entry = cache.get(dep_name);
      if (!dep_entry) {
        throw new Error('Cannot find dependency entry for ' + dep_name);
      }
      print(`        ":${dep_entry.name}",`);
    });
  }
  print(`    ],`);
  print(`)`);
}

function printNodeModuleBinary(entry, pkg, name, path) {
  if (path.indexOf("./") === 0) {
    path = path.slice(2);
  }
  print(``);
  print(`sh_binary(`);
  print(`    name = "${entry.name}_${name}",`);
  print(`    srcs = [":node_modules/${entry.name}/${path}"],`);
  print(`    data = [`);
  print(`        ":${entry.name}",`); // must always depend on self
  if (pkg.dependencies) {
    Object.keys(pkg.dependencies).forEach(dep_name => {
      const dep_entry = cache.get(dep_name);
      if (!dep_entry) {
        throw new Error('Cannot find dependency entry for ' + dep_name);
      }
      print(`        ":${dep_entry.name}",`);
    });
  }
  print(`    ],`);
  print(`)`);
}

function print(msg) {
  console.log(msg);
}
