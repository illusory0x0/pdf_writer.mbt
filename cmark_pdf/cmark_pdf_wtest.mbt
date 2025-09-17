///|
test {
  markdown_write_to_pdf_file(md_str, path="./output/hello_md.pdf")
}

///|
fn markdown_write_to_pdf_file(
  md_str : String,
  path~ : String,
) -> Unit raise @fs.IOError {
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
  write_multiple_page_pdf_file(path~, [table_of_contents, ..contents])
}

///|
test "plain_paragraph_to_ascii_multi_line" {
  let xs = ["123"]
  @json.inspect(plain_paragraph_to_ascii_multi_line(xs, limits=2), content=[
    "12", "3 ",
  ])
}

///|
test "split_bytes" {
  // Test with simple bytes
  let input = b"hello world"
  let result = split_bytes(input, init_cols=0, max_cols=5)
  @json.inspect(result, content=["hello", " worl", "d"])

  // Test with initial columns
  let result2 = split_bytes(b"test", init_cols=3, max_cols=5)
  @json.inspect(result2, content=["te", "st"])

  // Test with empty input
  let result3 = split_bytes(b"", init_cols=0, max_cols=5)
  @json.inspect(result3, content=[])
}
