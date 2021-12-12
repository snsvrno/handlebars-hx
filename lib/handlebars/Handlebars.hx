package handlebars;

class Handlebars {

    private var blocks : Array<Block> = [];
    private final rawtext : String;

    private var cursor : Int = -1;

    public function new(text : String) {
        rawtext = text;
        blocks = parseBlocks();
    }

    public function make(object : Dynamic) : String {
        return makeFromBlocks(object, blocks);
    }

    private function makeFromBlocks(object : Dynamic, blocks : Array<Block>) : String {
        var renderedText = "";

        for (b in blocks) switch(b) {
            case Text(text): 
                renderedText += text;

            case Var(name):

                // checking if we are using the "this" keyword.
                if (name.length == 1 && name[0] == "this") { 
                    renderedText += '${object}';
                    continue;
                }

                // we pop this so when we 'getcontext' we don't all the way
                // to the final key. then we add it later because this pop
                // permanently modifies the block.
                var finalKey = name.pop();
                var working = getContext(object, name);
                name.push(finalKey);

                var finalKey = name[name.length-1];
                renderedText += '${Reflect.getProperty(working, finalKey)}';   
            
            case With(context, blocks):
                var working = getContext(object, context);
                renderedText += makeFromBlocks(working, blocks);

            case Each(context, blocks):
                var working = getContext(object, context);
                if (Std.isOfType(working, Array)) {
                    for (o in cast(working, Array<Dynamic>)) {
                        renderedText += makeFromBlocks(o, blocks);
                    }
                }


        }

        return renderedText;
    }

    private function getContext(object : Dynamic, name : Array<String>) : Dynamic {
        var working = object;
        for (n in name) {
            if (Reflect.hasField(working, n)) working = Reflect.getProperty(working, n);
            else throw "error";
        }
        return working;
    }

    private function parseBlocks(?blockname : String) : Array<Block> {
        var blocks : Array<Block> = [];

        var char;
        var working = "";
        
        while((char = nextChar()) != null) {
            switch(char) {
                
                // a moustache statement.
                case "{" if (peakChar() == "{"): 

                    //////////////////////////////////////////////
                    // CLEANUP BEFORE WE BEGIN
                    // adds the previous thing as a text block.
                    if (working.length > 0) {
                        blocks.push(Text(working));
                        working = "";
                    }

                    // consumes the token
                    nextChar();
                    //////////////////////////////////////////////

                    // checks for the closing moustache.
                    while(peakChar(2) != null && peakChar(2) != "}}") working += nextChar();

                    // gets the moustache.
                    nextChar();
                    nextChar();

                    // trims the white space
                    while(working.charAt(0) == " ") working = working.substr(1);
                    while(working.charAt(working.length-1) == " ") working = working.substr(0,working.length-1);

                    //////////////////////////////////////////////

                    // now checks what we may have.
                    // the closing of a command.
                    if (working.charAt(0) == "/") {
                        var parameters = working.substr(1).split(" ");
                        var command = parameters.shift();
                        if (blockname != null && blockname == command)
                            return blocks;
                        else 
                            throw 'expected closing $blockname but found $command instead';
                    }
                    // the start of a command
                    else if (working.charAt(0) == "#") {
                        var parameters = working.substr(1).split(" ");
                        var command = parameters.shift();
                        var subblocks = parseBlocks(command);
                        switch(command) {
                            case "with":
                                blocks.push(With(parameters[0].split("."), subblocks));

                            case "each":
                                blocks.push(Each(parameters[0].split("."), subblocks));

                            case unknown:
                                throw "unknown command:" + unknown;
                        }
                    }

                    // nothing left, must be a variable.
                    else blocks.push(Var(working.split(".")));

                    working = "";
                    
                default: 
                    working += char;
            }
        }

        if (working.length > 0) blocks.push(Text(working));

        return blocks;
    }


    inline private function nextChar() : Null<String> {
        if (cursor < rawtext.length) return rawtext.charAt(cursor += 1);
        else return null;
    }

    inline private function peakChar(?size = 1) : Null<String> {
        if (cursor + size - 1 < rawtext.length) return rawtext.substr(cursor + 1, size);
        else return null;
    }

}