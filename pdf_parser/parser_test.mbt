///|
/// Test the PDF parser with a simple PDF document
test "parse simple PDF" {
  // Create a minimal valid PDF content using bytes literal  
  let input = b"%PDF-1.4\n1 0 obj\ntrue\nendobj\nxref\n0 2\n0000000000 65535 f \n0000000009 00000 n\ntrailer\n<</Size 2>>\nstartxref\n40\n%%EOF"
  let result = parse(input) // Let errors propagate
  @json.inspect(result, content={
    "major": 1,
    "minor": 4,
    "objects": [["Boolean", true]],
    "trailer": ["Dictionary", [["Size", ["Integer", 2]]]],
  })

  // test lexer
  let file = @pdf_file_lexer.tokenize_file(input)
  @json.inspect(file, content={
    "value": {
      "header": { "major": 1, "minor": 4 },
      "body": [
        {
          "bytes_offset": 29,
          "object_num": 1,
          "generation_num": 0,
          "obj_bytes": "true\\n",
        },
      ],
      "xref_table": {
        "entries": [
          { "bytes_offset": 0, "generation_num": 65535, "state": "Free" },
          { "bytes_offset": 9, "generation_num": 0, "state": "InUse" },
        ],
        "start_num": 0,
      },
      "trailer": "<</Size 2>>",
      "start_xref_pos": 40,
    },
    "bytes_offset": 115,
    "rest": "",
  })
  let obj = file.value.body.0[0]
  @json.inspect(obj, content={
    "bytes_offset": 29,
    "object_num": 1,
    "generation_num": 0,
    "obj_bytes": "true\\n",
  })
  let bytes = obj.obj_bytes
  inspect(@helper.ascii_string_of_bytesview(bytes), content="true\\n")
  inspect(
    @helper.ascii_string_of_bytesview(bytes.to_bytes()),
    content="true\\n",
  )
  inspect(
    bytes,
    content=(
      #|b"\x74\x72\x75\x65\x0a"
    ),
  )
  let tokens = @pdf_object_parser.tokenize(bytes.to_bytes())
  inspect(tokens.length(), content="2")
  inspect(
    tokens,
    content="[(TRUE, {row: 0, col: 0}, {row: 0, col: 4}), (EOF, {row: 1, col: 0}, {row: 1, col: 0})]",
  )
  let result = @pdf_object_parser.parse(tokens)
  @json.inspect(result, content=["Boolean", true])
}

///|
test {
  let input = try! @fs.read_file_to_bytes("./output/hello.pdf")
  let tokens = @pdf_file_lexer.tokenize_file(input)
  @json.inspect(tokens, content={
    "value": {
      "header": { "major": 1, "minor": 4 },
      "body": [
        {
          "bytes_offset": 463,
          "object_num": 1,
          "generation_num": 0,
          "obj_bytes": "<<\\n  /Length 53\\n>>\\nstream\\n 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\\nendstream\\nendobj\\n2 0 obj\\n<<\\n  /Type /Pages  \\n  /Kids [4 0 R]  \\n  /Count 1\\n>>\\nendobj\\n3 0 obj\\n<<\\n  /Type /Catalog  \\n  /Pages 2 0 R\\n>>\\nendobj\\n4 0 obj\\n<<\\n  /Type /Page  \\n  /Contents 1 0 R  \\n  /Parent 2 0 R  \\n  /MediaBox [0 0 595.2765 841.89105]  \\n  /Resources <<\\n  /Font <<\\n  /F0 <<\\n  /Type /Font  \\n  /Subtype /Type1  \\n  /BaseFont /Times-Italic\\n>>\\n>>\\n>>\\n>>\\n",
        },
      ],
      "xref_table": {
        "entries": [
          { "bytes_offset": 0, "generation_num": 65535, "state": "Free" },
          { "bytes_offset": 105, "generation_num": 0, "state": "InUse" },
          { "bytes_offset": 67, "generation_num": 0, "state": "InUse" },
          { "bytes_offset": 55, "generation_num": 0, "state": "InUse" },
          { "bytes_offset": 221, "generation_num": 0, "state": "InUse" },
        ],
        "start_num": 0,
      },
      "trailer": "<<\\n  /Size 5  \\n  /Root 3 0 R\\n>>",
      "start_xref_pos": 622,
    },
    "bytes_offset": 631,
    "rest": "\\n",
  })

  // let result = try parse(input) catch {
  //   @pdf_object_parser.ParseError::UnexpectedToken(tok,range,kinds) => {
  //     println(tok)
  //     println(range)
  //     println(kinds)
  //     panic()
  //   }
  //   @pdf_object_parser.ParseError::UnexpectedEndOfInput(_,_) => {
  //     panic()
  //   }
  //   _ => panic()
  // }
}
