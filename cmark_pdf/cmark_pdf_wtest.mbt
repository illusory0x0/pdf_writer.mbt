///|
test (t : @test.T) {
  let path = "./output/hello_md.pdf"
  let bytes = markdown_to_bytes(md_str)
  @fs.write_bytes_to_file(path, bytes)
  t.writeln(bytes)
  t.snapshot(filename="hello_md.pdf.bytes")
}

///|
test {
  let files = @fs.read_dir("./markdown")
  let buffer = StringBuilder::new(
    size_hint=files.fold(init=0, (acc, s) => acc + s.length()),
  )
  // let files = ["/Users/cici/dev.mbt/pdf.mbt/markdown/list_README.md"]
  for f in files {
    // Only process files that end with .md
    if f.has_suffix(".md") {
      let full_path = "./markdown/" + f
      // let full_path = f
      let content = @fs.read_file_to_string(full_path)
      buffer.write_string(content)
      buffer.write_string("\n\n")
    }
  }
  let md_str = buffer.to_string()
  let bytes = markdown_to_bytes(md_str)
  let cmark_doc = @cmark.Doc::from_string(md_str)
  let doc = Doc::from_cmark(cmark_doc)

  // Verify doc conversion worked by checking length
  let _ = doc.inner().length()
  let path = "./output/all_md.pdf"
  @fs.write_bytes_to_file(path, bytes)
}
