///|
fn write_ops(xs : Array[GraphicsOp], buf : @fmt.Memory, start : Int) -> Int {
  let mut offset = start
  for x in xs {
    offset += @fmt.Format::write(x, buf, offset)
  }
  offset - start
}

///|
test "@fmt.Format for Object" {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let value = Object::Integer(42)
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="42")
  let value = Null
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="null")
  let value = Boolean(true)
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="true")
  let value = Boolean(false)
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="false")
  let value = Real(3.14)
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="3.14")
  let value = String(b"Hello, World!")
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="(Hello, World!)")
  let value = Name(b"/Name")
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="/Name")
  let value = Array([Integer(1), Integer(2), Integer(3)])
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="[1 2 3]")
  let value = Dictionary([("/Type", Name(b"/Example")), ("/Count", Integer(3))])
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(
    string_of_memory(buffer, offset),
    content=(
      #|<<
      #|  /Type /Example  
      #|  /Count 3
      #|>>
    ),
  )
  let value = Object::Stream(
    Dictionary([("/Length", Integer(11))]),
    b"Hello World",
  )
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(
    string_of_memory(buffer, offset),
    content=(
      #|<<
      #|  /Length 11
      #|>>
      #|stream
      #|Hello World
      #|endstream
    ),
  )
  let value = Indirect(1)
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="1 0 R")
  let value = Dictionary([
    ("/Type", Name("/Pages")),
    ("/Kids", Integer(1)),
    ("/Count", Integer(1)),
  ])
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(
    string_of_memory(buffer, offset),
    content=(
      #|<<
      #|  /Type /Pages  
      #|  /Kids 1  
      #|  /Count 1
      #|>>
    ),
  )
  let value = Array([Indirect(1)])
  let offset = @fmt.Format::write(value, buffer, 0)
  inspect(string_of_memory(buffer, offset), content="[1 0 R]")
}

///|
test "write_ops" {
  let buffer = @fmt.Memory::make(4096, Byte::default())
  let mut offset = 0
  offset += @fmt.format_write(b" ET", [], buffer, offset)
  offset += @fmt.format_write(b" BT", [], buffer, offset)
  inspect(string_of_memory(buffer, offset), content=" ET BT")
}

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
  let op1 = Op_cm(tm)
  let op2 = Op_BT
  let op3 = Op_Tf("/F0", 36)
  let op4 = Op_Tj("Hello, World!")
  let op5 = Op_ET
  let ops = [op1, op2, op3, op4, op5]
  let offset = write_ops(ops, buf, 0)
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
test {
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
  let op1 = Op_cm(tm)
  let op2 = Op_BT
  let op3 = Op_Tf("/F0", 36)
  let op4 = Op_Tj("Hello, World!")
  let op5 = Op_ET
  let ops = [op1, op2, op3, op4, op5]
  let offset = write_ops(ops, buf, 0)
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
  let times_italic_font = Dictionary([
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
}

///|
test "image" {
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
  let ops = [Op_cm(tm), Op_Do("/Im0")]
  let offset = write_ops(ops, buf, 0)
  let bytes = bytes_of_memory(buf, offset)
  let len = bytes.length()

  // 1 0 obj
  let stm = Object::Stream(Dictionary([("/Length", Integer(len))]), bytes)
  // 2 0 obj - Use define_pages helper
  let pages = define_pages([4])

  // 3 0 obj - Use define_catalog helper
  let catalog = define_catalog(2)

  // 4 0 obj - Use define_page and helper functions for resources
  let times_italic_font = Dictionary([
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
}
