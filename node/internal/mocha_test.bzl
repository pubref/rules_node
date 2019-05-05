load("//node:internal/providers.bzl", "NodeModuleInfo")
load("//node:internal/node_module.bzl", "node_module")
load("//node:internal/node_modules.bzl", "node_modules")

def mocha_test(
        name = None,
        # Main test script entrypoint
        main = None,
        # Additional module deps for the test
        deps = [],
        # The mocha binary executable target
        mocha_bin = "@mocha_modules//:mocha_bin",
        # The script runner for the sh_test
        script = "@org_pubref_rules_node//node:internal/mocha_test.sh",
        # Any additional args to pass directly to mocha
        args = [],
        # Test size
        size = "small",
        # Test visibility
        visibility = None,
        # Remainder of args go to 'node_module'
        **kwargs):

    """Given a rule name and a main test script entrypoint file, package
    that test script up as a module, then package that module in a
    node_modules tree.  Run a bash script that invokes the mocha_bin
    executable with the name of the testable entrypoint module.

    """

    node_module(
        name = name + "_module",
        main = main,
        visibility = visibility,
        **kwargs
    )

    node_modules(
        name = name + "_modules",
        target = name + "_modules",
        visibility = visibility,
        deps = deps + [name + "_module"],
    )

    entrypoint = [
        "%s_modules" % name,
        "node_modules"
    ]

    if native.package_name():
        entrypoint.insert(0, native.package_name())
        entrypoint.append(native.package_name())
    entrypoint.append("%s_module" % name)

    native.sh_test(
        name = name,
        srcs = [script],
        args = args + ["/".join(entrypoint)],
        data = [
            mocha_bin,
            name + "_modules",
        ],
        size = size,
        visibility = visibility,
    )
