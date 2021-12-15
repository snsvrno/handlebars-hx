package handlebars;

enum Block {
    Text(text : String);
    Var(name : Array<String>);
    With(scope : Array<String>, blocks : Array<Block>);
    Each(scope : Array<String>, blocks : Array<Block>);
}
