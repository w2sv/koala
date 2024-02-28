SHELL=/bin/bash

# $$$$$$$$$ Testing $$$$$$$$$$

test-and-show-coverage: run-tests coverage-html

run-tests:
	@dart run test --coverage=./coverage --chain-stack-traces
	@echo "Converting to lcov.info"
	@dart pub global activate coverage > /dev/null
	@dart pub global run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --lcov -o ./coverage/lcov.info -i ./coverage

coverage-html:
	@genhtml coverage/lcov.info -o coverage/html
	@open coverage/html/index.html

# $$$$$$$$$ Publishing $$$$$$$$$$

pre-publish:
	@dart format lib
	@dart analyze
	@dart doc
	@dart pub publish --dry-run

patch-version:
	dart pub global activate pubversion
	pubversion patch
	dart pub get

publish:
	dart pub publish
	gh release create