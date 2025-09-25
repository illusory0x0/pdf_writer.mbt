///|
fn coerce_seq_to_array(
  seq : @cmark.Seq[@cmark.Seq[String]],
) -> Array[Array[String]] = "%identity"

///|
pub fn Block::from_cmark(block : @cmark.Block) -> Block {
  match block {
    Heading(node) => {
      let block_heading = node.v
      let level = block_heading.level
      let text = block_heading.inline.to_plain_text(break_on_soft=true)
        |> coerce_seq_to_array
      let text = text.flatten().join(" ")
      Heading(level~, text~)
    }
    Paragraph(node) => {
      let block_paragraph = node.v
      let para = Inline::from_cmark(block_paragraph.inline)
      Paragraph(para)
    }
    CodeBlock({ v: code_block, .. }) =>
      match code_block.info_string {
        Some({ v: "moonbit", .. }) => {
          let cs_lines = from_cmark_code_block(code_block)
          MoonBitCodeBlock(cs_lines)
        }
        Some({ v: text, .. }) => {
          let code = code_block.code
            .to_array()
            .map(x => x.v |> pdf_bytes_of_string)
          let language = text
          CodeBlock(language~, code~)
        }
        None => {
          let code = code_block.code
            .to_array()
            .map(x => x.v |> pdf_bytes_of_string)
          CodeBlock(language="", code~)
        }
      }
    BlankLine(_) => BlankLine
    // Handle all other block types by converting them to Paragraph with Plain inline text
    BlockQuote(node) => {
      // Extract text content from the quoted block and convert to paragraph
      let quoted_texts = extract_texts_from_block(node.v.block)
      let plain_elements = quoted_texts.map(fn(text) { Plain(text) })
      Paragraph(plain_elements)
    }
    Blocks(node) => {
      // For multiple blocks, convert the first one or return empty paragraph
      let blocks = node.v.to_array()
      match blocks {
        [] => Paragraph([Plain("")])
        [first, ..] => Block::from_cmark(first)
      }
    }
    HtmlBlock(node) => {
      // Convert HTML block to plain text paragraph
      let html_block = node.v
      let html_lines = html_block.0.to_array().map(x => x.v)
      let plain_elements = html_lines.map(fn(line) { Plain(line) })
      Paragraph(plain_elements)
    }
    LinkRefDefinition(node) => {
      // Convert link definition to plain text paragraph
      let link_def = node.v
      let text = match link_def.label {
        Some(label) => "[\{label.key}]"
        None => "[undefined]"
      }
      Paragraph([Plain(text)])
    }
    List(node) => {
      // Convert each list item to a Block and collect into List(Array[Block])
      let list = node.v
      let items = list.items.to_array()
      let list_items = items.map(fn(item) { Block::from_list_item(item.v) })
      List(list_items)
    }
    ThematicBreak(_) =>
      // Convert thematic break to plain text representation
      Paragraph([Plain("---")])
    ExtMathBlock({ v: code_block, .. }) => {
      // Handle math blocks similar to code blocks but as plain text
      let math_lines = code_block.code.to_array().map(x => x.v)
      let plain_elements = math_lines.map(fn(line) { Plain(line) })
      Paragraph(plain_elements)
    }
    ExtTable(node) => {
      // Convert table to plain text paragraph
      let table = node.v
      let rows = table.rows.to_array()
      let row_texts = rows.map(fn(row_pair) {
        let row = row_pair.0.v
        match row {
          Header(cells) | Data(cells) => {
            let cell_texts = cells
              .to_array()
              .map(fn(cell) {
                let text = cell.0.to_plain_text(break_on_soft=true)
                  |> coerce_seq_to_array
                let text = text.flatten().join(" ")
                text
              })
            cell_texts.join(" | ")
          }
          Sep(_) => "---"
        }
      })
      let plain_elements = row_texts.map(fn(row_text) { Plain(row_text) })
      Paragraph(plain_elements)
    }
    ExtFootnoteDefinition(node) => {
      // Convert footnote to plain text paragraph
      let footnote = node.v
      let footnote_texts = extract_texts_from_block(footnote.block)
      let footnote_label = "[\{footnote.label.key}]:"
      let plain_elements = [Plain(footnote_label)] +
        footnote_texts.map(fn(text) { Plain(text) })
      Paragraph(plain_elements)
    }
  }
}

///|
/// Helper function to extract text content from a block recursively.
/// Returns an array of individual text pieces without joining them.
fn extract_texts_from_block(block : @cmark.Block) -> Array[String] {
  match block {
    Heading(node) => {
      let texts = node.v.inline.to_plain_text(break_on_soft=true)
        |> coerce_seq_to_array
      texts.flatten()
    }
    Paragraph(node) => {
      let texts = node.v.inline.to_plain_text(break_on_soft=true)
        |> coerce_seq_to_array
      texts.flatten()
    }
    CodeBlock({ v: code_block, .. }) => code_block.code.to_array().map(x => x.v)
    BlankLine(_) => []
    BlockQuote(node) => extract_texts_from_block(node.v.block)
    Blocks(node) => {
      let blocks = node.v.to_array()
      blocks.map(extract_texts_from_block).flatten()
    }
    HtmlBlock(node) => {
      let html_block = node.v
      html_block.0.to_array().map(x => x.v)
    }
    LinkRefDefinition(node) =>
      match node.v.label {
        Some(label) => ["[\{label.key}]"]
        None => ["[undefined]"]
      }
    List(node) => {
      let items = node.v.items.to_array()
      items
      .map(fn(item) {
        let texts = extract_texts_from_block(item.v.block)
        texts.map(fn(text) { " \{text}" })
      })
      .flatten()
    }
    ThematicBreak(_) => ["---"]
    ExtMathBlock({ v: code_block, .. }) =>
      code_block.code.to_array().map(x => x.v)
    ExtTable(node) => {
      let table = node.v
      let rows = table.rows.to_array()
      rows
      .map(fn(row_pair) {
        let row = row_pair.0.v
        match row {
          Header(cells) | Data(cells) =>
            cells
            .to_array()
            .map(fn(cell) {
              let texts = cell.0.to_plain_text(break_on_soft=true)
                |> coerce_seq_to_array
              texts.flatten()
            })
            .flatten()
          Sep(_) => ["---"]
        }
      })
      .flatten()
    }
    ExtFootnoteDefinition(node) => {
      let footnote = node.v
      let footnote_texts = extract_texts_from_block(footnote.block)
      ["[\{footnote.label.key}]:"] + footnote_texts
    }
  }
}

///|
fn utf16_string_to_pdf_escaped_ascii_bytes(s : String) -> Bytes {
  let buffer = @buffer.new(size_hint=s.length() * 2)
  for char in s {
    let code = char.to_int()

    // Handle characters that need escaping according to PDF spec
    if code <= 127 {
      // ASCII characters - apply PDF literal string escaping
      match char {
        '\\' => {
          buffer.write_byte('\\')
          buffer.write_byte('\\')
        }
        '(' => {
          buffer.write_byte('\\')
          buffer.write_byte('(')
        }
        ')' => {
          buffer.write_byte('\\')
          buffer.write_byte(')')
        }
        '\n' => {
          buffer.write_byte('\\')
          buffer.write_byte('n')
        }
        '\r' => {
          buffer.write_byte('\\')
          buffer.write_byte('r')
        }
        '\t' => {
          buffer.write_byte('\\')
          buffer.write_byte('t')
        }
        '\b' => {
          buffer.write_byte('\\')
          buffer.write_byte('b')
        }
        '\u000c' => { // form feed
          buffer.write_byte('\\')
          buffer.write_byte('f')
        }
        _ if code < 32 || code > 126 => {
          // Non-printable ASCII: use octal escape sequence
          buffer.write_byte('\\')
          buffer.write_byte((code / 64 + '0'.to_int()).to_byte())
          buffer.write_byte((code % 64 / 8 + '0'.to_int()).to_byte())
          buffer.write_byte((code % 8 + '0'.to_int()).to_byte())
        }
        _ =>
          // Regular printable ASCII
          buffer.write_byte(code.to_byte())
      }
      // Non-ASCII characters: use octal escape sequence
      // For characters > 127, we need to handle them as UTF-8 bytes or use octal escaping
      // Since this is for PDF text, we'll use octal escape for simplicity
    } else if code <= 255 {
      // Single byte, use octal escape
      buffer.write_byte('\\')
      buffer.write_byte((code / 64 + '0'.to_int()).to_byte())
      buffer.write_byte((code % 64 / 8 + '0'.to_int()).to_byte())
      buffer.write_byte((code % 8 + '0'.to_int()).to_byte())
    } else {
      // Multi-byte characters - encode as UTF-8 bytes and escape each
      let utf8_str = char.to_string()
      let utf8_bytes = utf8_str.to_bytes()
      for byte in utf8_bytes {
        let b_code = byte.to_int()
        buffer.write_byte('\\')
        buffer.write_byte((b_code / 64 + '0'.to_int()).to_byte())
        buffer.write_byte((b_code % 64 / 8 + '0'.to_int()).to_byte())
        buffer.write_byte((b_code % 8 + '0'.to_int()).to_byte())
      }
    }
  }
  buffer.to_bytes()
}

///|
test "utf16_string_to_pdf_escaped_ascii_bytes basic" {
  // Test basic ASCII text
  let result1 = utf16_string_to_pdf_escaped_ascii_bytes("Hello World")
  inspect(@pdf.ascii_string_of_bytes(result1), content="Hello World")

  // Test empty string
  let result2 = utf16_string_to_pdf_escaped_ascii_bytes("")
  inspect(@pdf.ascii_string_of_bytes(result2), content="")

  // Test single character
  let result3 = utf16_string_to_pdf_escaped_ascii_bytes("A")
  inspect(@pdf.ascii_string_of_bytes(result3), content="A")
}

///|
test "utf16_string_to_pdf_escaped_ascii_bytes special_chars" {
  // Test special characters that need escaping
  let result1 = utf16_string_to_pdf_escaped_ascii_bytes("Hello\\World")
  inspect(@pdf.ascii_string_of_bytes(result1), content="Hello\\\\\\\\World")

  // Test parentheses
  let result2 = utf16_string_to_pdf_escaped_ascii_bytes("Hello(World)")
  inspect(@pdf.ascii_string_of_bytes(result2), content="Hello\\\\(World\\\\)")

  // Test newlines and tabs
  let result3 = utf16_string_to_pdf_escaped_ascii_bytes("Hello\nWorld\tTest")
  inspect(
    @pdf.ascii_string_of_bytes(result3),
    content="Hello\\\\nWorld\\\\tTest",
  )
}

///|
test "utf16_string_to_pdf_escaped_ascii_bytes control_chars" {
  // Test various control characters
  let result1 = utf16_string_to_pdf_escaped_ascii_bytes("Hello\rWorld")
  inspect(@pdf.ascii_string_of_bytes(result1), content="Hello\\\\rWorld")
  let result2 = utf16_string_to_pdf_escaped_ascii_bytes("Test\bBackspace")
  inspect(@pdf.ascii_string_of_bytes(result2), content="Test\\\\bBackspace")

  // Test form feed
  let result3 = utf16_string_to_pdf_escaped_ascii_bytes("Page1\u000cPage2")
  inspect(@pdf.ascii_string_of_bytes(result3), content="Page1\\\\fPage2")
}

///|
test "utf16_string_to_pdf_escaped_ascii_bytes non_ascii" {
  // Test simple non-ASCII characters
  let result1 = utf16_string_to_pdf_escaped_ascii_bytes("Café")
  // é is Unicode U+00E9 (233 in decimal), should be octal escaped
  inspect(@pdf.ascii_string_of_bytes(result1), content="Caf\\\\351")

  // Test character above 255 (should be encoded as UTF-8 bytes)
  let result2 = utf16_string_to_pdf_escaped_ascii_bytes("Hello 世界")
  // 世 and 界 should be encoded as UTF-8 bytes and each byte escaped
  // This will produce a more complex escaped sequence
  let ascii_result = @pdf.ascii_string_of_bytes(result2)
  // Just verify it starts with "Hello "
  inspect(ascii_result.has_prefix("Hello "), content="true")
}
