test_all:
	(cd tests/helloworld && bazel test //:helloworld_test)
	(cd tests/lyrics && bazel test //:lyrics_test)
	(cd tests/express && bazel test //:server_test)
	(cd tests/namespace && bazel test //:question_test)
	(cd tests/typescript && bazel test //:typescript_test)
	(cd tests/mocha && bazel test //:test)
	(cd tests/mocha && bazel test //tests:test)
