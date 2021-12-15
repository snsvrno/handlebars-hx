import handlebars.Handlebars;

class Process {
    public static function main() {
        TestEngine.getInput((input : String, ?object : Dynamic) -> {
            var hb = new Handlebars(input);
            var result = hb.make(object);
            Sys.println(result);

            TestEngine.done();
        });
    }
}