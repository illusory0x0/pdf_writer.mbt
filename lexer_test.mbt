///|
test "PDF comment lexing with different end-of-line markers" {
  // Test PDF comments with \r\n (CRLF)
  let input1 = b"% This is a comment\r\ntrue"
  let tokens1 = tokenize(input1[:])
  // Should tokenize TRUE after the comment and newline
  let token_kinds1 = tokens1.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds1, content="[TRUE, EOF]")

  // Test PDF comments with \r (CR only)
  let input2 = b"% This is a comment\rtrue"
  let tokens2 = tokenize(input2[:])
  let token_kinds2 = tokens2.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds2, content="[TRUE, EOF]")

  // Test PDF comments with \n (LF only)
  let input3 = b"% This is a comment\ntrue"
  let tokens3 = tokenize(input3[:])
  let token_kinds3 = tokens3.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds3, content="[TRUE, EOF]")

  // Test PDF comment at end of file (no end-of-line marker)
  let input4 = b"true % This is a comment"
  let tokens4 = tokenize(input4[:])
  let token_kinds4 = tokens4.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds4, content="[TRUE, EOF]")

  // Test multiple comments with different end-of-line markers
  let input5 = b"% Comment 1\r\n% Comment 2\r% Comment 3\ntrue"
  let tokens5 = tokenize(input5[:])
  let token_kinds5 = tokens5.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds5, content="[TRUE, EOF]")
}

///|
test "PDF comment position tracking" {
  // Test that row/column positions are correctly updated after comments
  let input = b"% Comment line 1\n% Comment line 2\ntrue"
  let tokens = tokenize(input[:])

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
  let input1 = b"Hello\\nWorld"
  let result1 = tokenize_pdf_literal_string(input1[:])
  inspect(ascii_string_of_bytes(result1), content="Hello\\nWorld")
  let input2 = b"Tab\\tSeparated"
  let result2 = tokenize_pdf_literal_string(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Tab\\tSeparated")
  let input3 = b"Backslash\\\\Test"
  let result3 = tokenize_pdf_literal_string(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Backslash\\\\Test")
  let input4 = b"Parens\\(\\)Test"
  let result4 = tokenize_pdf_literal_string(input4[:])
  inspect(ascii_string_of_bytes(result4), content="Parens()Test")
}

///|
test "tokenize_pdf_literal octal escape sequences" {
  // Test 3-digit octal escape sequences
  let input1 = b"Hello\\101World" // \101 is 'A' (65)
  let result1 = tokenize_pdf_literal_string(input1[:])
  inspect(ascii_string_of_bytes(result1), content="HelloAWorld")

  // Test 2-digit octal escape sequences
  let input2 = b"Bell\\07Sound" // \07 is bell character
  let result2 = tokenize_pdf_literal_string(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Bell\\007Sound")

  // Test 1-digit octal escape sequences
  let input3 = b"Null\\0Char" // \0 is null character
  let result3 = tokenize_pdf_literal_string(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Null\\000Char")
}

///|
test "tokenize_pdf_literal end-of-line handling" {
  // Test CRLF conversion to LF
  let input1 = b"Line1\r\nLine2"
  let result1 = tokenize_pdf_literal_string(input1[:])
  inspect(ascii_string_of_bytes(result1), content="Line1\\nLine2")

  // Test CR conversion to LF
  let input2 = b"Line1\rLine2"
  let result2 = tokenize_pdf_literal_string(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Line1\\nLine2")

  // Test LF remains LF
  let input3 = b"Line1\nLine2"
  let result3 = tokenize_pdf_literal_string(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Line1\\nLine2")
}

///|
test "tokenize_pdf_literal multi-line continuation" {
  // Test backslash followed by CRLF (should be ignored)
  let input1 = b"Line1\\\r\nLine2"
  let result1 = tokenize_pdf_literal_string(input1[:])
  inspect(ascii_string_of_bytes(result1), content="Line1Line2")

  // Test backslash followed by CR (should be ignored)
  let input2 = b"Line1\\\rLine2"
  let result2 = tokenize_pdf_literal_string(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Line1Line2")

  // Test backslash followed by LF (should be ignored)
  let input3 = b"Line1\\\nLine2"
  let result3 = tokenize_pdf_literal_string(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Line1Line2")
}

///|
test "tokenize_pdf_literal complex mixed content" {
  // Test combination of various escape sequences and content
  let input = b"Start\\n\\tIndented\\\\Path\\(param\\)\\101nd\\12Bell\\0Null"
  let result = tokenize_pdf_literal_string(input[:])
  inspect(
    ascii_string_of_bytes(result),
    content="Start\\n\\tIndented\\\\Path(param)And\\nBell\\000Null",
  )
}

///|
test "tokenize_pdf_literal edge cases" {
  // Test empty string
  let input1 = b""
  let result1 = tokenize_pdf_literal_string(input1[:])
  inspect(ascii_string_of_bytes(result1), content="")

  // Test unrecognized escape sequence (backslash should be ignored)
  let input2 = b"Test\\zInvalid"
  let result2 = tokenize_pdf_literal_string(input2[:])
  inspect(ascii_string_of_bytes(result2), content="TestInvalid")

  // Test form feed escape
  let input3 = b"Page1\\fPage2"
  let result3 = tokenize_pdf_literal_string(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Page1\\fPage2")

  // Test backspace escape
  let input4 = b"Back\\bSpace"
  let result4 = tokenize_pdf_literal_string(input4[:])
  inspect(ascii_string_of_bytes(result4), content="Back\\bSpace")

  // Test carriage return escape
  let input5 = b"Car\\rReturn"
  let result5 = tokenize_pdf_literal_string(input5[:])
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

///|
test "tokenize_pdf_name basic characters" {
  // Test normal ASCII printable characters
  let input1 = b"SimpleNameTest"
  let result1 = tokenize_pdf_name(input1[:])
  inspect(ascii_string_of_bytes(result1), content="SimpleNameTest")

  // Test with numbers and underscores
  let input2 = b"Name123_Test"
  let result2 = tokenize_pdf_name(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Name123_Test")

  // Test empty input
  let input3 = b""
  let result3 = tokenize_pdf_name(input3[:])
  inspect(ascii_string_of_bytes(result3), content="")
}

///|
test "tokenize_pdf_name hex escape sequences" {
  // Test basic hex escape sequences
  let input1 = b"Name#41Test" // #41 is 'A' (65)
  let result1 = tokenize_pdf_name(input1[:])
  inspect(ascii_string_of_bytes(result1), content="NameATest")

  // Test lowercase hex
  let input2 = b"Name#61Test" // #61 is 'a' (97)
  let result2 = tokenize_pdf_name(input2[:])
  inspect(ascii_string_of_bytes(result2), content="NameaTest")

  // Test uppercase hex
  let input3 = b"Name#4FTest" // #4F is 'O' (79)
  let result3 = tokenize_pdf_name(input3[:])
  inspect(ascii_string_of_bytes(result3), content="NameOTest")

  // Test mixed case hex
  let input4 = b"Name#4fTest" // #4f is 'O' (79)
  let result4 = tokenize_pdf_name(input4[:])
  inspect(ascii_string_of_bytes(result4), content="NameOTest")
}

///|
test "tokenize_pdf_name special characters" {
  // Test space escape
  let input1 = b"Name#20Test" // #20 is space (32)
  let result1 = tokenize_pdf_name(input1[:])
  inspect(ascii_string_of_bytes(result1), content="Name Test")

  // Test null character
  let input2 = b"Name#00Test" // #00 is null (0)
  let result2 = tokenize_pdf_name(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Name\\000Test")

  // Test control character
  let input3 = b"Name#07Test" // #07 is bell (7)
  let result3 = tokenize_pdf_name(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Name\\007Test")
}

///|
test "tokenize_pdf_name edge cases" {
  // Test invalid hex sequences (should treat # as literal)
  let input1 = b"Name#GGTest" // Invalid hex characters
  let result1 = tokenize_pdf_name(input1[:])
  inspect(ascii_string_of_bytes(result1), content="Name#GGTest")

  // Test incomplete hex sequence at end
  let input2 = b"Name#4" // Incomplete, should be treated as #40
  let result2 = tokenize_pdf_name(input2[:])
  inspect(ascii_string_of_bytes(result2), content="Name@") // #40 is '@' (64)

  // Test lone # at end
  let input3 = b"Name#"
  let result3 = tokenize_pdf_name(input3[:])
  inspect(ascii_string_of_bytes(result3), content="Name#")

  // Test invalid single hex character
  let input4 = b"Name#XY" // X is invalid
  let result4 = tokenize_pdf_name(input4[:])
  inspect(ascii_string_of_bytes(result4), content="Name#XY")
}

///|
test "tokenize_pdf_name complex mixed content" {
  // Test combination of normal characters and hex escapes
  let input = b"Page#20Title#28Section#203#29"
  // #20 = space, #28 = '(', #29 = ')'
  let result = tokenize_pdf_name(input[:])
  inspect(ascii_string_of_bytes(result), content="Page Title(Section 3)")
}

///|
test "tokenize_pdf_name slash exclusion" {
  // Test that leading slash is excluded
  let input_with_slash = b"/TestName"
  let result_with_slash = tokenize_pdf_name(input_with_slash[:])
  inspect(ascii_string_of_bytes(result_with_slash), content="TestName")
  
  // Test that leading slash is excluded with hex escape
  let input_with_slash_hex = b"/Test#41Name"
  let result_with_slash_hex = tokenize_pdf_name(input_with_slash_hex[:])
  inspect(ascii_string_of_bytes(result_with_slash_hex), content="TestAName")
  
  // Test input without slash is unchanged
  let input_without_slash = b"TestName"
  let result_without_slash = tokenize_pdf_name(input_without_slash[:])
  inspect(ascii_string_of_bytes(result_without_slash), content="TestName")
  
  // Test edge case: just a slash
  let input_just_slash = b"/"
  let result_just_slash = tokenize_pdf_name(input_just_slash[:])
  inspect(ascii_string_of_bytes(result_just_slash), content="")
}