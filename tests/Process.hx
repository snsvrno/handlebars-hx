import handlebars.Handlebars;
import testengine.TestEngine;

class Process {
    public static function main() {
        TestEngine.getInput((input) -> {

            var hb = new Handlebars(input.hbs);
            var object = haxe.Json.parse(input.json);

            // loads any helpers from the script if available.
            if (Reflect.hasField(input, "hxs")) {
                var parser = new hscript.Parser();
                var program = parser.parseString(input.hxs);
                var interp = new hscript.Interp();
                interp.variables.set("Handlebars", hb);
                interp.execute(program);
            }

            var result = hb.make(object);

            Sys.println(result);

            TestEngine.done();
        });
    }
}
