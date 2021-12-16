package handlebars;

using Block.BlockTools;

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
		for (b in blocks) Sys.println(b.toString());
	}

	public function make(object : Dynamic) : String {
		context = new Context(object);
		return makeBlocks(blocks);
	}

	private function makeBlocks(blocks : Array<Block>) : String {
		var renderedText : String = "";

		for (b in blocks) switch(b) {
			case Text(text): 
				renderedText += text;
			
			case Var(path):
				renderedText += '${context.get(path)}';

			case Each(path, blocks):
				context.forEach(path, function() {
					renderedText += makeBlocks(blocks);
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
				nextChar();
				nextChar();

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
							blocks.push(Each(parsePath(parameters[0]), subBlocks));

						case unknown: throw 'unimplemented block $command';
					}

				// a variable / lookup
				} else
					blocks.push(Var(parsePath(working)));
				
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
					case Each(_,_):
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

		while(working.length > 3 && working.substr(0,3) == "../") {
			path.push(Parent);
			working = working.substr(3);
		}

		for (s in working.split(".")) {
			var second = s.split("/");
			while(second.length > 0) path.push(String(second.shift()));
		}

		return path;
	}

}
