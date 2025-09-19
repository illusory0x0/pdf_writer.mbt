///|
test "PDF comment lexing with different end-of-line markers" {
  // Test PDF comments with \r\n (CRLF)
  let input1 = "% This is a comment\r\ntrue"
  let tokens1 = tokenize(input1)
  // Should tokenize TRUE after the comment and newline
  let token_kinds1 = tokens1.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds1, content="[TRUE, EOF]")

  // Test PDF comments with \r (CR only)
  let input2 = "% This is a comment\rtrue"
  let tokens2 = tokenize(input2)
  let token_kinds2 = tokens2.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds2, content="[TRUE, EOF]")

  // Test PDF comments with \n (LF only)
  let input3 = "% This is a comment\ntrue"
  let tokens3 = tokenize(input3)
  let token_kinds3 = tokens3.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds3, content="[TRUE, EOF]")

  // Test PDF comment at end of file (no end-of-line marker)
  let input4 = "true % This is a comment"
  let tokens4 = tokenize(input4)
  let token_kinds4 = tokens4.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds4, content="[TRUE, EOF]")

  // Test multiple comments with different end-of-line markers
  let input5 = "% Comment 1\r\n% Comment 2\r% Comment 3\ntrue"
  let tokens5 = tokenize(input5)
  let token_kinds5 = tokens5.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds5, content="[TRUE, EOF]")
}

///|
test "PDF comment position tracking" {
  // Test that row/column positions are correctly updated after comments
  let input = "% Comment line 1\n% Comment line 2\ntrue"
  let tokens = tokenize(input)

  // The TRUE token should be at row 2 (after two comment lines)
  let true_token = tokens[0]
  let (_, start_pos, _) = true_token
  inspect(start_pos.row, content="2")
  inspect(start_pos.col, content="0")
}

///|

///|
test "ascii_string_of_bytes escaping" {
  // Test normal printable characters
  let normal = b"Hello World"
  inspect(ascii_string_of_bytes(normal), content="Hello World")

  // Test escape sequences
  let with_newline = b"Hello\nWorld"
  inspect(ascii_string_of_bytes(with_newline), content="Hello\\nWorld")
  let with_tab = b"Hello\tWorld"
  inspect(ascii_string_of_bytes(with_tab), content="Hello\\tWorld")
  let with_backslash = b"Hello\\World"
  inspect(ascii_string_of_bytes(with_backslash), content="Hello\\\\World")

  // Test non-printable characters (control characters)
  let with_bell : Array[Byte] = [
    72, 101, 108, 108, 111, 7, 87, 111, 114, 108, 100,
  ] // "Hello\x07World"
  inspect(
    ascii_string_of_bytes(Bytes::from_array(with_bell)),
    content="Hello\\007World",
  )

  // Test form feed
  let with_form_feed = b"Hello\x0cWorld"
  inspect(ascii_string_of_bytes(with_form_feed), content="Hello\\fWorld")
}

///|
test "tokenize_pdf_literal basic escape sequences" {
  // Test basic escape sequences
  let input1 = "Hello\\nWorld"
  let result1 = tokenize_pdf_literal(input1)
  inspect(ascii_string_of_bytes(result1), content="Hello\\nWorld")
  let input2 = "Tab\\tSeparated"
  let result2 = tokenize_pdf_literal(input2)
  inspect(ascii_string_of_bytes(result2), content="Tab\\tSeparated")
  let input3 = "Backslash\\\\Test"
  let result3 = tokenize_pdf_literal(input3)
  inspect(ascii_string_of_bytes(result3), content="Backslash\\\\Test")
  let input4 = "Parens\\(\\)Test"
  let result4 = tokenize_pdf_literal(input4)
  inspect(ascii_string_of_bytes(result4), content="Parens()Test")
}

///|
test "tokenize_pdf_literal octal escape sequences" {
  // Test 3-digit octal escape sequences
  let input1 = "Hello\\101World" // \101 is 'A' (65)
  let result1 = tokenize_pdf_literal(input1)
  inspect(ascii_string_of_bytes(result1), content="HelloAWorld")

  // Test 2-digit octal escape sequences
  let input2 = "Bell\\07Sound" // \07 is bell character
  let result2 = tokenize_pdf_literal(input2)
  inspect(ascii_string_of_bytes(result2), content="Bell\\007Sound")

  // Test 1-digit octal escape sequences
  let input3 = "Null\\0Char" // \0 is null character
  let result3 = tokenize_pdf_literal(input3)
  inspect(ascii_string_of_bytes(result3), content="Null\\000Char")
}

///|
test "tokenize_pdf_literal end-of-line handling" {
  // Test CRLF conversion to LF
  let input1 = "Line1\r\nLine2"
  let result1 = tokenize_pdf_literal(input1)
  inspect(ascii_string_of_bytes(result1), content="Line1\\nLine2")

  // Test CR conversion to LF
  let input2 = "Line1\rLine2"
  let result2 = tokenize_pdf_literal(input2)
  inspect(ascii_string_of_bytes(result2), content="Line1\\nLine2")

  // Test LF remains LF
  let input3 = "Line1\nLine2"
  let result3 = tokenize_pdf_literal(input3)
  inspect(ascii_string_of_bytes(result3), content="Line1\\nLine2")
}

///|
test "tokenize_pdf_literal multi-line continuation" {
  // Test backslash followed by CRLF (should be ignored)
  let input1 = "Line1\\\r\nLine2"
  let result1 = tokenize_pdf_literal(input1)
  inspect(ascii_string_of_bytes(result1), content="Line1Line2")

  // Test backslash followed by CR (should be ignored)
  let input2 = "Line1\\\rLine2"
  let result2 = tokenize_pdf_literal(input2)
  inspect(ascii_string_of_bytes(result2), content="Line1Line2")

  // Test backslash followed by LF (should be ignored)
  let input3 = "Line1\\\nLine2"
  let result3 = tokenize_pdf_literal(input3)
  inspect(ascii_string_of_bytes(result3), content="Line1Line2")
}

///|
test "tokenize_pdf_literal complex mixed content" {
  // Test combination of various escape sequences and content
  let input = "Start\\n\\tIndented\\\\Path\\(param\\)\\101nd\\12Bell\\0Null"
  let result = tokenize_pdf_literal(input)
  inspect(
    ascii_string_of_bytes(result),
    content="Start\\n\\tIndented\\\\Path(param)And\\nBell\\000Null",
  )
}

///|
test "tokenize_pdf_literal edge cases" {
  // Test empty string
  let input1 = ""
  let result1 = tokenize_pdf_literal(input1)
  inspect(ascii_string_of_bytes(result1), content="")

  // Test unrecognized escape sequence (backslash should be ignored)
  let input2 = "Test\\zInvalid"
  let result2 = tokenize_pdf_literal(input2)
  inspect(ascii_string_of_bytes(result2), content="TestInvalid")

  // Test form feed escape
  let input3 = "Page1\\fPage2"
  let result3 = tokenize_pdf_literal(input3)
  inspect(ascii_string_of_bytes(result3), content="Page1\\fPage2")

  // Test backspace escape
  let input4 = "Back\\bSpace"
  let result4 = tokenize_pdf_literal(input4)
  inspect(ascii_string_of_bytes(result4), content="Back\\bSpace")

  // Test carriage return escape
  let input5 = "Car\\rReturn"
  let result5 = tokenize_pdf_literal(input5)
  inspect(ascii_string_of_bytes(result5), content="Car\\rReturn")
}

///|
fn ascii_string_of_bytes(bytes : Bytes) -> String {
  let buffer = StringBuilder::new(size_hint=bytes.length() * 2)
  for b in bytes {
    // if b is non printable, please escape it
    match b {
      '\\' => buffer.write_string("\\\\")
      '\n' => buffer.write_string("\\n")
      '\r' => buffer.write_string("\\r")
      '\t' => buffer.write_string("\\t")
      '\b' => buffer.write_string("\\b")
      '\x0c' => buffer.write_string("\\f") // form feed
      c if c.to_int() < 32 || c.to_int() > 126 => {
        // Non-printable ASCII: use octal escape sequence
        let code = c.to_int()
        buffer.write_string("\\")
        buffer.write_string((code / 64).to_string())
        buffer.write_string((code % 64 / 8).to_string())
        buffer.write_string((code % 8).to_string())
      }
      c => buffer.write_char(c.to_char())
    }
  }
  buffer.to_string()
}
