load("//node:internal/node_utils.bzl", "execute")

sha256_attrs = {
    "sha256": attr.string(),
}

def sha256_execute(ctx, filepath):
    sha256 = None
    os = ctx.os.name
    if os == 'linux':
        sha256sum = ctx.which("sha256sum")
        if not sha256sum:
            fail("sha256sum not found (is it present in your PATH?)")
        sha256 = [sha256sum]
    elif os == 'mac os x':
        shasum = ctx.which("shasum")
        if not shasum:
            fail("shasum not found (is it present in your PATH?)")
        sha256 = [shasum, "-a256"]
    else:
        fail("Unsupported operating system: " + os)

    expected = ctx.attr.sha256
    result = execute(ctx, sha256 + [filepath])
    actual = result.stdout.split(" ")[0]
    if actual != expected:
        fail(ctx.name + "file <%s> sha256 [%s] does not match expected value [%s]" %(filepath, actual, expected))

    ctx.file("%s.sha256" % filepath, actual)
    return result
