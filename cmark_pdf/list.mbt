///|
pub fn Block::from_list_item(list_item : @cmark.ListItem) -> Block {
  let block = list_item.block
  Block::from_list_block(block)
}

///|
/// Helper function to convert a @cmark.Block to Block for list items
fn Block::from_list_block(block : @cmark.Block) -> Block {
  match block {
    Paragraph(node) => {
      let block_paragraph = node.v
      let para = Inline::from_cmark(block_paragraph.inline)
      Paragraph(para)
    }
    BlankLine(_) => BlankLine
    Blocks(node) => {
      // Handle nested blocks - convert each block to a Block element
      let blocks = node.v.to_array()
      let list_items = blocks.map(Block::from_list_block)
      Blocks(list_items)
    }
    List(node) => {
      // Handle nested lists - convert each list item
      let list = node.v
      let items = list.items.to_array()
      let list_items = items.map(fn(item) { Block::from_list_item(item.v) })
      List(list_items)
    }
    // For other block types, convert them to paragraphs with plain text
    Heading(node) => {
      let block_heading = node.v
      let text = block_heading.inline.to_plain_text(break_on_soft=true)
        |> coerce_seq_to_array
      let flattened_text = text.flatten().join(" ")
      Paragraph([Plain(flattened_text)])
    }
    CodeBlock({ v: code_block, .. }) => {
      let code_lines = code_block.code.to_array().map(x => x.v)
      let code_text = code_lines.join("\n")
      Paragraph([Plain(code_text)])
    }
    BlockQuote(node) =>
      // Convert quoted block to list element
      Block::from_list_block(node.v.block)
    HtmlBlock(node) => {
      // Convert HTML block to plain text paragraph
      let html_block = node.v
      let html_lines = html_block.0.to_array().map(x => x.v)
      let html_text = html_lines.join("\n")
      Paragraph([Plain(html_text)])
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
    ThematicBreak(_) =>
      // Convert thematic break to plain text representation
      Paragraph([Plain("---")])
    ExtMathBlock({ v: code_block, .. }) => {
      // Handle math blocks as plain text
      let math_lines = code_block.code.to_array().map(x => x.v)
      let math_text = math_lines.join("\n")
      Paragraph([Plain(math_text)])
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
                text.flatten().join(" ")
              })
            cell_texts.join(" | ")
          }
          Sep(_) => "---"
        }
      })
      let table_text = row_texts.join("\n")
      Paragraph([Plain(table_text)])
    }
    ExtFootnoteDefinition(node) => {
      // Convert footnote to plain text paragraph
      let footnote = node.v
      let footnote_texts = extract_texts_from_block(footnote.block)
      let footnote_text = "[\{footnote.label.key}]: " + footnote_texts.join(" ")
      Paragraph([Plain(footnote_text)])
    }
  }
}
