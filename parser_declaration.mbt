///|
test {
  let token_decl =
    #|%derive<Eq> TokenKind 
    #|
    #|// moonyacc entry point, specify the `parse` non-terminal symbol as the start point
    #|%start parse 
    #|
    #|// specify the position type 
    #|%position<Position>
    #|
    #|
    #|// PDF delimiter characters
    #| 
    #|%token LEFT_PARENTHESIS "("
    #|%token RIGHT_PARENTHESIS ")"
    #|%token LEFT_CURLY_BRACE "{"
    #|%token RIGHT_CURLY_BRACE "}"
    #|%token LEFT_SQUARE_BRACKET "["
    #|%token RIGHT_SQUARE_BRACKET "]"
    #|%token LESS_THAN_SIGN "<"
    #|%token GREATER_THAN_SIGN ">"
    #|%token SOLIDUS "/"
    #|%token DICT_BEGIN "<<"
    #|%token DICT_END ">>"
    #|
    #|
    #|// PDF end-of-line markers
    #|// `\r`, `\r\n`, `\n`, this can appear in  reverse solidus `\`
    #|// reverse solidus after an end-of-line marker is used for multi-line literal strings, in this case, end-of-line marker is ignored.
    #|
    #|// if string literal has end-of-line marker, it would be convert to `\n`.
    #|
    #|
    #|//
    #|// PDF comment:
    #|// starting with a percent sign (%) and continuing to the end of the line
    #|// this comment should outside a PDF string or inside a content stream.
    #|
    #|// PDF Objects:
    #|
    #|// Booleans objects, see more details in `ISO 32000-2:2020 (PDF 2.0)`, section 7.3.2
    #|%token TRUE "true"
    #|%token FALSE "false"
    #|
    #|// Numeric objects, see more details in `ISO 32000-2:2020 (PDF 2.0)`, section 7.3.3
    #|%token<Int> INTEGER
    #|
    #|%token<Double> REAL 
    #|
    #|// String objects, see more details in `ISO 32000-2:2020 (PDF 2.0)`, section 7.3.4
    #|//
    #|// here we parse `Literal String` and `Hexadecimal String` into a unified representation as STRING token
    #|//
    #|%token<Bytes> STRING 
    #|
    #|// Name objects, see more details in `ISO 32000-2:2020 (PDF 2.0)`, section 7.3.5
    #|// 
    #|// here is different from the official PDF specification:
    #|// warning!
    #|//
    #|// this NAME token contains the leading solidus (/) character
    #|%token<Bytes> NAME
    #|
    #|// Array objects, Dictionary objects and Stream objects aren't terminal symbols.
    #|
    #|// here define an EOF token to mark the end of input
    #|%token EOF 
    #|
    #|%left PLUS MINUS
    #|
    #|%% 
    #|// moonyacc entry point must be declared using `%start <symbol_name>` directive
    #|// here is the definition of the entry point symbol
    #|parse  :  
    #|  |  EOF { $1 }
    #|;
    #|
    #|
  // let expr = [
  //   rule(fn(lhs : Expr, _ : PLUS, rhs : Expr) -> Expr { Expr::Add(lhs, rhs) }),
  //   rule(fn(lhs : Expr, _ : MINUS, rhs : Expr) -> Expr { Expr::Minus(lhs, rhs) }),
  //   rule(fn(value : INT) -> Expr { Expr::LInt(value) }),
  // ]
  let path = current_source_location().path.replace(
    old="parser_declaration.mbt",
    new="parser.mbty",
  )
  let buffer = StringBuilder::new()

  // // dump the non-terminal declaration to the buffer
  buffer.write_string(token_decl)
  // buffer.write_string(NonTerminal::from(expr).emit())
  // buffer.write_string("\n")

  try! @fs.write_string_to_file(path, buffer.to_string())
}
