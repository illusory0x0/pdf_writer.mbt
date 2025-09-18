///|
test (t : @test.T) {
  let path = "./output/hello_md.pdf"
  let bytes = markdown_to_bytes(md_str)
  @fs.write_bytes_to_file(path, bytes)
  t.writeln(bytes)
  t.snapshot(filename="hello_md.pdf.bytes")
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
  let table_of_contents : Content = [
      Op_cm(tm),
      Op_BT,
      ..FlatHeading::to_graphic_operators(flat_headings),
      Op_ET,
    ]
  let trim_doc = doc.remove_contiguous_blanklines()
  let split_doc = trim_doc.split(max_height=700)
  let contents : Array[Content] = split_doc.map(doc => [
      Op_cm(tm),
      Op_BT,
      ..doc.to_graphic_operators(),
      Op_ET,
    ])
  multiple_page_to_bytes([table_of_contents, ..contents])
}
