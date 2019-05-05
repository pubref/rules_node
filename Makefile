BAZEL_ARGS=--all_incompatible_changes --incompatible_disallow_struct_provider_syntax=false

test_helloworld:
	(cd tests/helloworld && bazel test ${BAZEL_ARGS} //...)

test_lyrics:
	(cd tests/lyrics && bazel test ${BAZEL_ARGS} //...)

test_express:
	(cd tests/express && bazel test ${BAZEL_ARGS} //...)

test_namespace:
	(cd tests/namespace && bazel test ${BAZEL_ARGS} //...)

test_rollup:
	(cd tests/rollup && bazel test ${BAZEL_ARGS} //...)

test_typescript:
	(cd tests/typescript && bazel test ${BAZEL_ARGS} //...)

test_webpack:
	(cd tests/webpack && bazel test ${BAZEL_ARGS} //...)

test_polymer-cli:
	(cd tests/polymer-cli && bazel test //...)

test_mocha:
	(cd tests/mocha && bazel test ${BAZEL_ARGS} //...)

# polymer cli not included as it appears to still be a WIP
test_all: test_helloworld test_lyrics test_express test_namespace test_typescript test_webpack test_mocha test_rollup