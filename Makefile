SHELL=/bin/bash

# $$$$$$$$$ Testing $$$$$$$$$$

test-and-show-coverage: test coverage-html

run-tests:
	dart pub global activate coverage
	dart pub global run coverage:test_with_coverage

coverage-html:
	genhtml coverage/lcov.info -o coverage/html
	firefox coverage/html/index.html

# $$$$$$$$$ Releasing $$$$$$$$$$

pre-release:
	dart format lib
	dart analyze
	dart pub publish --dry-run

patch-version:
	dart pub global activate pubversion
	pubversion patch

release:
	dart pub publish