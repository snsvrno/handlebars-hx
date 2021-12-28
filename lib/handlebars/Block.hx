package handlebars;

using StringTools;
using Path.PathArrayTools;

enum Block {
	Text(text:String);
	Var(path:Array<Path>, escaped : Bool);
	Each(path:Array<Path>, blocks: Array<Block>, escaped : Bool);
	If(condition:Block, trueStatement: Array<Block>, elseStatement: Array<Block>);
	Helper(name : String, parameters : Array<Block>);
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

			case If(condition, trueStatement, elseStatement):
				var blocktext = "";

				blocktext += '<If "${toString(condition)}">\n';
				for (b in trueStatement) blocktext += '    ' + toString(b) + "\n";
				if (elseStatement.length > 0) {
					blocktext += '<Else>\n';
					for (b in elseStatement) blocktext += '    ' + toString(b) + "\n";
				}

				return blocktext;

			case Helper(name, parameters):
				return '<$name "${parameters.join(", ")}">\n';
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
