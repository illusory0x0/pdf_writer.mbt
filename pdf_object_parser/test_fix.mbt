///|
/// Test to demonstrate the fix for tokenize_pdf_name delimiter handling
test "demonstrate_tokenize_pdf_name_fix" {
  // Test that PDF names stop at spaces
  let input1 = b"Name Test"
  let (result1, offset1) = tokenize_pdf_name(input1)
  inspect(ascii_string_of_bytesview(result1), content="Name")
  inspect(offset1, content="4") // Should stop at position 4 (before space)

  // Test that PDF names stop at forward slash (preventing the old issue)
  let input2 = b"Name/Another"
  let (result2, offset2) = tokenize_pdf_name(input2)
  inspect(ascii_string_of_bytesview(result2), content="Name")
  inspect(offset2, content="4") // Should stop at position 4 (before slash)

  // Test in full tokenizer context with a complete PDF name token
  let input3 = b"/Name/Another"
  let tokens = tokenize(input3).map(triple => triple.0)
  inspect(tokens, content="[NAME(/Name), NAME(/Another), EOF]") // Two separate NAME tokens

  // Verify that names with delimiters work correctly in a real scenario
  let input4 = b"/Type /Font /Size 12"
  let tokens4 = tokenize(input4).map(triple => triple.0)
  inspect(
    tokens4,
    content="[NAME(/Type), NAME(/Font), NAME(/Size), INTEGER(12), EOF]",
  )
}

///|
test {
  let stm = b"<</hello null>>\nstream  hello world \nendstream"
  let tokens = tokenize(stm)
  inspect(
    tokens.map(triple => triple.0),
    content="[DICT_BEGIN, NAME(/hello), NULL, DICT_END, STREAM_BYTES(  hello world \\n), EOF]",
  )
  let result = parse(tokens) catch {
    UnexpectedToken(tok, range, kinds) => {
      println(tok)
      println(range)
      println(kinds)
      panic()
    }
    UnexpectedEndOfInput(_, _) => panic()
    _ => panic()
  }
  @json.inspect(result, content=[
    "Stream",
    ["Dictionary", [["/hello", "Null"]]],
    ["Stream", "  hello world \\x0a"],
  ])
  // let result = parse(tokens)
}
