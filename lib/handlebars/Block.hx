package handlebars;

enum Block {
    Text(text : String);
    Var(name : Array<String>);
    With(context : Array<String>, blocks : Array<Block>);
    Each(context : Array<String>, blocks : Array<Block>);
}