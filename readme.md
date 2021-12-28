# Handlebars-hx
Haxe implementation of the [Handlebars](https://handlebarsjs.com/) templating engine.

**IN PROGRESS, NOT FEATURE COMPLETE**

## HXML Files

- **basic.hxml** builds a small neko app that takes a test name as a parameter and runs the output of that test.
- **test.hxml** builds the neko files required for testing the library.

## Tests

As of the creation of this project, I did not find a good test suite that could be used that is javascript agnostic. So I decided to make my own based on the examples and explainations at the [Handlebars Guide](https://handlebarsjs.com/guide/). In the future the tests from the [spec/ from the github repository](https://github.com/handlebars-lang/handlebars.js/tree/master/spec) should be ported over in order to use the same test suite as the original engine.

### Running Tests
Tests are stored in the [tests](tests/) directory and are run using [test-engine](https://github.com/snsvrno/test-engine) in the project (this project) root. Be sure to run `haxe test.hxml` before running the tests otherwise you could be using an older compiled build for the test.

There are multiple ways to use [test-engine](https://github.com/snsvrno/test-engine) based on what you want.
- `haxelib run test-engine` will run all the tests and show only the error outputs of each failed test
- `haxelib run test-engine -l` will show all tests ran and failed, but no output errors
- `haxelib run test-engine --test "*blob*"` will run tests that match the provided title.

### Creating a Test
Each test should be chosen to test a specific thing, and the name and folder the test is placed should accurately describe that thing. Before adding the test make sure the files adhere to the results from [the online handlebars engine](https://handlebarsjs.com/examples/simple-expressions.html) (an eample here, put in your template and object and ensure the output matches the output for the testfile).

Each test is made of at least 2 and up to 3 files:

- **[name].hbs** : the handlebars template file
- **[name].json** : the data object used by the template to generate the output
- **[name].html** : the rendered output 

The output is optional. If there is no output file then [test-engine](https://github.com/snsvrno/test-engine) will assume that this should be a failing test, and the test will pass if it gets an error.
