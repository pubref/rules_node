v0.4.0 (Thu Sep 21 2017)

This is a complete rewrite of `rules_node`.  In prior releases `npm`
was used to install dependencies, this has been replaced with `yarn`.
The mechanism for associating external (npm) node modules was
previously based on assembling a `NODE_PATH` enviroment variable.
This has been replaced by code that constructs a fresh `node_modules/`
tree foreach `node_binary` rule, having much better hermeticity
characteristics.
