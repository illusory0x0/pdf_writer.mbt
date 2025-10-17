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
    "trailer": ["Dictionary", [["/Size", ["Integer", 2]]]],
  })

  // test lexer
  let file = @pdf_file_lexer.tokenize_file(input)
  @json.inspect(file, content={
    "value": {
      "header": { "major": 1, "minor": 4 },
      "body": [
        {
          "bytes_offset": 9,
          "object_num": 1,
          "generation_num": 0,
          "obj_bytes": "\\ntrue\\n",
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
    "start_bytes_offset": 0,
    "end_bytes_offset": 115,
    "rest": "",
  })
  let obj = file.value.body[0]
  @json.inspect(obj, content={
    "bytes_offset": 9,
    "object_num": 1,
    "generation_num": 0,
    "obj_bytes": "\\ntrue\\n",
  })
  let bytes = obj.obj_bytes
  inspect(@helper.ascii_string_of_bytesview(bytes), content="\\ntrue\\n")
  inspect(
    @helper.ascii_string_of_bytesview(bytes.to_bytes()),
    content="\\ntrue\\n",
  )
  inspect(
    bytes,
    content=(
      #|b"\x0atrue\x0a"
    ),
  )
  let tokens = @pdf_object_parser.tokenize(bytes.to_bytes())
  inspect(tokens.length(), content="2")
  inspect(
    tokens,
    content="[(TRUE, {row: 1, col: 0}, {row: 1, col: 4}), (EOF, {row: 2, col: 0}, {row: 2, col: 0})]",
  )
  let result = @pdf_object_parser.parse(tokens)
  @json.inspect(result, content=["Boolean", true])
}

///|
test {
  let input = try! @fs.read_dir("./output")
  let files = input.map(basename => "./output/\{basename}")
  for file in files {
    let input = try! @fs.read_file_to_bytes(file)
    let result = parse(input)
    ignore(result)
  }
}

///|
const Debug = false

///|
test "test for pdfbox dataset" {
  if Debug {
    let dir_path = "./resources/pdf_dataset/pdfbox"
    let files = try! @fs.read_dir(dir_path)

    // `ISO 32000-2:2020 (PDF 2.0)`, section 7.5.8 Cross-Reference Streams
    // some files use XRef streams, which is not supported yet.
    // These files will be skipped
    let skips = Set::from_array(["JBIG2Image.pdf"])
    for file in files {
      if skips.contains(file) {
        continue
      }
      let file_path = "\{dir_path}/\{file}"
      println("Parsing file: \{file_path}")
      let input = try! @fs.read_file_to_bytes(file_path)
      let result = parse(input)
      ignore(result)
    }
  }
}

// ///|
// test {
//   if true {
//     let file_path = "./resources/pdf_dataset/pdfbox/eu-001.pdf"
//     let input = try! @fs.read_file_to_bytes(file_path)
//     let result = parse(input)
//     ignore(result)
//   }
// }
