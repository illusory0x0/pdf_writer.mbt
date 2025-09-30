///|
test "tokenize_file with comments between sections" {
  let pdf_content =
    #|%PDF-1.4
    #|% This is a comment after header
    #|1 0 obj
    #|null
    #|endobj
    #|% Comment after body
    #|xref
    #|0 2
    #|0000000000 65535 f 
    #|0000000009 00000 n
    #|% Comment after xref
    #|trailer
    #|<<
    #|/Size 2
    #|>>
    #|% Comment after trailer
    #|startxref
    #|35
    #|%%EOF
    #|
  let input = @encoding/utf8.encode(pdf_content)
  let result = try? @pdf_file_lexer.tokenize_file(input)

  // Should successfully parse despite comments
  @json.inspect(result is Ok(_), content=true)
  match result {
    Ok(file_result) => {
      // Verify header was parsed correctly
      @json.inspect(file_result.value.header, content={ "major": 1, "minor": 4 })

      // Verify body has one object (Body is Array[Obj], access via .0)
      @json.inspect(file_result.value.body.0.length(), content=1)

      // Verify xref table has 2 entries
      @json.inspect(file_result.value.xref_table.entries.length(), content=2)
    }
    Err(_) => fail("Should not have failed to parse")
  }
}

///|
test "tokenize_file without comments" {
  let pdf_content =
    #|%PDF-1.4
    #|1 0 obj
    #|null
    #|endobj
    #|xref
    #|0 2
    #|0000000000 65535 f 
    #|0000000009 00000 n
    #|trailer
    #|<<
    #|/Size 2
    #|>>
    #|startxref
    #|35
    #|%%EOF
    #|
  let input = @encoding/utf8.encode(pdf_content)
  let result = try? @pdf_file_lexer.tokenize_file(input)

  // Should also successfully parse without comments
  @json.inspect(result is Ok(_), content=true)
  match result {
    Ok(file_result) => {
      // Verify header was parsed correctly
      @json.inspect(file_result.value.header, content={ "major": 1, "minor": 4 })

      // Verify body has one object (Body is Array[Obj], access via .0)
      @json.inspect(file_result.value.body.0.length(), content=1)

      // Verify xref table has 2 entries
      @json.inspect(file_result.value.xref_table.entries.length(), content=2)
    }
    Err(_) => fail("Should not have failed to parse")
  }
}
