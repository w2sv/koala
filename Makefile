SHELL=/bin/bash

# $$$$$$$$$ Testing $$$$$$$$$$

test-and-show-coverage: run-tests coverage-html

run-tests:
	dart pub global activate coverage
	dart pub global run coverage:test_with_coverage

coverage-html:
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

# $$$$$$$$$ Publishing $$$$$$$$$$

pre-publish:
	dart format lib
	dart analyze
	dart pub publish --dry-run

patch-version:
	dart pub global activate pubversion
	pubversion patch

publish:
	dart pub publish