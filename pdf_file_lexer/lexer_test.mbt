///|
test {
  let input = b"%PDF-1.4\n"
  let result = @pdf_file_lexer.tokenize_header(input)
  @json.inspect(result, content={
    "value": { "major": 1, "minor": 4 },
    "bytes_offset": 9,
    "rest": "",
  })
}

///|
test "body" {
  let input = b"1 0 obj\nnull\nendobj\n"
  let result = @pdf_file_lexer.tokenize_body(input, 0)
  @json.inspect(result, content={
    "value": [
      {
        "bytes_offset": 20,
        "object_num": 1,
        "generation_num": 0,
        "obj_bytes": "null\\n",
      },
    ],
    "bytes_offset": 20,
    "rest": "",
  })
}

///|
test {
  let input =
    #|1 0 obj
    #|true 
    #|endobj
    #| 
    #|
  let input = @encoding/utf8.encode(input)
  let result = @pdf_file_lexer.tokenize_body(input, 0)
  @json.inspect(result, content={
    "value": [
      {
        "bytes_offset": 21,
        "object_num": 1,
        "generation_num": 0,
        "obj_bytes": "true \\n",
      },
    ],
    "bytes_offset": 21,
    "rest": " \\n",
  })
}

///|
test "tokenize_xref_entry - valid InUse entry" {
  let input = b"0000000000 00000 n\n"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 0)
  @json.inspect(result, content={
    "value": { "bytes_offset": 0, "generation_num": 0, "state": "InUse" },
    "bytes_offset": 19,
    "rest": "",
  })
}

///|
test "tokenize_xref_entry - valid Free entry" {
  let input = b"0000000009 00001 f \n"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 0)
  @json.inspect(result, content={
    "value": { "bytes_offset": 9, "generation_num": 1, "state": "Free" },
    "bytes_offset": 20,
    "rest": "",
  })
}

///|
test "tokenize_xref_entry - large offset and generation" {
  let input = b"1234567890 12345 n\n"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 100)
  @json.inspect(result, content={
    "value": {
      "bytes_offset": 1234567890,
      "generation_num": 12345,
      "state": "InUse",
    },
    "bytes_offset": 119,
    "rest": "",
  })
}

///|
test "tokenize_xref_entry - with remaining content" {
  let input = b"0000000015 00000 n\nextra content"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 50)
  @json.inspect(result, content={
    "value": { "bytes_offset": 15, "generation_num": 0, "state": "InUse" },
    "bytes_offset": 69,
    "rest": "extra content",
  })
}

///|
test "tokenize_xref_entry - Free entry with remaining content" {
  let input = b"0000000020 00002 f \nmore data here"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 0)
  @json.inspect(result, content={
    "value": { "bytes_offset": 20, "generation_num": 2, "state": "Free" },
    "bytes_offset": 20,
    "rest": "more data here",
  })
}

///|
test "tokenize_xref_entry - zero offset and generation" {
  let input = b"0000000000 00000 n\n"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 25)
  @json.inspect(result, content={
    "value": { "bytes_offset": 0, "generation_num": 0, "state": "InUse" },
    "bytes_offset": 44,
    "rest": "",
  })
}

///|
test "tokenize_xref_entry - minimal valid numbers" {
  let input = b"1 0 n\n"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 10)
  @json.inspect(result, content={
    "value": { "bytes_offset": 1, "generation_num": 0, "state": "InUse" },
    "bytes_offset": 16,
    "rest": "",
  })
}

///|
test "tokenize_xref_entry - minimal valid free entry" {
  let input = b"5 1 f \n"
  let result = @pdf_file_lexer.tokenize_xref_entry(input, 0)
  @json.inspect(result, content={
    "value": { "bytes_offset": 5, "generation_num": 1, "state": "Free" },
    "bytes_offset": 7,
    "rest": "",
  })
}

///|
test {
  let input =
    #|xref
    #|0 5
    #|0000000000 65535 f 
    #|0000000105 00000 n 
    #|0000000067 00000 n 
    #|0000000055 00000 n 
    #|0000000221 00000 n 
    #| 
    #|
  let input = @encoding/utf8.encode(input)
  let result = @pdf_file_lexer.tokenize_xref_table(input, 0)
  @json.inspect(result, content={
    "value": {
      "entries": [
        { "bytes_offset": 0, "generation_num": 65535, "state": "Free" },
        { "bytes_offset": 105, "generation_num": 0, "state": "InUse" },
        { "bytes_offset": 67, "generation_num": 0, "state": "InUse" },
        { "bytes_offset": 55, "generation_num": 0, "state": "InUse" },
        { "bytes_offset": 221, "generation_num": 0, "state": "InUse" },
      ],
      "start_num": 0,
    },
    "bytes_offset": 109,
    "rest": " \\n",
  })
}

///|
test {
  let file = @fs.read_file_to_bytes("./output/hello.pdf")
  let result = @pdf_file_lexer.tokenize_file(file)
  @json.inspect(result, content=({"value":{"header":{"major":1,"minor":4},"body":[{"bytes_offset":120,"object_num":1,"generation_num":0,"obj_bytes":"<<\\n  /Length 53\\n>>\\nstream\\n 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\\nendstream\\n"},{"bytes_offset":187,"object_num":2,"generation_num":0,"obj_bytes":"<<\\n  /Type /Pages  \\n  /Kids [4 0 R]  \\n  /Count 1\\n>>\\n"},{"bytes_offset":242,"object_num":3,"generation_num":0,"obj_bytes":"<<\\n  /Type /Catalog  \\n  /Pages 2 0 R\\n>>\\n"},{"bytes_offset":463,"object_num":4,"generation_num":0,"obj_bytes":"<<\\n  /Type /Page  \\n  /Contents 1 0 R  \\n  /Parent 2 0 R  \\n  /MediaBox [0 0 595.2765 841.89105]  \\n  /Resources <<\\n  /Font <<\\n  /F0 <<\\n  /Type /Font  \\n  /Subtype /Type1  \\n  /BaseFont /Times-Italic\\n>>\\n>>\\n>>\\n>>\\n"}],"xref_table":{"entries":[{"bytes_offset":0,"generation_num":65535,"state":"Free"},{"bytes_offset":105,"generation_num":0,"state":"InUse"},{"bytes_offset":67,"generation_num":0,"state":"InUse"},{"bytes_offset":55,"generation_num":0,"state":"InUse"},{"bytes_offset":221,"generation_num":0,"state":"InUse"}],"start_num":0},"trailer":"<<\\n  /Size 5  \\n  /Root 3 0 R\\n>>","start_xref_pos":622},"bytes_offset":631,"rest":"\\n"}))
}

///|
test {
  let files = @fs.read_dir("./output")
  for file in files {
    let file = "./output/\{file}"
    let file = @fs.read_file_to_bytes(file)
    let result = @pdf_file_lexer.tokenize_file(file)
    ignore(result)
  }
}
