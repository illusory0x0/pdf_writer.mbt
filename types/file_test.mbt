///|
test "test write to file" {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let buf = buffer

  // Use define_pages helper function
  let pages = @pdf_helper.define_pages(pages=[@pdf.Indirect(4)])
  let offset = @fmt.write(pages, buf, 0)
  inspect(
    @mem_helper.string_of_memory(buffer, offset),
    content=(
      #|<<
      #|  /Type /Pages  
      #|  /Kids [4 0 R]  
      #|  /Count 1
      #|>>
    ),
  )
  let tm : @pdf.TransformMatrix = @pdf.TransformMatrix::{
    a: 1,
    b: 0,
    c: 0,
    d: 1,
    e: 50,
    f: 770,
  }
  let op1 = @pdf.Op_cm(tm)
  let op2 = @pdf.Op_BT
  let op3 = @pdf.Op_Tf(b"/F0", 36)
  let op4 = @pdf.Op_Tj(b"Hello, World!")
  let op5 = @pdf.Op_ET
  let content : @pdf.ContentStream = [op1, op2, op3, op4, op5]
  let offset = @fmt.write(content, buf, 0)
  let bytes = @mem_helper.bytes_of_memory(buf, offset)
  let len = bytes.length()
  let stm = @pdf.Object::Stream(
    @pdf.Dictionary([("/Length", @pdf.Integer(len))]),
    bytes,
  )
  let offset = @fmt.write(stm, buf, 0)
  inspect(
    @mem_helper.string_of_memory(buffer, offset),
    content=(
      #|<<
      #|  /Length 53
      #|>>
      #|stream
      #| 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET
      #|endstream
    ),
  )
}

///|
test {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let offset = @fmt.format_write(" ET", [], buffer, 0)
  inspect(@mem_helper.string_of_memory(buffer, offset), content=" ET")
}

///|
/// 
/// first and last should be indirect references
fn make_outline(first : @pdf.Object, last : @pdf.Object) -> @pdf.Object {
  @pdf.Dictionary([
    ("/Type", @pdf.Name(b"/Outlines")),
    ("/First", first),
    ("/Last", last),
    ("/Count", @pdf.Integer(0)),
  ])
}

///|
fn make_outline_item(
  title : Bytes,
  parent : @pdf.Object,
  prev : @pdf.Object,
  next : @pdf.Object,
  first : @pdf.Object,
  last : @pdf.Object,
) -> @pdf.Object {
  @pdf.Dictionary([
    ("/Title", @pdf.String(title)),
    ("/Parent", parent),
    ("/Prev", prev),
    ("/Next", next),
    ("/First", first),
    ("/Last", last),
    ("/Count", @pdf.Integer(0)),
  ])
}

///|
fn define_catalog(pages~ : @pdf.Object, outlines~ : @pdf.Object) -> @pdf.Object {
  Dictionary([("/Type", Name("/Catalog")), ("/Pages", pages), ("/Outlines", outlines)])
}


///|
test (t : @test.T) {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let buf = buffer
  let tm : @pdf.TransformMatrix = @pdf.TransformMatrix::{
    a: 1,
    b: 0,
    c: 0,
    d: 1,
    e: 50,
    f: 770,
  }
  let op1 = @pdf.Op_cm(tm)
  let op2 = @pdf.Op_BT
  let op3 = @pdf.Op_Tf(b"/F0", 36)
  let op4 = @pdf.Op_Tj(b"Hello, World!")
  let op5 = @pdf.Op_ET
  let content : @pdf.ContentStream = [op1, op2, op3, op4, op5]
  let offset = @fmt.write(content, buf, 0)
  inspect(
    @mem_helper.string_of_memory(buf, offset),
    content=" 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET",
  )
  let bytes = @mem_helper.bytes_of_memory(buf, offset)
  let len = bytes.length()

  // 1 0 obj
  let stm = @pdf.Object::Stream(
    @pdf.Dictionary([("/Length", @pdf.Integer(len))]),
    bytes,
  )
  // 2 0 obj - Use define_pages helper
  let pages = @pdf_helper.define_pages(pages=[@pdf.Indirect(4)])

  // 3 0 obj - Use define_catalog helper
  let catalog = define_catalog(pages=@pdf.Indirect(2), outlines=@pdf.Indirect(5))

  let times_italic_font = @pdf.Dictionary([
    ("/Type", @pdf.Name(b"/Font")),
    ("/Subtype", @pdf.Name(b"/Type1")),
    ("/BaseFont", @pdf.Name(b"/Times-Italic")),
  ])
  let font_f0 = @pdf_helper.define_font_item(
    name=b"/F0",
    font=times_italic_font,
  )
  // 4 0 obj - Use define_page and helper functions for resources
  let font_resources = @pdf_helper.define_fonts(fonts=[font_f0])
  let page = @pdf_helper.define_page(
    contents=@pdf.Indirect(1),
    parent=@pdf.Indirect(2),
    resources=[font_resources],
  )
  // 5 0 obj - outline dictionary
  let outline = make_outline(@pdf.Indirect(6), @pdf.Indirect(6))
  // 6 0 obj - outline item
  let outline_item = make_outline_item("Chapter 1", @pdf.Indirect(5), @pdf.Null, @pdf.Null, @pdf.Null, @pdf.Null)


  let pdf = @pdf_helper.make_pdf(@pdf.Indirect(3), [stm, pages, catalog, page,outline,outline_item])
  let offset = @fmt.write(pdf, buf, 0)
  let pdf_file = @mem_helper.bytes_of_memory(buf, offset)
  @fs.write_bytes_to_file("./output/hello.pdf", pdf_file)
  t.writeln(pdf_file)
  t.snapshot(filename="hello.pdf.bytes")
}

///|
test "image" (t : @test.T) {
  let buffer = @fmt.Memory::make(1_000_000, Byte::default())
  let buf = buffer
  let times = 28.0
  let tm : @pdf.TransformMatrix = @pdf.TransformMatrix::{
    a: 3.6 * times,
    b: 0,
    c: 0,
    d: 1 * times,
    e: 50,
    f: 770,
  }
  let content : @pdf.ContentStream = [@pdf.Op_cm(tm), @pdf.Op_Do(b"/Im0")]
  let offset = @fmt.write(content, buf, 0)
  let bytes = @mem_helper.bytes_of_memory(buf, offset)
  let len = bytes.length()

  // 1 0 obj
  let stm = @pdf.Object::Stream(
    @pdf.Dictionary([("/Length", @pdf.Integer(len))]),
    bytes,
  )
  // 2 0 obj - Use define_pages helper
  let pages = @pdf_helper.define_pages(pages=[@pdf.Indirect(4)])

  // 3 0 obj - Use define_catalog helper
  let catalog = @pdf_helper.define_catalog(pages=@pdf.Indirect(2))

  // 4 0 obj - Use define_page and helper functions for resources
  let times_italic_font = @pdf.Dictionary([
    ("/Type", @pdf.Name(b"/Font")),
    ("/Subtype", @pdf.Name(b"/Type1")),
    ("/BaseFont", @pdf.Name(b"/Times-Italic")),
  ])
  let image_bytes = @fs.read_file_to_bytes("images/ocaml.jpg")
  // 5 0 obj 
  //2187x601
  let image = @pdf_helper.define_jpeg_image(
    image=image_bytes,
    width=2187,
    height=601,
    bpc=8,
    icc=6,
  )
  let icc_bytes = @fs.read_file_to_bytes("./typst.icc")
  // 6 0 obj 
  let icc = @pdf_helper.define_icc(icc=icc_bytes)
  let font_f0 = @pdf_helper.define_font_item(
    name=b"/F0",
    font=times_italic_font,
  )
  let font_resources = @pdf_helper.define_fonts(fonts=[font_f0])
  let xobjects = @pdf_helper.define_xobject(xobjs=[(b"/Im0", @pdf.Indirect(5))])
  let page = @pdf_helper.define_page(
    contents=@pdf.Indirect(1),
    parent=@pdf.Indirect(2),
    resources=[font_resources, xobjects],
  )
  let pdf = @pdf_helper.make_pdf(@pdf.Indirect(3), [
    stm, pages, catalog, page, image, icc,
  ])
  let offset = @fmt.write(pdf, buf, 0)
  let bytes = @mem_helper.bytes_of_memory(buf, offset)
  @fs.write_bytes_to_file("./output/ocaml.pdf", bytes)
  t.writeln(bytes)
  t.snapshot(filename="ocaml.pdf.bytes")
}
