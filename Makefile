test_helloworld:
	(cd tests/helloworld && bazel test //...)

test_lyrics:
	(cd tests/lyrics && bazel test //...)

test_express:
	(cd tests/express && bazel test //...)

test_namespace:
	(cd tests/namespace && bazel test //...)

test_rollup:
	(cd tests/rollup && bazel test //...)

test_typescript:
	(cd tests/typescript && bazel test //...)

test_webpack:
	(cd tests/webpack && bazel test //...)

test_polymer-cli:
	(cd tests/polymer-cli && bazel test //...)

test_mocha:
	(cd tests/mocha && bazel test //...)

# polymer cli not included as it appears to still be a WIP
test_all: test_helloworld test_lyrics test_express test_namespace test_typescript test_webpack test_mocha test_rollup