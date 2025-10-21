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
    let skips = Set::from_array([
      "JBIG2Image.pdf", "PDFBOX3812-acrobat-multiline-auto.pdf", "PDFBOX-3127-RAU4G6QMOVRYBISJU7R6MOVZCRFUO7P4-VFont.pdf",
      "PDFBOX-2725-878725.pdf", "PDFBOX-5838-0024320-reduced.pdf", "PDFBOX-6049-Source.pdf",
      "PDFBOX-5784.pdf", "F001u_3_7j.pdf", "AcroFormForMerge-DifferentFieldType.pdf",
      "MultilineFields.pdf", "PDFBOX-4322-Empty-ToUnicode-reduced.pdf", "PDFBOX-3062-N2MOQ7YZICIYGTPLQJAWJ4HLN6CCEMHZ-reduced.pdf",
      "PasswordSample-256bit.pdf", "PDFBOX-3067-negativeTf.pdf", "AESkeylength256.pdf",
      "AcroFormForMerge.pdf", "PDFBOX-4531-bidi-ligature-2.pdf", "PDFBOX-3123-ADSFWTRB3HBZBZKEVESVTBRZC2MNKZF5_reduced.pdf",
      "AngledExample.pdf", "AcrobatMerge-TextFieldsOnly-SameMerged.pdf", "AcroFormsRotation.pdf",
      "AcroFormForMerge-DifferentExportValues.pdf", "PDFBOX-3062-005717-p1.pdf",
      "PDFBOX-5920-Y5U2XZCKG2U6TO3FC36NCGOZECHQA2PY-p39-reduced.pdf", "PDFBOX-3061-092465-reduced.pdf",
      "PDFBOX-3044-010197-p5-ligatures.pdf", "AES256ExposedMeta.pdf", "AcrobatMerge-DifferentOptions-WasMaster.pdf",
      "AnnotationTypes.pdf", "sign_me_protected.pdf", "PDFBOX-5747-unicode-surrogate-with-diacritic-reduced.pdf",
      "AcroFormForMerge-TextFieldsOnly.pdf", "PDFBOX-3833-reduced.pdf", "PDFBOX-5797-SO79271803.pdf",
      "AcrobatMerge-DifferentExportValues-WasMaster.pdf", "AcrobatMerge-DifferentExportValues.pdf",
      "ControlCharacters.pdf", "unencrypted.pdf", "acroform.pdf", "AcrobatMerge-DifferentFieldType-WasMaster.pdf",
    ])
    for file in files {
      if skips.contains(file) {
        continue
      }
      let file_path = "\{dir_path}/\{file}"
      let input = try! @fs.read_file_to_bytes(file_path)
      parse(input) |> ignore
    }
  }
}

///|
test {
  let file_path = "./resources/pdf_dataset/pdfbox/eu-001.pdf"
  let input = try! @fs.read_file_to_bytes(file_path)
  let result = parse(input)
  ignore(result)
}
