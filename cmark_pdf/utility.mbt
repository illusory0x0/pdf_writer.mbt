///|
fn pdf_bytes_of_string(s : String) -> Bytes {
  let buffer = @buffer.new(size_hint=s.length() * 2)
  for i in 0..<s.length() {
    let code_unit = s[i]
    if Char::is_ascii(code_unit.unsafe_to_char()) {
      let byte = code_unit.to_byte()
      // Escape PDF delimiter characters for literal strings
      match byte {
        '\\' => {
          buffer.write_byte(b'\\')
          buffer.write_byte(b'\\')
        }
        '(' => {
          buffer.write_byte(b'\\')
          buffer.write_byte(b'(')
        }
        ')' => {
          buffer.write_byte(b'\\')
          buffer.write_byte(b')')
        }
        _ => buffer.write_byte(byte)
      }
    } else {
      // Non-ASCII characters are replaced with '?'
      buffer.write_byte(b'?')
    }
  }
  buffer.to_bytes()
}

///|
fn markdown_to_bytes(md_str : String) -> Bytes {
  let tm : @pdf.TransformMatrix = @pdf.TransformMatrix::{
    a: 1,
    b: 0,
    c: 0,
    d: 1,
    e: 50,
    f: 770,
  }
  let cmark_doc = @cmark.Doc::from_string(md_str)
  let doc = Doc::from_cmark(cmark_doc)
  let flat_headings = doc.to_flatheadings()
  let table_of_contents : ContentStream = [
      Op_cm(tm),
      Op_BT,
      ..FlatHeading::to_graphic_operators(flat_headings),
      Op_ET,
    ]
  let trim_doc = doc.remove_contiguous_blanklines()
  let split_doc = trim_doc.split(max_height=660)
  // let split_doc = doc 

  //   for doc in split_doc {
  // println    (doc)
  //   }
  let contents : Array[ContentStream] = split_doc.map(doc => [
      Op_cm(tm),
      Op_BT,
      ..doc.to_graphic_operators(),
      Op_ET,
    ])
  multiple_page_to_bytes([table_of_contents, ..contents])
}
