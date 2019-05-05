NodeBinaryInfo = provider(
    fields = {
        "files": "the complete set of (run)files",
        "node": "the node executable",
    },
)

NodeModulesInfo = provider(
    fields = {
        "files": "the complete set of files",
        "modules": "the complete set of node_modules",
        "manifest": "the manifest file",
    },
)

NodeModuleInfo = provider(
    fields = {
        "identifier": "a canonical identifier for the module (string)",
        "name": "string: the common name of the module (string)",
        "version": "the module version (string)",
        "url": "the module url (string)",
        "sha1": "the module sha1 (string)",
        "package_json": "the package.json file (File)",
        "files": "the complete set of files in the module",
        "sources": "the set of source files in the module",
        "sourcemap": "the sourcemap file",
        "executables": "the set of executable targets",
        "transitive_deps": "the set of transitive node module dependencies",
    },
)
