# Express Server Example

This folder demonstrates the use of node_binary with a node modules
dependency that has other modular dependencies.  In this case, we're
using the `yarn_modules.package_json` attribute rather than the `deps`
attribute to specify the dependency on express. Another dependency on
express-sessoin is added to package.json using a github npm URL. We're
also using the `@yarn_modules//:_all_` pseudo-module target to pull in
all the module dependencies.
