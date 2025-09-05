///|
fn write_graphics_operator_sequence(
  xs : Array[GraphicsOp],
  buf : @fmt.Memory,
  start : Int,
) -> Int {
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
