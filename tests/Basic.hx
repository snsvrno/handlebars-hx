class Basic {
	public static function main() {
		var file = Sys.args()[0];
		var contents = sys.io.File.getContent(file + ".hbs");
		var object = haxe.Json.parse(sys.io.File.getContent(file + ".json"));
	
		var hb = new handlebars.Handlebars(contents);
		Sys.print(hb.make(object));
	}
}

