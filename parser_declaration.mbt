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
    #|// Null object, see more details in `ISO 32000-2:2020 (PDF 2.0)`, section 7.3.9
    #|%token NULL "null"
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
    #|// Indirect Object, see more details in `ISO 32000-2:2020 (PDF 2.0)`, section 7.3.10
    #|%token<INDIRECT> INDIRECT
    #|
    #|// Array objects, Dictionary objects and Stream objects aren't terminal symbols.
    #|
    #|// here define an EOF token to mark the end of input
    #|%token EOF
    #|
    #|%% 
    #|// moonyacc entry point must be declared using `%start <symbol_name>` directive
    #|// here is the definition of the entry point symbol
    #|parse -> PDF_Obj :  
    #|  |  PDF_Obj EOF { $1 }
    #|;
    #|
    #|
  let path = current_source_location().path.replace(
    old="parser_declaration.mbt",
    new="parser.mbty",
  )
  let buffer = StringBuilder::new()
  let atom = [
    rule(fn(val : NAME) -> Atom { Name(val) }),
    rule(fn(val : STRING) -> Atom { String(val) }),
    rule(fn(val : INTEGER) -> Atom { Integer(val) }),
    rule(fn(val : REAL) -> Atom { Real(val) }),
    rule(fn(val : NULL) -> Atom { Null }),
    rule(fn(val : TRUE) -> Atom { Boolean(true) }),
    rule(fn(val : FALSE) -> Atom { Boolean(false) }),
    rule(fn(val : INDIRECT) -> Atom { Indirect(val.object_num) }),
  ]
  let array_non_empty_elems = [
    rule(fn(val : Atom) -> NonEmptyElems { [val] }),
    rule(fn(acc : NonEmptyElems, val : Atom) -> NonEmptyElems {
      acc.push(val)
      acc
    }),
  ]
  let pdf_array = [
    // Array([]])
    rule(fn(_ : LEFT_SQUARE_BRACKET, _ : RIGHT_SQUARE_BRACKET) -> PDF_Array {
      Object::Array([])
    }),
    rule(fn(
      _ : LEFT_SQUARE_BRACKET,
      array : NonEmptyElems,
      _ : RIGHT_SQUARE_BRACKET,
    ) -> PDF_Array {
      Array(array)
    }),
  ]
  let pdf_dict_entries = [
    rule(fn(key : NAME, value : Atom) -> DictEntries { [(key, value)] }),
    rule(fn(acc : DictEntries, key : NAME, value : Atom) -> DictEntries {
      acc.push((key, value))
      acc
    }),
  ]
  let pdf_dict = [
    // Dictionary with no entries: << >>
    rule(fn(_ : DICT_BEGIN, _ : DICT_END) -> PDF_Dict { Object::Dictionary([]) }),
    // Dictionary with entries: << /Key1 Value1 /Key2 Value2 ... >>
    rule(fn(_ : DICT_BEGIN, entries : DictEntries, _ : DICT_END) -> PDF_Dict {
      Object::Dictionary(entries)
    }),
  ]
  let pdf_obj = [
    rule(fn(val : Atom) -> PDF_Obj { val }),
    rule(fn(val : PDF_Array) -> PDF_Obj { val }),
    rule(fn(val : PDF_Dict) -> PDF_Obj { val }),
  ]
  let non_terminal_symbols = [
    pdf_obj, atom, array_non_empty_elems, pdf_array, pdf_dict_entries, pdf_dict,
  ]

  // dump the non-terminal declaration to the buffer
  buffer.write_string(token_decl)
  for non_terminal in non_terminal_symbols {
    buffer.write_string(NonTerminal::from(non_terminal).emit())
  }
  buffer.write_string("\n\n%%\n")
  try! @fs.write_string_to_file(path, buffer.to_string())
}
