///|
fnalias @helper.ascii_string_of_bytesview

///|
test "PDF comment lexing with different end-of-line markers" {
  // Test PDF comments with \r\n (CRLF)
  let input1 = b"% This is a comment\r\ntrue"
  let tokens1 = tokenize(input1)
  // Should tokenize TRUE after the comment and newline
  let token_kinds1 = tokens1.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds1, content="[TRUE, EOF]")

  // Test PDF comments with \r (CR only)
  let input2 = b"% This is a comment\rtrue"
  let tokens2 = tokenize(input2)
  let token_kinds2 = tokens2.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds2, content="[TRUE, EOF]")

  // Test PDF comments with \n (LF only)
  let input3 = b"% This is a comment\ntrue"
  let tokens3 = tokenize(input3)
  let token_kinds3 = tokens3.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds3, content="[TRUE, EOF]")

  // Test PDF comment at end of file (no end-of-line marker)
  let input4 = b"true % This is a comment"
  let tokens4 = tokenize(input4)
  let token_kinds4 = tokens4.map(fn(triplet) {
    let (tok, _, _) = triplet
    tok
  })
  inspect(token_kinds4, content="[TRUE, EOF]")

  // Test multiple comments with different end-of-line markers
  let input5 = b"% Comment 1\r\n% Comment 2\r% Comment 3\ntrue"
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
  let input = b"% Comment line 1\n% Comment line 2\ntrue"
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
  inspect(ascii_string_of_bytesview(normal), content="Hello World")

  // Test escape sequences
  let with_newline = b"Hello\nWorld"
  inspect(ascii_string_of_bytesview(with_newline), content="Hello\\nWorld")
  let with_tab = b"Hello\tWorld"
  inspect(ascii_string_of_bytesview(with_tab), content="Hello\\tWorld")
  let with_backslash = b"Hello\\World"
  inspect(ascii_string_of_bytesview(with_backslash), content="Hello\\\\World")

  // Test non-printable characters (control characters)
  let with_bell : Array[Byte] = [
    72, 101, 108, 108, 111, 7, 87, 111, 114, 108, 100,
  ] // "Hello\x07World"
  inspect(
    ascii_string_of_bytesview(Bytes::from_array(with_bell)),
    content="Hello\\007World",
  )

  // Test form feed
  let with_form_feed = b"Hello\x0cWorld"
  inspect(ascii_string_of_bytesview(with_form_feed), content="Hello\\fWorld")
}

///|
test "tokenize_pdf_name basic characters" {
  // Test normal ASCII printable characters
  let input1 = b"SimpleNameTest"
  let (result1, offset1) = tokenize_pdf_name(input1)
  inspect(ascii_string_of_bytesview(result1), content="SimpleNameTest")
  inspect(offset1, content="14")

  // Test with numbers and underscores
  let input2 = b"Name123_Test"
  let (result2, offset2) = tokenize_pdf_name(input2)
  inspect(ascii_string_of_bytesview(result2), content="Name123_Test")
  inspect(offset2, content="12")

  // Test empty input
  let input3 = b""
  let (result3, offset3) = tokenize_pdf_name(input3)
  inspect(ascii_string_of_bytesview(result3), content="")
  inspect(offset3, content="0")
}

///|
test "tokenize_pdf_name hex escape sequences" {
  // Test basic hex escape sequences
  let input1 = b"Name#41Test" // #41 is 'A' (65)
  let (result1, offset1) = tokenize_pdf_name(input1)
  inspect(ascii_string_of_bytesview(result1), content="NameATest")
  inspect(offset1, content="11")

  // Test lowercase hex
  let input2 = b"Name#61Test" // #61 is 'a' (97)
  let (result2, offset2) = tokenize_pdf_name(input2)
  inspect(ascii_string_of_bytesview(result2), content="NameaTest")
  inspect(offset2, content="11")

  // Test uppercase hex
  let input3 = b"Name#4FTest" // #4F is 'O' (79)
  let (result3, offset3) = tokenize_pdf_name(input3)
  inspect(ascii_string_of_bytesview(result3), content="NameOTest")
  inspect(offset3, content="11")

  // Test mixed case hex
  let input4 = b"Name#4fTest" // #4f is 'O' (79)
  let (result4, offset4) = tokenize_pdf_name(input4)
  inspect(ascii_string_of_bytesview(result4), content="NameOTest")
  inspect(offset4, content="11")
}

///|
test "tokenize_pdf_name special characters" {
  // Test space escape
  let input1 = b"Name#20Test" // #20 is space (32)
  let (result1, offset1) = tokenize_pdf_name(input1)
  inspect(ascii_string_of_bytesview(result1), content="Name Test")
  inspect(offset1, content="11")

  // Test null character
  let input2 = b"Name#00Test" // #00 is null (0)
  let (result2, offset2) = tokenize_pdf_name(input2)
  inspect(ascii_string_of_bytesview(result2), content="Name\\000Test")
  inspect(offset2, content="11")

  // Test control character
  let input3 = b"Name#07Test" // #07 is bell (7)
  let (result3, offset3) = tokenize_pdf_name(input3)
  inspect(ascii_string_of_bytesview(result3), content="Name\\007Test")
  inspect(offset3, content="11")
}

///|
test "tokenize_pdf_name edge cases" {
  // Test invalid hex sequences (should treat # as literal)
  let input1 = b"Name#GGTest" // Invalid hex characters
  let (result1, offset1) = tokenize_pdf_name(input1)
  inspect(ascii_string_of_bytesview(result1), content="Name#GGTest")
  inspect(offset1, content="11")

  // Test incomplete hex sequence at end
  let input2 = b"Name#4" // Incomplete, should be treated as #40
  let (result2, offset2) = tokenize_pdf_name(input2)
  inspect(ascii_string_of_bytesview(result2), content="Name@") // #40 is '@' (64)
  inspect(offset2, content="6")

  // Test lone # at end
  let input3 = b"Name#"
  let (result3, offset3) = tokenize_pdf_name(input3)
  inspect(ascii_string_of_bytesview(result3), content="Name#")
  inspect(offset3, content="5")

  // Test invalid single hex character
  let input4 = b"Name#XY" // X is invalid
  let (result4, offset4) = tokenize_pdf_name(input4)
  inspect(ascii_string_of_bytesview(result4), content="Name#XY")
  inspect(offset4, content="7")
}

///|
test "tokenize_pdf_hexadecimal_string basic hex pairs" {
  // Test basic hex pairs
  let input1 = b"48656C6C6F" // "Hello" in hex
  let result1 = tokenize_pdf_hexadecimal_string(input1[:])
  inspect(ascii_string_of_bytesview(result1), content="Hello")

  // Test with lowercase hex
  let input2 = b"48656c6c6f" // "Hello" in hex (lowercase)
  let result2 = tokenize_pdf_hexadecimal_string(input2[:])
  inspect(ascii_string_of_bytesview(result2), content="Hello")

  // Test mixed case hex
  let input3 = b"48656C6c6F" // "Hello" in hex (mixed case)
  let result3 = tokenize_pdf_hexadecimal_string(input3[:])
  inspect(ascii_string_of_bytesview(result3), content="Hello")

  // Test empty input
  let input4 = b""
  let result4 = tokenize_pdf_hexadecimal_string(input4[:])
  inspect(ascii_string_of_bytesview(result4), content="")
}

///|
test "tokenize_pdf_name delimiter handling" {
  // Test name stops at space
  let input1 = b"Name Test"
  let (result1, offset1) = tokenize_pdf_name(input1)
  inspect(ascii_string_of_bytesview(result1), content="Name")
  inspect(offset1, content="4")

  // Test name stops at forward slash
  let input2 = b"Name/Test"
  let (result2, offset2) = tokenize_pdf_name(input2)
  inspect(ascii_string_of_bytesview(result2), content="Name")
  inspect(offset2, content="4")

  // Test name stops at left parenthesis
  let input3 = b"Name(Test"
  let (result3, offset3) = tokenize_pdf_name(input3)
  inspect(ascii_string_of_bytesview(result3), content="Name")
  inspect(offset3, content="4")

  // Test name stops at right parenthesis
  let input4 = b"Name)Test"
  let (result4, offset4) = tokenize_pdf_name(input4)
  inspect(ascii_string_of_bytesview(result4), content="Name")
  inspect(offset4, content="4")

  // Test name stops at left bracket
  let input5 = b"Name[Test"
  let (result5, offset5) = tokenize_pdf_name(input5)
  inspect(ascii_string_of_bytesview(result5), content="Name")
  inspect(offset5, content="4")

  // Test name stops at right bracket
  let input6 = b"Name]Test"
  let (result6, offset6) = tokenize_pdf_name(input6)
  inspect(ascii_string_of_bytesview(result6), content="Name")
  inspect(offset6, content="4")

  // Test name stops at angle brackets
  let input7 = b"Name<Test"
  let (result7, offset7) = tokenize_pdf_name(input7)
  inspect(ascii_string_of_bytesview(result7), content="Name")
  inspect(offset7, content="4")
  let input8 = b"Name>Test"
  let (result8, offset8) = tokenize_pdf_name(input8)
  inspect(ascii_string_of_bytesview(result8), content="Name")
  inspect(offset8, content="4")

  // Test name stops at comment start
  let input9 = b"Name%comment"
  let (result9, offset9) = tokenize_pdf_name(input9)
  inspect(ascii_string_of_bytesview(result9), content="Name")
  inspect(offset9, content="4")

  // Test name stops at tab
  let input10 = b"Name\tTest"
  let (result10, offset10) = tokenize_pdf_name(input10)
  inspect(ascii_string_of_bytesview(result10), content="Name")
  inspect(offset10, content="4")

  // Test name stops at newline
  let input11 = b"Name\nTest"
  let (result11, offset11) = tokenize_pdf_name(input11)
  inspect(ascii_string_of_bytesview(result11), content="Name")
  inspect(offset11, content="4")
}

///|
test "tokenize_pdf_hexadecimal_string whitespace handling" {
  // Test with spaces between hex pairs
  let input1 = b"48 65 6C 6C 6F" // "Hello" with spaces
  let result1 = tokenize_pdf_hexadecimal_string(input1[:])
  inspect(ascii_string_of_bytesview(result1), content="Hello")

  // Test with tabs between hex pairs
  let input2 = b"48\t65\t6C\t6C\t6F" // "Hello" with tabs
  let result2 = tokenize_pdf_hexadecimal_string(input2[:])
  inspect(ascii_string_of_bytesview(result2), content="Hello")

  // Test with CR and LF
  let input3 = b"48\r65\n6C\r\n6C\n6F" // "Hello" with CR/LF
  let result3 = tokenize_pdf_hexadecimal_string(input3[:])
  inspect(ascii_string_of_bytesview(result3), content="Hello")

  // Test with mixed whitespace
  let input4 = b"48 \t\r\n65 6C\t6C 6F" // "Hello" with mixed whitespace
  let result4 = tokenize_pdf_hexadecimal_string(input4[:])
  inspect(ascii_string_of_bytesview(result4), content="Hello")

  // Test whitespace at beginning and end
  let input5 = b" \t48656C6C6F \r\n" // "Hello" with surrounding whitespace
  let result5 = tokenize_pdf_hexadecimal_string(input5[:])
  inspect(ascii_string_of_bytesview(result5), content="Hello")
}

///|
test "tokenize_pdf_hexadecimal_string odd number of digits" {
  // Test single odd digit - should be treated as followed by 0
  let input1 = b"4" // Should become 0x40 = 64 = '@'
  let result1 = tokenize_pdf_hexadecimal_string(input1[:])
  inspect(ascii_string_of_bytesview(result1), content="@")

  // Test multiple pairs plus one odd digit
  let input2 = b"48656C6C6F4" // "Hello" + 0x40 = "Hello@"
  let result2 = tokenize_pdf_hexadecimal_string(input2[:])
  inspect(ascii_string_of_bytesview(result2), content="Hello@")

  // Test odd digit with whitespace
  let input3 = b"48 65 6C 6C 6F 4" // "Hello" + 0x40 with spaces
  let result3 = tokenize_pdf_hexadecimal_string(input3[:])
  inspect(ascii_string_of_bytesview(result3), content="Hello@")

  // Test various odd digits
  let input4 = b"A" // Should become 0xA0 = 160
  let result4 = tokenize_pdf_hexadecimal_string(input4[:])
  inspect(result4.to_array(), content="[b'\\xA0']")
  let input5 = b"F" // Should become 0xF0 = 240
  let result5 = tokenize_pdf_hexadecimal_string(input5[:])
  inspect(result5.to_array(), content="[b'\\xF0']")
}

///|
test "tokenize_pdf_hexadecimal_string non-hex characters" {
  // Test with non-hex characters that should be ignored
  let input1 = b"48G65H6CI6CJ6F" // "Hello" with G,H,I,J that should be ignored
  let result1 = tokenize_pdf_hexadecimal_string(input1[:])
  inspect(ascii_string_of_bytesview(result1), content="Hello")

  // Test with punctuation mixed in
  let input2 = b"48!65@6C#6C$6F" // "Hello" with punctuation
  let result2 = tokenize_pdf_hexadecimal_string(input2[:])
  inspect(ascii_string_of_bytesview(result2), content="Hello")

  // Test with only non-hex characters
  let input3 = b"GHIJKLMNOP"
  let result3 = tokenize_pdf_hexadecimal_string(input3[:])
  inspect(ascii_string_of_bytesview(result3), content="")

  // Test mix of hex and non-hex with odd count
  let input4 = b"4G8H6I5J" // Should parse as 48,65 = "He"
  let result4 = tokenize_pdf_hexadecimal_string(input4[:])
  inspect(ascii_string_of_bytesview(result4), content="He")
}

///|
test "tokenize_pdf_hexadecimal_string special byte values" {
  // Test null byte
  let input1 = b"00" // null byte
  let result1 = tokenize_pdf_hexadecimal_string(input1[:])
  inspect(ascii_string_of_bytesview(result1), content="\\000")

  // Test high values
  let input2 = b"FF" // 255
  let result2 = tokenize_pdf_hexadecimal_string(input2[:])
  inspect(result2.to_array(), content="[b'\\xFF']")

  // Test control characters
  let input3 = b"070809" // Bell, backspace, tab
  let result3 = tokenize_pdf_hexadecimal_string(input3[:])
  inspect(ascii_string_of_bytesview(result3), content="\\007\\b\\t")

  // Test newline and carriage return
  let input4 = b"0A0D" // LF, CR
  let result4 = tokenize_pdf_hexadecimal_string(input4[:])
  inspect(ascii_string_of_bytesview(result4), content="\\n\\r")
}

///|
test "tokenize_pdf_hexadecimal_string edge cases" {
  // Test only whitespace
  let input1 = b" \t\r\n"
  let result1 = tokenize_pdf_hexadecimal_string(input1[:])
  inspect(ascii_string_of_bytesview(result1), content="")

  // Test alternating hex and non-hex
  let input2 = b"4X8Y6Z5" // Should parse as 4,8,6,5 with odd digit at end
  let result2 = tokenize_pdf_hexadecimal_string(input2[:])
  // 0x48 = 'H', 0x65 = 'e', 0x50 = 'P' (5 followed by 0)
  inspect(ascii_string_of_bytesview(result2), content="He")

  // Test long string with various cases
  let input3 = b"48 65 6C 6C 6F 20 57 6F 72 6C 64 21" // "Hello World!"
  let result3 = tokenize_pdf_hexadecimal_string(input3[:])
  inspect(ascii_string_of_bytesview(result3), content="Hello World!")

  // Test very long hex string
  let input4 = b"546869732069732061206C6F6E67206865786164656369"
  let input4_cont = b"6D616C20737472696E6720746F2074657374"
  let combined_input = Bytes::from_array(
    input4.to_array() + input4_cont.to_array(),
  )
  let result4 = tokenize_pdf_hexadecimal_string(combined_input[:])
  inspect(
    ascii_string_of_bytesview(result4),
    content="This is a long hexadecimal string to test",
  )
}

///|
test "tokenize" {
  let input = b"/hello"
  let tokens = tokenize(input).map(triple => triple.0)
  inspect(tokens, content="[NAME(/hello), EOF]")
}

///|
test "tokenize basic literals" {
  // Test boolean literals
  let input1 = b"true false"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[TRUE, FALSE, EOF]")

  // Test integers
  let input2 = b"123 -456 0 42"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[INTEGER(123), INTEGER(-456), INTEGER(0), INTEGER(42), EOF]",
  )

  // Test real numbers
  let input3 = b"3.14 -2.5 .5 123. 1E10 -2.5E-3"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(
    tokens3,
    content="[REAL(3.14), REAL(-2.5), REAL(0.5), REAL(123), REAL(10000000000), REAL(-0.0025), EOF]",
  )
}

///|
test "tokenize delimiters" {
  // Test all delimiter tokens
  let input = b"() {} [] < > / << >>"
  let tokens = tokenize(input).map(triple => triple.0)
  inspect(
    tokens,
    content="[STRING(), LEFT_CURLY_BRACE, RIGHT_CURLY_BRACE, LEFT_SQUARE_BRACKET, RIGHT_SQUARE_BRACKET, STRING(), NAME(/), DICT_BEGIN, DICT_END, EOF]",
  )
}

///|
test "tokenize pdf names" {
  // Test simple PDF names
  let input1 = b"/Name /Type /Subtype"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[NAME(/Name), NAME(/Type), NAME(/Subtype), EOF]")

  // Test PDF names with numbers and underscores
  let input2 = b"/Name123 /_Private /Test_Name"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[NAME(/Name123), NAME(/_Private), NAME(/Test_Name), EOF]",
  )
}

///|
test "tokenize literal strings" {
  // Test simple literal strings
  let input1 = b"(Hello World) (Simple string)"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[STRING(Hello World), STRING(Simple string), EOF]")

  // Test literal strings with escape sequences
  let input2 = b"(Line1\\nLine2) (Tab\\tSeparated) (Quote\\\"Test)"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[STRING(Line1\\nLine2), STRING(Tab\\tSeparated), STRING(QuoteTest), EOF]",
  )
}

///|
test "tokenize hexadecimal strings" {
  // Test hexadecimal strings
  let input1 = b"<48656C6C6F> <576F726C64>"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[STRING(Hello), STRING(World), EOF]")

  // Test hex strings with whitespace
  let input2 = b"<48 65 6C 6C 6F> <57 6F 72 6C 64>"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[STRING(Hello), STRING(World), EOF]")

  // Test empty hex string
  let input3 = b"<>"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(tokens3, content="[STRING(), EOF]")
}

///|
test "tokenize mixed content" {
  // Test realistic PDF content mixing different token types
  let input = b"<< /Type /Catalog /Pages 123 /Count 5 >>"
  let tokens = tokenize(input).map(triple => triple.0)
  inspect(
    tokens,
    content="[DICT_BEGIN, NAME(/Type), NAME(/Catalog), NAME(/Pages), INTEGER(123), NAME(/Count), INTEGER(5), DICT_END, EOF]",
  )
}

///|
test "tokenize arrays and objects" {
  // Test array notation
  let input1 = b"[1 2 3 /Name (string)]"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(
    tokens1,
    content="[LEFT_SQUARE_BRACKET, INTEGER(1), INTEGER(2), INTEGER(3), NAME(/Name), STRING(string), RIGHT_SQUARE_BRACKET, EOF]",
  )

  // Test nested structures
  let input2 = b"{[/Key (Value)] << /Inner true >>}"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[LEFT_CURLY_BRACE, LEFT_SQUARE_BRACKET, NAME(/Key), STRING(Value), RIGHT_SQUARE_BRACKET, DICT_BEGIN, NAME(/Inner), TRUE, DICT_END, RIGHT_CURLY_BRACE, EOF]",
  )
}

///|
test "tokenize with comments" {
  // Test single line comment
  let input1 = b"true % this is a comment\nfalse"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[TRUE, FALSE, EOF]")

  // Test comment at end of file
  let input2 = b"123 % comment at end"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[INTEGER(123), EOF]")

  // Test multiple comments
  let input3 = b"% First comment\n42 % inline comment\n% Final comment\ntrue"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(tokens3, content="[INTEGER(42), TRUE, EOF]")
}

///|
test "tokenize with whitespace variations" {
  // Test different whitespace characters
  let input1 = b"true\t\ffalse"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[TRUE, FALSE, EOF]")

  // Test different newline variations
  let input2 = b"123\r\n456\r789\n000"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[INTEGER(123), INTEGER(456), INTEGER(789), INTEGER(0), EOF]",
  )
}

///|
test "tokenize numeric edge cases" {
  // Test different integer formats
  let input1 = b"0x1A 0xFF 077 0123"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(
    tokens1,
    content="[INTEGER(26), INTEGER(255), INTEGER(77), INTEGER(123), EOF]",
  )

  // Test scientific notation edge cases
  let input2 = b"1e5 1E-5 -1.5e+10 .5E10"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[REAL(100000), REAL(0.00001), REAL(-15000000000), REAL(5000000000), EOF]",
  )
}

///|
test "tokenize position tracking" {
  // Test that positions are correctly tracked
  let input = b"true\nfalse"
  let tokens = tokenize(input)

  // Check first token (true) position
  let (true_token, true_start, true_end) = tokens[0]
  inspect(true_token, content="TRUE")
  inspect(true_start.row, content="0")
  inspect(true_start.col, content="0")
  inspect(true_end.row, content="0")
  inspect(true_end.col, content="4")

  // Check second token (false) position
  let (false_token, false_start, false_end) = tokens[1]
  inspect(false_token, content="FALSE")
  inspect(false_start.row, content="1")
  inspect(false_start.col, content="0")
  inspect(false_end.row, content="1")
  inspect(false_end.col, content="5")
}

///|
test "tokenize complex pdf document structure" {
  // Test a realistic PDF object structure
  let input = @encoding/utf8.encode(
    (
      #|<< 
      #|  /Type /Page
      #|  /Parent 3 0 R
      #|  /MediaBox [0 0 612 792]
      #|  /Contents 5 0 R
      #|  /Resources << 
      #|    /Font << /F1 6 0 R >>
      #|    /ProcSet [/PDF /Text]
      #|  >>
      #|>>
      #|
    ),
  )
  let tokens = tokenize(input).map(triple => triple.0)
  // This tests a complex nested structure with various token types
  let expected_tokens = [
    "DICT_BEGIN", "NAME(Type)", "NAME(Page)", "NAME(Parent)", "INTEGER(3)", "INTEGER(0)",
    "NAME(R)", "NAME(MediaBox)", "LEFT_SQUARE_BRACKET", "INTEGER(0)", "INTEGER(0)",
    "INTEGER(612)", "INTEGER(792)", "RIGHT_SQUARE_BRACKET", "NAME(Contents)", "INTEGER(5)",
    "INTEGER(0)", "NAME(R)", "NAME(Resources)", "DICT_BEGIN", "NAME(Font)", "DICT_BEGIN",
    "NAME(F1)", "INTEGER(6)", "INTEGER(0)", "NAME(R)", "DICT_END", "NAME(ProcSet)",
    "LEFT_SQUARE_BRACKET", "NAME(PDF)", "NAME(Text)", "RIGHT_SQUARE_BRACKET", "DICT_END",
    "DICT_END", "EOF",
  ]

  // Convert to string representation for easier comparison
  let token_strings = tokens.map(Token::to_string)
  inspect(
    token_strings,
    content=(
      #|["DICT_BEGIN", "NAME(/Type)", "NAME(/Page)", "NAME(/Parent)", "INDIRECT(3, 0)", "NAME(/MediaBox)", "LEFT_SQUARE_BRACKET", "INTEGER(0)", "INTEGER(0)", "INTEGER(612)", "INTEGER(792)", "RIGHT_SQUARE_BRACKET", "NAME(/Contents)", "INDIRECT(5, 0)", "NAME(/Resources)", "DICT_BEGIN", "NAME(/Font)", "DICT_BEGIN", "NAME(/F1)", "INDIRECT(6, 0)", "DICT_END", "NAME(/ProcSet)", "LEFT_SQUARE_BRACKET", "NAME(/PDF)", "NAME(/Text)", "RIGHT_SQUARE_BRACKET", "DICT_END", "DICT_END", "EOF"]
    ),
  )
}

///|
test "tokenize empty and edge inputs" {
  // Test empty input
  let input1 = b""
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[EOF]")

  // Test only whitespace
  let input2 = b"   \t  \n  \r\n  "
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[EOF]")

  // Test only comments
  let input3 = b"% just a comment\n% another comment"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(tokens3, content="[EOF]")
}

///|
test "tokenize string escaping comprehensive" {
  // Test complex string with multiple escape types
  let input = b"(Start\\n\\tIndented\\\\Path\\(param\\)\\101nd\\12Bell\\0Null)"
  let tokens = tokenize(input).map(triple => triple.0)
  // This should parse the escape sequences according to PDF literal string rules
  inspect(
    tokens,
    content="[STRING(Start\\n\\tIndented\\\\Path(param)And\\nBell\\000Null), EOF]",
  )

  // Test multiline string continuation
  let input2 = b"(Line1\\\nLine2)"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[STRING(Line1Line2), EOF]")
}

///|
test "tokenize hex string edge cases" {
  // Test hex string with odd number of digits
  let input1 = b"<48656C6C6F4>"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[STRING(Hello@), EOF]")

  // Test hex string with non-hex characters (should be ignored)
  let input2 = b"<48G65H6CI6CJ6F>"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(
    tokens2,
    content="[LESS_THAN_SIGN, INTEGER(48), INTEGER(65), INTEGER(6), INTEGER(6), INTEGER(6), GREATER_THAN_SIGN, EOF]",
  )

  // Test hex string with mixed case
  let input3 = b"<48656C6c6F>"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(tokens3, content="[STRING(Hello), EOF]")
}

///|
test "tokenize pdf name with escapes" {
  // Test PDF names with hex escape sequences  
  let input1 = b"/Name#20With#20Spaces"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[NAME(/Name With Spaces), EOF]")

  // Test PDF names with special characters
  let input2 = b"/Søren#20Åberg"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[NAME(/S\\303\\270ren \\303\\205berg), EOF]")
}

///|
test "tokenize error resilience" {
  // The tokenize function should handle most inputs gracefully
  // Test with mixed valid and potentially problematic content
  let input = b"true (unclosed string /name 123 false"
  let tokens = tokenize(input).map(triple => triple.0)

  // Should tokenize everything it can recognize
  inspect(
    tokens,
    content="[TRUE, STRING(unclosed string /name 123 false), EOF]",
  )
}

///|
test "tokenize pdf indirect object references" {
  // Test basic indirect object reference
  let input1 = b"123 0 R"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[INDIRECT(123, 0), EOF]")

  // Test indirect reference with different numbers
  let input2 = b"456 17 R"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[INDIRECT(456, 17), EOF]")

  // Test multiple indirect references
  let input3 = b"1 0 R 2 0 R 3 5 R"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(
    tokens3,
    content="[INDIRECT(1, 0), INDIRECT(2, 0), INDIRECT(3, 5), EOF]",
  )

  // Test indirect reference with extra whitespace
  let input4 = b"789  \t 42  \t R"
  let tokens4 = tokenize(input4).map(triple => triple.0)
  inspect(tokens4, content="[INDIRECT(789, 42), EOF]")

  // Test mixed content with indirect references
  let input5 = b"/Parent 3 0 R /Contents 5 0 R"
  let tokens5 = tokenize(input5).map(triple => triple.0)
  inspect(
    tokens5,
    content="[NAME(/Parent), INDIRECT(3, 0), NAME(/Contents), INDIRECT(5, 0), EOF]",
  )
}

///|
test "tokenize comprehensive integration" {
  // Test a comprehensive example with all token types
  let input = @encoding/utf8.encode(
    (
      #|% PDF document structure example
      #|<<
      #|  /Type /Catalog
      #|  /Version 1.4
      #|  /Pages << /Type /Pages /Count 2 >>
      #|  /Metadata (This is metadata)
      #|  /ViewerPreferences << /FitWindow true >>
      #|  /OpenAction [0 /XYZ null null 1.0]
      #|  /Names <4E616D6573>
      #|>>
      #|
    ),
  )
  let tokens = tokenize(input).map(triple => triple.0)

  // This integration test verifies that all major token types work together
  let found_token_types = []
  for token in tokens {
    let token_type = match token {
      TRUE | FALSE => "BOOLEAN"
      INTEGER(_) => "INTEGER"
      REAL(_) => "REAL"
      STRING(_) => "STRING"
      NAME(_) => "NAME"
      DICT_BEGIN | DICT_END => "DICT"
      LEFT_SQUARE_BRACKET | RIGHT_SQUARE_BRACKET => "ARRAY"
      EOF => "EOF"
      _ => "OTHER"
    }
    if not(found_token_types.contains(token_type)) {
      found_token_types.push(token_type)
    }
  }

  // Should find all major token types in this comprehensive example
  found_token_types.sort()
  inspect(
    found_token_types,
    content=(
      #|["EOF", "DICT", "NAME", "REAL", "ARRAY", "OTHER", "STRING", "BOOLEAN", "INTEGER"]
    ),
  )
}

///|
test {
  let input = b"true\n"
  let tokens = tokenize(input)
  inspect(tokens.length(), content="2")
  inspect(tokens[0], content="(TRUE, {row: 0, col: 0}, {row: 0, col: 4})")
  inspect(tokens[1], content="(EOF, {row: 1, col: 0}, {row: 1, col: 0})")
  inspect(
    tokens,
    content="[(TRUE, {row: 0, col: 0}, {row: 0, col: 4}), (EOF, {row: 1, col: 0}, {row: 1, col: 0})]",
  )
}

///|
test "tokenize stream data" {
  // Test basic stream with simple content
  let input1 = b"stream\nHello World\nendstream"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[STREAM_BYTES(Hello World\\n), EOF]")

  // Test stream with binary data
  let input2 = Bytes::from_array([
    115, 116, 114, 101, 97, 109, 10, // "stream\n"
     1, 2, 3, 4, // binary data
     101, 110, 100, 115, 116, 114, 101, 97, 109, // "endstream"
  ])
  let tokens2 = tokenize(input2).map(triple => triple.0)
  let stream_data = match tokens2[0] {
    STREAM_BYTES(data) => data.to_array()
    _ => []
  }
  inspect(stream_data, content="[b'\\x01', b'\\x02', b'\\x03', b'\\x04']")

  // Test stream with multiple lines
  let input3 = b"stream\nLine 1\nLine 2\nLine 3\nendstream"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(tokens3, content="[STREAM_BYTES(Line 1\\nLine 2\\nLine 3\\n), EOF]")

  // Test stream with different whitespace after "stream"
  let input4 = b"stream \t\r\nData after whitespace\nendstream"
  let tokens4 = tokenize(input4).map(triple => triple.0)
  inspect(
    tokens4,
    content="[STREAM_BYTES( \\t\\r\\nData after whitespace\\n), EOF]",
  )
}

///|
test "tokenize stream edge cases" {
  // Test empty stream
  let input1 = b"stream\nendstream"
  let tokens1 = tokenize(input1).map(triple => triple.0)
  inspect(tokens1, content="[STREAM_BYTES(), EOF]")

  // Test stream without endstream (should handle gracefully)
  let input2 = b"stream\nData without end"
  let tokens2 = tokenize(input2).map(triple => triple.0)
  inspect(tokens2, content="[STREAM_BYTES(), EOF]")

  // Test stream with endstream in the middle of data
  let input3 = b"stream\nThis has endstream word but\nendstream"
  let tokens3 = tokenize(input3).map(triple => triple.0)
  inspect(tokens3, content="[STREAM_BYTES(This has ), STREAM_BYTES(), EOF]")

  // Test immediate stream->endstream (no newline)
  let input4 = b"streamendstream"
  let tokens4 = tokenize(input4).map(triple => triple.0)
  inspect(tokens4, content="[STREAM_BYTES(), EOF]")
}
