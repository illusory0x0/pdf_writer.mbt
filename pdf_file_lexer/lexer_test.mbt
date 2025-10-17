///|
fn bytes_concat(bs : Array[Bytes]) -> Bytes {
  let buffer = @buffer.new(size_hint=1024)
  for b in bs {
    buffer.write_bytes(b)
  }
  buffer.to_bytes()
}

///|
test "byte_offset" {
  let file_header = b"%PDF-1.4\n"
  let body = [b"1 0 obj\n", b"null\n", b"endobj\n"]
  let xref_table = [
    b"xref\n", b"0 2\n", b"0000000000 65535 f \n", b"000000009 00000 n\n",
  ]
  let trailer = [
    b"trailer\n", b"<</Size 2 /Root 1 0 R>>\n", b"startxref\n", b"29\n", b"%%EOF\n",
  ]
  let file = bytes_concat([file_header, ..body, ..xref_table, ..trailer])
  let result = @pdf_file_lexer.tokenize_file(file)
  inspect(file_header.length(), content="9")
  inspect(result.value.body.0[0].bytes_offset, content="9")
  inspect(file.length() - result.rest.length(), content="126")
  inspect(result.bytes_offset, content="126")
  inspect(result.value.start_xref_pos, content="29")
  inspect(
    file_header.length() + body.fold(init=0, (acc, x) => acc + x.length()),
    content="29",
  )
  @json.inspect(result, content={
    "value": {
      "header": { "major": 1, "minor": 4 },
      "body": [
        {
          "bytes_offset": 9,
          "object_num": 1,
          "generation_num": 0,
          "obj_bytes": "null\\n",
        },
      ],
      "xref_table": {
        "entries": [
          { "bytes_offset": 0, "generation_num": 65535, "state": "Free" },
          { "bytes_offset": 9, "generation_num": 0, "state": "InUse" },
        ],
        "start_num": 0,
      },
      "trailer": "<</Size 2 /Root 1 0 R>>",
      "start_xref_pos": 29,
    },
    "bytes_offset": 126,
    "rest": "\\n",
  })
}

///|
test "testing ./output/*" {
  let files = @fs.read_dir("./output")
  for file in files {
    let file = "./output/\{file}"
    let file = @fs.read_file_to_bytes(file)
    let result = @pdf_file_lexer.tokenize_file(file)
    ignore(result)
  }
}

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

///|
test {
  let input = b"4 0 obj \x0a<<\x0a/Border [0 0 0]\x0a/Subtype /Link\x0a/C [0 0 0]\x0a/A \x0a<<\x0a/URI (http://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2006:033:0001:0017:EN:PDF#page=8)\x0a/S /URI\x0a>>\x0a/Type /Annot\x0a/Rect [312 719 469 735]\x0a>>\x0aendobj"
  let result = tokenize_body(input, 0)
  @json.inspect(result, content={
    "value": [],
    "bytes_offset": 0,
    "rest": "4 0 obj \\n<<\\n/Border [0 0 0]\\n/Subtype /Link\\n/C [0 0 0]\\n/A \\n<<\\n/URI (http://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2006:033:0001:0017:EN:PDF#page=8)\\n/S /URI\\n>>\\n/Type /Annot\\n/Rect [312 719 469 735]\\n>>\\nendobj",
  })
}
