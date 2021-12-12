#if termcolors
import termcolors.Termcolors.*;
#end

class Test {
    
    public var desiredResult : String;
    public var template : String;
    public var object : Dynamic;
    public var result : String;

    private final handlebars : handlebars.Handlebars;

    static public function test() {

        // building the list of tests
        var tests : Map<String, Test> = new Map();
        for (f in getFiles('test/')) {
            var name = f.substr("test/suite/".length);
            tests.set(name, new Test(f));
        }

        var numberOfTests = 0;
        var passed = 0;

        // run the tests
        for (k => v in tests) {
            numberOfTests += 1;
            if (v.run()) passed += 1;
            else {

                var error = 'ERROR';
                #if termcolors
                error = red(error);
                k = yellow(k);
                v.desiredResult = blue(v.desiredResult);
                v.result = magenta(v.result);
                #end

                Sys.println('$error: $k');
                Sys.println('    expected: ${v.desiredResult} but found ${v.result}\n');
            }
        }

        #if termcolors
        Sys.println('Passed ${green(passed)} tests of ${green(numberOfTests)}');

        #else
        Sys.println('Passed $passed tests of $numberOfTests');
        #end
    }

    static private function getFiles(path : String) : Array<String> {
        var files : Array<String> = [ ];
        for (f in sys.FileSystem.readDirectory(path)) {
            var fullPath = haxe.io.Path.join([path, f]);
            if (sys.FileSystem.isDirectory(fullPath)) {
                var foundfiles = getFiles(fullPath);
                while(foundfiles.length > 0) files.push(foundfiles.shift());
            } else {
                if (haxe.io.Path.extension(f) == "json") files.push(fullPath);
            }
        }
        return files;
    }

    public function new(file : String) {
        var content = sys.io.File.getContent(file);
        var json = haxe.Json.parse(content);

        desiredResult = json.result;
        template = json.template;
        object = json.object;

        this.handlebars = new handlebars.Handlebars(template);
    }

    public function run() : Bool {
        result = handlebars.make(object);
        return desiredResult == result;
    }
}