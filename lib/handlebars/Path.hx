package handlebars;

enum Path {
	String(string : String);
	Index(i : Int);
	Parent;
}

class PathTools {

	public static function toString(path: Path) : String {
		switch(path) {
			case String(string): return string;
			case Index(i): return '[$i]';
			case Parent: return "../";
		}
	}
}

class PathArrayTools {

	public static function toString(path:Array<Path>) : String {
		var pathString = "";
		for (i in 0 ... path.length) {
			pathString += PathTools.toString(path[i]);
			if (i > 0 && i < path.length-1) pathString += ".";
		}
		return pathString;
	}
}
