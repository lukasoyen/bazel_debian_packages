"repository rule for extracting debian archives into a install dir"

load("//apt/private:util.bzl", "util")

def _extract_data_file(rctx, host_tar, path):
    cmd = [host_tar, "-xf", path]
    result = rctx.execute(cmd)
    if result.return_code:
        fail("Failed to extract data file: {} ({}, {}, {})".format(
            " ".join(cmd),
            result.return_code,
            result.stdout,
            result.stderr,
        ))

def _deb_install_impl(rctx):
    host_tar = util.get_host_tool(rctx, "bsd_tar", "tar")

    index = json.decode(rctx.read(util.get_repo_path(rctx, rctx.attr.source, "index.json")))

    # otherwise assume we are in the initial lockfile generation
    if index:
        if rctx.attr.architecture not in index:
            fail(
                "Misconfigured `sysroot()`. Can not find the provided architecture {} in packages from {}".format(rctx.attr.architecture, rctx.attr.source),
            )

        for package in index[rctx.attr.architecture]:
            path = rctx.path(Label(package))
            _extract_data_file(rctx, host_tar, path)

    rctx.template(
        "BUILD.bazel",
        rctx.attr.build_file,
        {
            "{target_name}": rctx.attr.source,
        },
    )

deb_install = repository_rule(
    implementation = _deb_install_impl,
    attrs = {
        "apparent_name": attr.string(mandatory = True),
        "architecture": attr.string(mandatory = True),
        "source": attr.string(mandatory = True),
        "build_file": attr.label(mandatory = True),
    },
)
