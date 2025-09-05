///|
test "test write to file" {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let buf = buffer

  // Use define_pages helper function
  let pages = define_pages([4])
  let offset = @fmt.Format::write(pages, buf, 0)
  inspect(
    string_of_memory(buffer, offset),
    content=(
      #|<<
      #|  /Type /Pages  
      #|  /Kids [4 0 R]  
      #|  /Count 1
      #|>>
    ),
  )
  let tm : TransformMatrix = TransformMatrix::{
    a: 1,
    b: 0,
    c: 0,
    d: 1,
    e: 50,
    f: 770,
  }
  let op1 = @pdf.Op_cm(tm)
  let op2 = @pdf.Op_BT
  let op3 = @pdf.Op_Tf("/F0", 36)
  let op4 = @pdf.Op_Tj("Hello, World!")
  let op5 = @pdf.Op_ET
  let ops = [op1, op2, op3, op4, op5]
  let offset = write_graphics_operator_sequence(ops, buf, 0)
  let bytes = bytes_of_memory(buf, offset)
  let len = bytes.length()
  let stm = Object::Stream(Dictionary([("/Length", Integer(len))]), bytes)
  let offset = @fmt.Format::write(stm, buf, 0)
  inspect(
    string_of_memory(buffer, offset),
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
  inspect(string_of_memory(buffer, offset), content=" ET")
}

///|
test (t : @test.T) {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let buf = buffer
  let tm : TransformMatrix = TransformMatrix::{
    a: 1,
    b: 0,
    c: 0,
    d: 1,
    e: 50,
    f: 770,
  }
  let op1 = @pdf.Op_cm(tm)
  let op2 = @pdf.Op_BT
  let op3 = @pdf.Op_Tf("/F0", 36)
  let op4 = @pdf.Op_Tj("Hello, World!")
  let op5 = @pdf.Op_ET
  let ops = [op1, op2, op3, op4, op5]
  let offset = write_graphics_operator_sequence(ops, buf, 0)
  inspect(
    string_of_memory(buf, offset),
    content=" 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET",
  )
  let bytes = bytes_of_memory(buf, offset)
  let len = bytes.length()

  // 1 0 obj
  let stm = Object::Stream(Dictionary([("/Length", Integer(len))]), bytes)
  // 2 0 obj - Use define_pages helper
  let pages = define_pages([4])

  // 3 0 obj - Use define_catalog helper
  let catalog = define_catalog(2)

  // 4 0 obj - Use define_page and helper functions for resources
  let times_italic_font = @pdf.Dictionary([
    ("/Type", Name("/Font")),
    ("/Subtype", Name("/Type1")),
    ("/BaseFont", Name("/Times-Italic")),
  ])
  let font_f0 = define_font_item("/F0", times_italic_font)
  let font_resources = define_fonts([font_f0])
  let page = define_page(1, 2, [font_resources])
  let offset = @fmt.Format::write(stm, buf, 0)
  inspect(
    string_of_memory(buf, offset),
    content=(
      #|<<
      #|  /Length 53
      #|>>
      #|stream
      #| 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET
      #|endstream
    ),
  )
  let offset = @fmt.Format::write(pages, buf, 0)
  inspect(
    string_of_memory(buf, offset),
    content=(
      #|<<
      #|  /Type /Pages  
      #|  /Kids [4 0 R]  
      #|  /Count 1
      #|>>
    ),
  )
  let offset = @fmt.Format::write(catalog, buf, 0)
  inspect(
    string_of_memory(buf, offset),
    content=(
      #|<<
      #|  /Type /Catalog  
      #|  /Pages 2 0 R
      #|>>
    ),
  )
  let offset = @fmt.Format::write(page, buf, 0)
  inspect(
    string_of_memory(buf, offset),
    content=(
      #|<<
      #|  /Type /Page  
      #|  /Contents 1 0 R  
      #|  /Parent 2 0 R  
      #|  /MediaBox [0 0 595.2765 841.89105]  
      #|  /Resources <<
      #|  /Font <<
      #|  /F0 <<
      #|  /Type /Font  
      #|  /Subtype /Type1  
      #|  /BaseFont /Times-Italic
      #|>>
      #|>>
      #|>>
      #|>>
    ),
  )
  let pdf = make_pdf(3, [stm, pages, catalog, page])
  let offset = @fmt.Format::write(pdf, buf, 0)
  let pdf_file = bytes_of_memory(buf, offset)
  @fs.write_bytes_to_file("./output/hello.pdf", pdf_file)
  t.writeln(pdf_file)
  t.snapshot(filename="hello.pdf.bytes")
}

///|
test "image" (t : @test.T) {
  let buffer = @fmt.Memory::make(1_000_000, Byte::default())
  let buf = buffer
  let times = 28.0
  let tm : TransformMatrix = TransformMatrix::{
    a: 3.6 * times,
    b: 0,
    c: 0,
    d: 1 * times,
    e: 50,
    f: 770,
  }
  let ops : Array[@pdf.GraphicOperator] = [Op_cm(tm), Op_Do("/Im0")]
  let offset = write_graphics_operator_sequence(ops, buf, 0)
  let bytes = bytes_of_memory(buf, offset)
  let len = bytes.length()

  // 1 0 obj
  let stm = Object::Stream(Dictionary([("/Length", Integer(len))]), bytes)
  // 2 0 obj - Use define_pages helper
  let pages = define_pages([4])

  // 3 0 obj - Use define_catalog helper
  let catalog = define_catalog(2)

  // 4 0 obj - Use define_page and helper functions for resources
  let times_italic_font = @pdf.Dictionary([
    ("/Type", Name("/Font")),
    ("/Subtype", Name("/Type1")),
    ("/BaseFont", Name("/Times-Italic")),
  ])
  let image_bytes = @fs.read_file_to_bytes("images/ocaml.jpg")
  // 5 0 obj 
  //2187x601
  let image = define_jpeg_image(image_bytes, 2187, 601, 8, 6)
  let icc_bytes = @fs.read_file_to_bytes("./typst.icc")
  // 6 0 obj 
  let icc = define_icc(icc_bytes)
  let font_f0 = define_font_item("/F0", times_italic_font)
  let font_resources = define_fonts([font_f0])
  let xobjects = define_xobject([("/Im0", Indirect(5))])
  let page = define_page(1, 2, [font_resources, xobjects])
  let pdf = make_pdf(3, [stm, pages, catalog, page, image, icc])
  let offset = @fmt.Format::write(pdf, buf, 0)
  let bytes = bytes_of_memory(buf, offset)
  @fs.write_bytes_to_file("./output/ocaml.pdf", bytes)
  t.writeln(bytes)
  t.snapshot(filename="ocaml.pdf.bytes")
}
