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
        content.push(@pdf.Op_Tf("/F0", font_size_body))
        content.push(@pdf.Op_TL(font_size_body))
        content.push_iter(paragraph_to_graphic_operators(para).iter())
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
      Heading(level~, text~) => {
        let font_size = match level {
          1 => font_size_h1
          2 => font_size_h2
          3 => font_size_h3
          _ => font_size_body
        }
        font_size // Op_TL sets leading to font_size, Op_T_star consumes it
      }
      // TODO: need to optimize
      Paragraph(para) =>
        plain_paragraph_to_ascii_multi_line(para).length().to_double() *
        font_size_body // Op_TL sets leading to font_size_body, Op_T_star consumes it
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
fn paragraph_to_graphic_operators(input : Array[String]) -> Content {
  multi_line_to_graphics_operator_sequence(
    plain_paragraph_to_ascii_multi_line(input),
  )
}
