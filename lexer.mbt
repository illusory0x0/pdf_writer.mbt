///|
pub fn tokenize(input : @string.View) -> Array[(Token, Position, Position)] {
  let mut input = input
  let mut start_row = 0
  let mut start_col = 0
  let mut row = 0
  let mut col = 0
  let result = []
  fn push(tok : Token, length : Int) -> Unit {
    let start = Position::{ row: start_row, col: start_col }
    col += length
    let end = Position::{ row, col }
    result.push((tok, start, end))
    start_row = row
    start_col = col
  }

  fn push_no_token(length : Int) -> Unit {
    col += length
    start_row = row
    start_col = col
  }

  for {
    lexmatch input {
      // Whitespace (spaces, tabs, form feed, null character)
      "[ \t\f\0]+" as s, rest => {
        push_no_token(s.length())
        input = rest
      }

      // Newlines (CR, LF, CRLF)
      "(\r\n)|\r|\n", rest => {
        row += 1
        col = 0
        start_row = row
        start_col = 0
        input = rest
      }

      // PDF Comments (% until end of line, including the end-of-line marker)
      // Handles all three PDF end-of-line markers: \r\n, \r, \n
      "%[^\r\n]*(\r\n|\r|\n)", rest => {
        // Comments are ignored, advance to next line
        row += 1
        col = 0
        start_row = row
        start_col = 0
        input = rest
      }

      // PDF Comments at end of file (% until end of input without end-of-line)
      // WARNING: This pattern is NOT redundant with the above pattern!
      // The above pattern requires a newline after the comment: "%[^\r\n]*(\r\n|\r|\n)"
      // This pattern handles comments at EOF WITHOUT trailing newlines: "%[^\r\n]*$"
      // Example: "true % comment" (comment at end with no newline)
      "%[^\r\n]*$", rest =>
        // Comment at end of file, just advance position
        input = rest

      // Dictionary delimiters (must come before < and >)
      "<<", rest => {
        push(DICT_BEGIN, 2)
        input = rest
      }
      ">>", rest => {
        push(DICT_END, 2)
        input = rest
      }

      // Boolean literals (must come before general identifiers)
      "true", rest => {
        push(TRUE, 4)
        input = rest
      }
      "false", rest => {
        push(FALSE, 5)
        input = rest
      }

      // Real numbers (must come before integers to catch decimals)
      // Matches: 123.456, .456, 123., 123.456E10, 123E-5, -123.456, +123.456
      "-?(([0-9]+\.[0-9]*|\.[0-9]+)([eE][+\-]?[0-9]+)?|[0-9]+[eE][+\-]?[0-9]+)" as s, rest => {
        let value = 0.0 // TODO: parse Double from string
        push(REAL(value), s.length())
        input = rest
      }

      // Integers (positive, negative, decimal, octal, hex)
      "-?([1-9][0-9]*|0[xX][0-9a-fA-F]+|0[0-7]*)" as s, rest => {
        let value = 0 // TODO: parse Int from string
        push(INTERGER(value), s.length())
        input = rest
      }

      // PDF Names: /Name (starts with solidus)
      // Simple version - alphanumeric names only
      "/[a-zA-Z_][a-zA-Z0-9_]*" as s, rest => {
        let value = b"" // TODO: convert name to Bytes (including the leading /)
        push(NAME(value), s.length())
        input = rest
      }

      // Literal strings: (text with possible escape sequences)
      // Simplified version without nested parentheses for now
      "\\([^)]*\\)" as s, rest => {
        let value = b"" // TODO: parse string content and convert to Bytes
        push(STRING(value), s.length())
        input = rest
      }

      // Hexadecimal strings: <hex digits and whitespace>
      "<[0-9a-fA-F \t\r\n]*>" as s, rest => {
        let value = b"" // TODO: parse hex content and convert to Bytes
        push(STRING(value), s.length())
        input = rest
      }

      // Single character delimiters
      "\(", rest => {
        push(LEFT_PARENTHESIS, 1)
        input = rest
      }
      "\)", rest => {
        push(RIGHT_PARENTHESIS, 1)
        input = rest
      }
      "[{]", rest => {
        push(LEFT_CURLY_BRACE, 1)
        input = rest
      }
      "[}]", rest => {
        push(RIGHT_CURLY_BRACE, 1)
        input = rest
      }
      "\[", rest => {
        push(LEFT_SQUARE_BRACKET, 1)
        input = rest
      }
      "\]", rest => {
        push(RIGHT_SQUARE_BRACKET, 1)
        input = rest
      }
      "<", rest => {
        push(LESS_THAN_SIGN, 1)
        input = rest
      }
      ">", rest => {
        push(GREATER_THAN_SIGN, 1)
        input = rest
      }
      "/", rest => {
        push(SOLIDUS, 1)
        input = rest
      }

      // End of input
      "$", _ => {
        push(EOF, 0)
        break
      }

      // Any other character (error case)
      _ => panic()
    }
  }
  result
}
