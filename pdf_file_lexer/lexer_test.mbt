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
