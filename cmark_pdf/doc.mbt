///|
fn Doc::remove_contiguous_blanklines(self : Doc) -> Doc {
  let result = []
  let mut last_was_blankline = false
  for block in self.inner() {
    if block is BlankLine {
      if !last_was_blankline {
        result.push(block)
        last_was_blankline = true
      }
    } else {
      result.push(block)
      last_was_blankline = false
    }
  }
  Doc(result)
}

///|
fn Doc::from_cmark(doc : @cmark.Doc) -> Doc {
  match doc.block {
    Blocks(node) => {
      let seq = node.v
      let blocks = seq.to_array()
      blocks.map(Block::from_cmark)
    }
    _ => panic()
  }
}

///|
fn Doc::to_flatheadings(self : Doc) -> Array[FlatHeading] {
  let mut h1 = 0
  let mut h2 = 0
  let mut h3 = 0
  let result = []
  for block in self.inner() {
    if block is Heading(level~, text~) {
      match level {
        1 => {
          h1 += 1
          h2 = 0
          h3 = 0
          result.push(FlatHeading::{ num: [h1], text })
        }
        2 => {
          h2 += 1
          h3 = 0
          result.push(FlatHeading::{ num: [h1, h2], text })
        }
        3 => {
          h3 += 1
          result.push(FlatHeading::{ num: [h1, h2, h3], text })
        }
        _ => abort("TODO")
      }
    }
  }
  result
}

///|
fn Doc::to_graphic_operators(self : Doc) -> Content {
  let content = []
  for block in self.inner() {
    match block {
      Heading(level~, text~) => {
        let font_size = match level {
          1 => font_size_h1
          2 => font_size_h2
          3 => font_size_h3
          _ => font_size_body
        }
        content.push(@pdf.Op_Tf("/F0", font_size))
        content.push(@pdf.Op_Tj(bytes_of_string(text)))
        content.push(@pdf.Op_TL(font_size))
        content.push(@pdf.Op_T_star)
      }
      Paragraph(para) => {
        content.push(@pdf.Op_TL(font_size_body))
        content.push(@pdf.Op_Tf("/F0", font_size_body))
        // TODO

        let max_cols = 80
        let mut cur_cols = 0
        for text in para {
          let (s, f) = match text {
            Plain(s) => (s, b"/F0")
            StrongEmphasis(s) => (s, b"/F1")
            Emphasis(s) => (s, b"/F2")
            StrongEmphasis_Emphasis(s) => (s, b"/F3") 
          }
          let s = utf16_string_to_ascii_bytes(s)
          let len = s.length()
          // set font and font size 
          content.push(@pdf.Op_Tf(f, font_size_body))
          if cur_cols + len > max_cols {
            // split text not exceeding max_cols
            let split_parts = split_bytes(s, init_cols=cur_cols, max_cols~)
            // TODO: need refacotr, use pattern match, handle if array only has 1 element, then
            // we not need `if` condition in the loop
            for i in 0..<split_parts.length() {
              if i > 0 {
                // Move to next line for subsequent parts
                content.push(@pdf.Op_T_star)
              }
              content.push(@pdf.Op_Tj(split_parts[i]))
            }
            // Calculate remaining columns on the last line
            let last_part = split_parts[split_parts.length() - 1]
            cur_cols = last_part.length()
          } else {
            // directly show text 
            content.push(@pdf.Op_Tj(s))
            cur_cols += len
          }
        }
        content.push(@pdf.Op_T_star)
      }
      BlankLine => {
        content.push(@pdf.Op_TL(font_size_body))
        content.push(@pdf.Op_T_star)
      }
    }
  }
  content
}

///|
fn Doc::split(self : Doc, max_height~ : Double) -> Array[Doc] {
  let result = []
  let mut current_height = 0.0
  let mut current_blocks = []
  for block in self.inner() {
    // Calculate the height that this block would add
    let block_height = match block {
      Heading(level~, ..) => {
        let font_size = match level {
          1 => font_size_h1
          2 => font_size_h2
          3 => font_size_h3
          _ => font_size_body
        }
        font_size // Op_TL sets leading to font_size, Op_T_star consumes it
      }
      // TODO: need to optimize
      Paragraph(para) => {
        // TODO 
        let para = para.map(x => match x {
          Plain(x) => x
          StrongEmphasis(x) => x
          Emphasis(x) => x
          StrongEmphasis_Emphasis(x) => x
        })
        plain_paragraph_to_ascii_multi_line(para).length().to_double() *
        font_size_body // Op_TL sets leading to font_size_body, Op_T_star consumes it
      }
      BlankLine => font_size_body // Op_TL sets leading to font_size_body, Op_T_star consumes it
    }

    // Check if adding this block would exceed max_height
    if current_height + block_height > max_height && current_blocks.length() > 0 {
      // Split here: add current blocks to result and start new document
      result.push(Doc(current_blocks))
      current_blocks = []
      current_height = 0.0
    }

    // Add the block to current document
    current_blocks.push(block)
    current_height += block_height
  }

  // Add the final document if it has any blocks
  if current_blocks.length() > 0 {
    result.push(Doc(current_blocks))
  }

  // Ensure we always return at least one document, even if empty
  if result.length() == 0 {
    result.push(Doc([]))
  }
  result
}

///|
fn split_bytes(
  input : Bytes,
  init_cols~ : Int,
  max_cols~ : Int,
) -> Array[Bytes] {
  let mut cur_cols = init_cols
  let result = []
  let buffer = @buffer.new()
  for i in 0..<input.length() {
    let byte = input[i]

    // Check if adding this byte would exceed max_cols
    if cur_cols >= max_cols {
      // Flush current buffer to result and start new line
      result.push(buffer.to_bytes())
      buffer.reset()
      cur_cols = 0
    }
    buffer.write_byte(byte)
    cur_cols += 1
  }

  // Add remaining content in buffer if any
  if buffer.length() > 0 {
    result.push(buffer.to_bytes())
  }
  result
}
