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
  let result = parse(input)
  @json.inspect(result, content={
    "major": 1,
    "minor": 4,
    "objects": [
      [
        "Stream",
        ["Dictionary", [["/Length", ["Integer", 53]]]],
        ["Stream", " 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\\x0a"],
      ],
      [
        "Dictionary",
        [
          ["/Type", ["Name", "/Pages"]],
          ["/Kids", ["Array", [["Indirect", 4]]]],
          ["/Count", ["Integer", 1]],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Type", ["Name", "/Catalog"]],
          ["/Pages", ["Indirect", 2]],
          ["/Outlines", ["Indirect", 5]],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Type", ["Name", "/Page"]],
          ["/Contents", ["Indirect", 1]],
          ["/Parent", ["Indirect", 2]],
          [
            "/MediaBox",
            [
              "Array",
              [
                ["Integer", 0],
                ["Integer", 0],
                ["Real", 595.2765],
                ["Real", 841.89105],
              ],
            ],
          ],
          [
            "/Resources",
            [
              "Dictionary",
              [
                [
                  "/Font",
                  [
                    "Dictionary",
                    [
                      [
                        "/F0",
                        [
                          "Dictionary",
                          [
                            ["/Type", ["Name", "/Font"]],
                            ["/Subtype", ["Name", "/Type1"]],
                            ["/BaseFont", ["Name", "/Times-Italic"]],
                          ],
                        ],
                      ],
                    ],
                  ],
                ],
              ],
            ],
          ],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Type", ["Name", "/Outlines"]],
          ["/First", ["Indirect", 6]],
          ["/Last", ["Indirect", 6]],
          ["/Count", ["Integer", 0]],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Title", ["String", "chapter 1"]],
          ["/Parent", ["Indirect", 5]],
          ["/Prev", "Null"],
          ["/Next", "Null"],
          ["/First", ["Indirect", 7]],
          ["/Last", ["Indirect", 8]],
          ["/Count", ["Integer", 0]],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Title", ["String", "section 1.1"]],
          ["/Parent", ["Indirect", 6]],
          ["/Prev", "Null"],
          ["/Next", ["Indirect", 8]],
          ["/First", "Null"],
          ["/Last", "Null"],
          ["/Count", ["Integer", 0]],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Title", ["String", "section 1.2"]],
          ["/Parent", ["Indirect", 6]],
          ["/Prev", ["Indirect", 7]],
          ["/Next", "Null"],
          ["/First", ["Indirect", 9]],
          ["/Last", ["Indirect", 9]],
          ["/Count", ["Integer", 0]],
        ],
      ],
      [
        "Dictionary",
        [
          ["/Title", ["String", "subsection 1.2.1"]],
          ["/Parent", ["Indirect", 8]],
          ["/Prev", "Null"],
          ["/Next", "Null"],
          ["/First", "Null"],
          ["/Last", "Null"],
          ["/Count", ["Integer", 0]],
        ],
      ],
    ],
    "trailer": [
      "Dictionary",
      [["/Size", ["Integer", 5]], ["/Root", ["Indirect", 3]]],
    ],
  })
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
