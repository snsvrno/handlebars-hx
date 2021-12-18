package handlebars;

using StringTools;
using Path.PathArrayTools;

enum Block {
	Text(text:String);
	Var(path:Array<Path>, escaped : Bool);
	Each(path:Array<Path>, blocks: Array<Block>, escaped : Bool);
}

class BlockTools {

	/**
	 * displays a more troubleshooting friendly represnetation
	 * of all the blocks, for easier console printing of the blocks
	 */
	public static function toString(block : Block) : String {
		switch(block) {
			case Text(text): 
				return '<Text "${replaceSpecials(text)}">';
			case Var(path, escaped):
				return '<Var "${PathArrayTools.toString(path)}">';
			case Each(path, blocks, escaped):
				var blocktext = "";

				blocktext += '<Each "${PathArrayTools.toString(path)}">\n';
				for (b in blocks) blocktext += '    ' + toString(b) + "\n";
				blocktext += '</Each>\n';
				
				return blocktext;
		}
	}

	/**
	 * transforms some of the special characters into symbols
	 * to keep the text compact and more readable.
	 */
	public static function replaceSpecials(string : String) : String {
		return string
			.replace("\n","[NL]")
			.replace("\t", "[T]");
	}
}
