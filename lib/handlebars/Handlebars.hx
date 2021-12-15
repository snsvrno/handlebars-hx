package handlebars;

using StringTools;

class Handlebars {

    private var blocks : Array<Block> = [];
    private final rawtext : String;

    private var context : Null<Context> = null;

    private var cursor : Int = -1;

    ////////////////////////////////////////////////////////

    /**
     * creates a new handlebars parser / processer.
     */
    public function new(text : String) {
        rawtext = text;
        blocks = parseBlocks();

        //for (b in blocks) trace(b);
    }

    /////////////////////////////////////////////////////////

    /*
     * creates a string (processed output) using the 
     * provided object
     */
    public function make(object : Dynamic) : String {
        // sets our working context.
        context = new Context(object);
        // renders the result.
        var result = makeFromBlocks(blocks);
        // cleanup, remove the context object so we don't accidently
        // get bleed from this context and another context.
        context = null;
        return result;
    }

    /*
     * internal helper function that makes a string based on the object
     * and blocks given.
     */
    private function makeFromBlocks(blocks : Array<Block>) : String {
        var renderedText = "";

        for (b in blocks) switch(b) {
            case Text(text): 
                renderedText += text;

            case Var(name):
                renderedText += '${context.get(name)}';

            case With(scope, blocks):
/*
                var working = getContext(object, context);
                renderedText += makeFromBlocks(working, blocks);
*/
            case Each(scope, blocks):
                context.forEach(scope, function() {
                    renderedText += makeFromBlocks(blocks);
                });

        }

        return renderedText;
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
                                // we want to ignore the first new line after the each
                                // block, so we are going to check if the first block
                                // has one first and removes it.
                                switch(subblocks[0]) {
                                    case Text(text):
                                        if (text.trim().length == 0 && text.indexOf("\n") > -1)
                                            subblocks[0] = Text(text.substr(text.indexOf("\n") + 1));

                                    default:
                                }

                                blocks.push(Each(parameters[0].split("."), subblocks));

                            case unknown:
                                throw "unknown command:" + unknown;
                        }
                    }

                    // nothing left, must be a variable.
                    else {
                        /*if (working.indexOf("/") != -1) {
                            // TODO : put some kind of deprecated warning here to let the user know
                            // that this isn't the ideal way to do this. use '.' instead of '/'
                        }*/


                        var path = [ ];

                        // part of the changing the context, the "parent".
                        // counts how many times we put "../" at the front.
                        var parentLevel = 0;
                        while (working.length > 3 && working.substr(0, 3) == "../") {
                            path.push("../");
                            working = working.substr(3);
                        }

                        for (s in working.split(".")) {
                            var secondSplit = s.split("/");
                            while(secondSplit.length > 0) path.push(secondSplit.shift());
                        }

                        blocks.push(Var(path));
                    }

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
