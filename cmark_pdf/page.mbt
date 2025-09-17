///|
fn write_single_page_pdf_file(
  path~ : String,
  content : Content,
) -> Unit raise @fs.IOError {
  let pdf = single_page(content)
  let buf = @fmt.Memory::make(@fmt.Format::count(pdf), 0)
  let offset = @fmt.Format::write(pdf, buf, 0)
  let pdf_file = bytes_of_memory(buf, offset)
  @fs.write_bytes_to_file(path, pdf_file)
}

///|
fn write_multiple_page_pdf_file(
  path~ : String,
  contents : Array[Content],
) -> Unit raise @fs.IOError {
  let pdf = multiple_pages(contents)
  let buf = @fmt.Memory::make(@fmt.Format::count(pdf), 0)
  let offset = @fmt.Format::write(pdf, buf, 0)
  let pdf_file = bytes_of_memory(buf, offset)
  @fs.write_bytes_to_file(path, pdf_file)
}

///|
fn single_page(content : Content) -> @pdf.File {
  // Font resources
  let times_italic_font = @pdf.Dictionary([
    ("/Type", Name("/Font")),
    ("/Subtype", Name("/Type1")),
    ("/BaseFont", Name("/Times-Roman")),
  ])
  let font_f0 = define_font_item(name="/F0", font=times_italic_font)
  let font_resources = define_fonts(fonts=[font_f0])

  // 1 0 obj
  let catalog = define_catalog(pages=Indirect(2))
  let (content_stream, page, page_id) = make_content_and_page(
    start_id=3,
    content,
    parent=Indirect(2),
    resources=[font_resources],
  )
  // 2 0 obj
  let pages = define_pages(pages=[Indirect(page_id)])
  let pdf = make_pdf(Indirect(1), [catalog, pages, content_stream, page])
  pdf
}

///|
fn multiple_pages(contents : Array[Content]) -> @pdf.File {
  // Font resources
  let times_italic_font = @pdf.Dictionary([
    ("/Type", Name("/Font")),
    ("/Subtype", Name("/Type1")),
    ("/BaseFont", Name("/Times-Roman")),
  ])
  let font_f0 = define_font_item(name="/F0", font=times_italic_font)
  let font_resources = define_fonts(fonts=[font_f0])

  // 1 0 obj
  let catalog = define_catalog(pages=Indirect(2))
  let stream_page_id_s = contents.mapi((i, x) => make_content_and_page(
    x,
    start_id=3 + i * 2,
    parent=Indirect(2),
    resources=[font_resources],
  ))
  let pages = []
  let rest_objs = []
  for item in stream_page_id_s {
    let (content_stream, page, page_id) = item
    pages.push(@pdf.Indirect(page_id))
    rest_objs.push(content_stream)
    rest_objs.push(page)
  }
  let pages = define_pages(pages~)
  let pdf = make_pdf(Indirect(1), [catalog, pages, ..rest_objs])
  pdf
}

///|
fn make_content_and_page(
  content : Content,
  parent~ : @pdf.Object,
  start_id~ : Int,
  resources~ : Array[(Bytes, @pdf.Object)],
) -> (@pdf.Object, @pdf.Object, Int) {
  let content_id = start_id
  let page_id = start_id + 1
  let content_stream = content.to_stream_object()
  let page = define_page(
    contents=@pdf.Indirect(content_id),
    parent~,
    resources~,
  )
  (content_stream, page, page_id)
}
