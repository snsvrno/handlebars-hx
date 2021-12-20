package handlebars;

using Block.BlockTools;
using StringTools;

class Handlebars {

	// related to lexing
	private final rawtext : String;
	private var cursor : Int = -1;

	// related to parsing the structure into a rendered output
	private var blocks : Array<Block> = [];
	private var context : Context;

	public function new(text : String) {
		rawtext = text;
		blocks = lex();
		// for (b in blocks) Sys.println(b.toString());
	}

	public function make(object : Dynamic) : String {
		context = new Context(object);
		return makeBlocks(blocks);
	}

	private function makeBlocks(blocks : Array<Block>, ?forceEscaped : Bool = false) : String {
		var renderedText : String = "";

		for (b in blocks) switch(b) {
			case Text(text): 
				renderedText += text;
			
			case Var(path, escaped):
				var vartext = '${context.get(path)}';
				if (escaped || forceEscaped) vartext = htmlEscape(vartext);
				renderedText += vartext;

			case Each(path, blocks, escaped):
				context.forEach(path, function() {
					renderedText += makeBlocks(blocks, escaped);
				});
		}

		return renderedText;
	}

	/**
	 * reads the string and creates blocks.
	 *
	 * is used recursively for nexted blocks. if used in a nested
	 * context it will check that the appropariate closing block
	 * is found
	 *
	 * @param block the block nake when nested
	 */
	private function lex(?block : String) : Array<Block> {
		var blocks : Array<Block> = [];

		var char;
		var working = "";
		var trimText: Bool = false;

		while((char = nextChar()) != null) switch(char) {
			// a command token
			case "{" if (peakChar() == "{"):

				// consume the moustace
				nextChar();

				// checks if this is a "raw ({{{) or html-escaped ({{) block
				var escaped : Bool = if (peakChar() == "{") {
					nextChar();
					false;
				} else true;

				///////////////////////////////////////////////////
				// some cleanup since we may have a text block we have been working on
				// before.

				// if this exists that means we ignore all white space between the start
				// of this object and the previous none "whitespace" character.
				if (peakChar() == "~") {

					// consumes the '~'
					nextChar();

					var textblock = createText(working, trimText, true);
					// get ride of the first line if we determine adhere to whitespace control.
					if (checkWhitespaceControl(blocks, textblock[0])) textblock.shift();
					while(textblock.length > 0) blocks.push(textblock.shift());

				} else if (working.length > 0) {
					
					var textblock = createText(working, trimText, false);
					// get ride of the first line if we determine adhere to whitespace control.
					if (checkWhitespaceControl(blocks, textblock[0])) textblock.shift();
					while(textblock.length > 0) blocks.push(textblock.shift());
				}
				
				working = "";

				// gets the text inside this block starter
				while(peakChar(2) != null && peakChar(2) != "}}") working += nextChar();

				// checks if we have '~' right at the end, meaning we trim the next set
				// of whitespace.
				if (working.length > 0 && working.substr(working.length - 1, 1) == "~") { 
					trimText = true;
					working = working.substr(0, working.length - 1);
				} else trimText = false;

				// consumes the '}}'
				checkForChar("}", nextChar());
				checkForChar("}", nextChar());
				if (escaped == false) checkForChar("}", nextChar());

				// an ending nested block
				if (working.charAt(0) == "/") {
					
					if (block != null && block == working.substr(1))
						return blocks;
					else
						throw 'expected closing $block but found $working instead';

				// a starting nested block
				} else if (working.charAt(0) == "#") {

					var parameters = working.substr(1).split(" ");
					var command = parameters.shift();
					var subBlocks = lex(command);

					switch(command) {
						case "each":
							blocks.push(Each(parsePath(parameters[0]), subBlocks, escaped));

						case unknown: throw 'unimplemented block $command';
					}

				// a variable / lookup
				} else
					blocks.push(Var(parsePath(working), escaped));
				
				working = "";

			// no command token, going to be a text object.
			default: 
				working += char;
		}

		if (working.length > 0) { 
			var textblock = createText(working, trimText, false);
			// get ride of the first line if we determine adhere to whitespace control.
			if (checkWhitespaceControl(blocks, textblock[0])) textblock.shift();
			while(textblock.length > 0) blocks.push(textblock.shift());
		}

		return blocks;
	}

	/**
	 * creates a `Text()` block from the string, will trim the front or rear of
	 * that string if requested. these trims should only be used when `~` is found
	 * in moustache blocks before or after this text being created
	 *
	 * @param working the string that is converted to text
	 * @param escaped if the block was a '{{' (escaped) block or a '{{{' (raw)
	 * @param trimFront remove whitespace from the front
	 * @param trimRear remove whitespace from the rear
	 */
	private function createText(working : String, trimFront : Bool, trimRear : Bool) : Array<Block> {
		if (trimRear) while(working.length > 0 && isWhitespace(working.charAt(working.length-1))) {
			working = working.substr(0, working.length-1);

		} else if (trimFront) while(working.length > 0 && isWhitespace(working.charAt(0))) {
			working = working.substr(1);
		
		}

		// splits the text into different lines.
		var lines = [];
		for (sp1 in working.split("\n")) {
			var sp2 = sp1.split("\r");
			while(sp2.length > 0) lines.push(sp2.shift());
		}
	
		var blocks : Array<Block> = [];
		for (i in 0 ... lines.length) {
			var text = lines[i];
			if (i < lines.length-1) text += "\n";
			blocks.push(Text(text));
		}
		return blocks;
	}

	/**
	 * checks if the new block should be added to the existing set of blocks using the
	 * whitespace controls per the handlebars spec: https://handlebarsjs.com/guide/expressions.html#whitespace-control
	 *
	 * this is only applicable for a 'Text' block that is white space following a 'standalone helper'
	 *
	 * the outpoint meanis if we should skip adding this block per whitespace control, so a true means skip because
	 * whitespace control says we don't want it, false says we keep the block.
	 */
	private function checkWhitespaceControl(blocks : Array<Block>, newBlock : Block) : Bool {
		switch(newBlock) {

			// we only care about stopping a block from being added if it is a text block
			// and only contains whitespace, so all other blocks passe as 'newblock' will
			// just return a `false`
			case Text(text):

				// we only can remove whitespace if we have a special block...
				if (blocks.length > 0) switch(blocks[blocks.length-1]) {
					case Each(_, _, _):
					default: return false;
				}

				// checks if the text is all "whitespace" per the spec.
				var iswhitespace = true;
				for (i in 0 ... text.length) if (isWhitespace(text.charAt(i)) == false) {
					iswhitespace = false;
					break;
				}

				return iswhitespace;

			// not a text block, so we don't skip it.
			default: return false;
		}
	}

	/////////////////////////////////////////////////////////////////////////////
	// INLINE FUNCTIONS (for cleanliness)

	/**
	 * checks if the character is a whitespace .. using the definition of 
	 * whitespace from hadnlebars ... which is a space, a tab, or a newline
	 */
	inline private function isWhitespace(char : String) : Bool {
		return char == "\n" || char == " " || char == "\t";
	}

	inline private function nextChar() : Null<String> {
		if (cursor < rawtext.length) return rawtext.charAt(cursor += 1);
  	else return null;
	}

	inline private function peakChar(?size = 1) : Null<String> {
		if (cursor + size - 1 < rawtext.length) return rawtext.substr(cursor + 1, size);
		else return null;
	}

	inline private function parsePath(working : String) : Array<Path> {
		var path : Array<Path> = [];

		var segment : Null<String>;
		while((segment = getNextSegment(working)) != null) {

			// this is a little messy and i'll forget what is going on here at one point ...
			// so normally i'd make the `getNextSegment` function shrink down the `working`
			// string .. but i can't do that because this is all "static" and `working` doesn't
			// exist in either context. ... so we are shrinking it based on the output of the 
			// `getNextSegment` function. this will miss separators, so we need to add the 
			// length of the separator if its not a "Parent" or a "Current". doing this down
			// in the next section.
			working = working.substr(segment.length);

			// checking for the special 'parent'
			if (segment == "../") path.push(Parent);
			// checking for the special 'current'
			else if (segment == "./") path.push(Current);
			// a 'captured' string.
			else if (segment.charAt(0) == "[") {
				var insides = segment.substr(1, segment.length-2);
				var int : Null<Int>;
				if ((int = Std.parseInt(insides)) != null) path.push(Index(int));
				else path.push(String(insides));
				// removing the separator.
				working = working.substr(1);
			}
			// a plain string
			else { 

				if (!validateSegmentLiterals(segment)) throw 'found illegal character in segment: $segment';

				// now we need to check if we are using any reserved characters, but the trick is we _can_ use them, but
				// we cannot use them as the last part of the path, unless it is the only part of the path ...
				if (working.length == 0) switch(segment) {
					case "true" | "false" | "undefined" | "null":
						throw 'cannot use special text $segment';
					default: // is ok.
				}
				path.push(String(segment));
				working = working.substr(1);
			}
	}

		return path;
	}

	private function getNextSegment(text : String) : Null<String> {
		if (text.length == 0) return null
		else if (text.length > 3 && text.substr(0,3) == "../") return "../";
		else if (text.length > 2 && text.substr(0,2) == "./") return "./";
		else {
			var sep : Int = 0;
			var quoted : Null<String> = null;
			for (i in 0 ... text.length) {
				
				var char = text.charAt(i);
				switch([quoted, char]) {
					case ["[", "]"]: 
						quoted = null;
						continue;


					case [null, "."] | [null, "/"]:
						return text.substr(0, i);

					default:
				}
			}
		}

		return text;
	}

	/**
	 * checks the string characters against a list of invalid literals. will return
	 * a true if this passes the test.
	 */
	private function validateSegmentLiterals(text : String) : Bool {
		for (i in 0 ... text.length) switch(text.charAt(i)) {
			case " " | "!" | "\"" | "#" | "%" | "'" | "("
				| ")" | "*" | "+" | "," | "." | "/" | ";"
				| "<" | ">" | "=" | "@" | "[" | "\\" | "]"
				| "^" | "`" | "{" | "|" | "}" | "~" | "-" : return false;
		}

		return true;
	}

	inline private function checkForChar(a : String, b : String, ?pos : haxe.PosInfos) {
		if (a != b) throw 'expected "$a" but found "$b"';
	}

	inline private function htmlEscape(text : String) : String {
		var newtext = "";
		for (i in 0 ... text.length) newtext += switch(text.charAt(i)) {
			case "&": "&amp;";
			case "<": "&lt;";
			case ">": "&gt;";
			case "\"": "&quot;";
			case "'": "&#x27;";
			case "`": "&#x60;";
			case "=": "&#x3D;";
			case other: other;
		}
		return newtext;
	}

	inline private function split(string : String, ... chars:String) : Array<String> {
		var items = [ ];
		
		var working = "";
		var char = "";

		for (i in 0 ... string.length) {
			char = string.charAt(i);
			var splitdelim = false;

			for (c in chars) if (c == char) splitdelim = true;
			
			if (splitdelim) {
				items.push(working);
				working = "";
			}
			else working += char;

		}

		if (working.length > 0) items.push(working);
		return items;
	}
}
