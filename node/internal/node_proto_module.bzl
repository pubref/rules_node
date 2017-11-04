load("//node:internal/node_module.bzl", "node_module")

_protocbin = Label("@com_google_protobuf//:protoc")
_protobuf_modules = Label("@protobuf_modules//:_all_")

def node_proto_module(name,
                      srcs,
                      binary = True,
                      descriptor = False,
                      protobuf_modules = _protobuf_modules,
                      protocbin = _protocbin,
                      **kwargs):
    outs = [src.split('.')[0] + "_pb.js" for src in srcs]

    js_out_options = ["import_style=commonjs"]

    if binary:
        js_out_options += ["binary"]

    cmd = ["$(location %s)" % protocbin]
    cmd += ["--js_out=%s:$(GENDIR)" % ",".join(js_out_options)]

    if descriptor:
        cmd += ["--descriptor_set_out=$(@D)/%s.descriptor" % name]
        outs += [name + ".descriptor"]

    cmd += ["$(location " +src + ")" for src in srcs]

    native.genrule(
        name = name + "_gen",
        cmd = " ".join(cmd),
        srcs = srcs,
        message = "Generating NodeJS Protocol Buffer file(s)...",
        outs = outs,
        tools = [protocbin],
        visibility = ["//visibility:private"]
    )

    node_module(
        name = name,
        srcs = outs,
        deps = [protobuf_modules],
        executables = None,
        index = None,
        main = None,
        package_json = None,
        **kwargs
    )
