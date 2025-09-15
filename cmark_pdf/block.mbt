///|
fn multi_line_to_graphics_operator_sequence(lines : Array[Bytes]) -> Content {
  let result = []
  match lines {
    [] => ()
    [x, .. xs] => {
      result.push(@pdf.Op_Tj(x))
      for x in xs {
        result.push(@pdf.Op_single_quote(x))
      }
    }
  }
  result
}

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
      let para = []
      match block_paragraph.inline {
        Text({ v: text, .. }) => para.push(text)
        Inlines(node) => {
          let inlines = node.v.to_array()
          for inline in inlines {
            if inline is Text({ v: text, .. }) {
              para.push(text)
            }
          }
        }
        _ => panic()
      }
      Paragraph(para)
    }
    BlankLine(_) => BlankLine
    _ => abort("Unsupported block type")
  }
}
