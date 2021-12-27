# Handlebars-hx
Haxe implementation of the [Handlebars](https://handlebarsjs.com/) templating engine.

**IN PROGRESS, NOT FEATURE COMPLETE**

## Running Tests
Tests are stored in the [tests](tests/) directory and are run using [test-engine](https://github.com/snsvrno/test-engine) in the project (this project) root. Be sure to run `haxe test.hxml` before running the tests otherwise you could be using an older compiled build for the test.

There are multiple ways to use `test-engine` based on what you want.
- `haxelib run test-engine` will run all the tests and show only the error outputs of each failed test
- `haxelib run test-engine -l` will show all tests ran and failed, but no output errors
- `haxelib run test-engine --test "*blob*"` will run tests that match the provided title.
