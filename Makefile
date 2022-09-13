SHELL=/bin/bash

test-with-coverage:
	dart pub global activate coverage
	dart pub global run coverage:test_with_coverage

coverage:
	genhtml coverage/lcov.info -o coverage-html
	firefox coverage-html/index.html