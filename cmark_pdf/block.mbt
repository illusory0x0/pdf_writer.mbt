///|
fn plain_paragraph_to_ascii_multi_line(
  input : Array[String],
  limits? : Int = 80,
) -> Array[Bytes] {
  let xs = []
  let mut line = FixedArray::make(limits, b' ')
  let mut offset = 0
  for span in input {
    for ch in span {
      if offset >= limits {
        offset = 0
        xs.push(line.unsafe_reinterpret_as_bytes())
        line = FixedArray::make(limits, b' ')
      }
      if ch.is_ascii() {
        line[offset] = ch.to_int().to_byte()
      } else {
        line[offset] = b'?'
      }
      offset += 1
    }
    if offset >= limits {
      offset = 0
      xs.push(line.unsafe_reinterpret_as_bytes())
      line = FixedArray::make(limits, b' ')
    }
    offset += 1
  }
  xs.push(line.unsafe_reinterpret_as_bytes())
  xs
}

///|
fn Block::from_cmark(block : @cmark.Block) -> Block {
  match block {
    Heading(node) => {
      let block_heading = node.v
      let level = block_heading.level
      guard block_heading.inline is Text({ v: text, .. }) else { panic() }
      Heading(level~, text~)
    }
    Paragraph(node) => {
      let block_paragraph = node.v
      let para = Inline::from_cmark(block_paragraph.inline)
      Paragraph(para)
    }
    CodeBlock({ v: code_block, .. }) => {
      let code = code_block.code.to_array().map(x => x.v |> bytes_of_string)
      let language = match code_block.info_string {
        None => ""
        Some({ v: text, .. }) => text
      }
      CodeBlock(language~, code~)
    }
    BlankLine(_) => BlankLine
    _ => abort("Unsupported block type")
  }
}

///|
fn utf16_string_to_ascii_bytes(s : String) -> Bytes {
  let bytes = FixedArray::make(s.length(), b'?')
  for i in 0..<s.length() {
    let ch = s[i]
    if Char::is_ascii(ch.unsafe_to_char()) {
      bytes[i] = ch.to_byte()
    } else {
      bytes[i] = b'?'
    }
  }
  bytes.unsafe_reinterpret_as_bytes()
}
