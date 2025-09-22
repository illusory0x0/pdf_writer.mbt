///|
fn string_of_pdf_object(obj : Object) -> String {
  let buf = @fmt.Memory::make(@fmt.Format::count(obj), 0)
  let ofs = @fmt.Format::write(obj, buf, 0)
  let bytes = bytes_of_memory(buf, ofs)
  ascii_string_of_bytes(bytes)
}

///|
test "basic integer array" {
  let s = b"[123 323 434]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[123 323 434]")
  @json.inspect(obj, content=[
    "Array",
    [["Integer", 123], ["Integer", 323], ["Integer", 434]],
  ])
}

///|
test "empty array" {
  let s = b"[]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[]")
  @json.inspect(obj, content=["Array", []])
}

///|
test "array with single element" {
  let s = b"[42]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[42]")
  @json.inspect(obj, content=["Array", [["Integer", 42]]])
}

///|
test "dictionary with indirect references" {
  let s = b"<< /Parent 1 0 R /Contents 2 0 R /Resources 3 0 R >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Parent 1 0 R  \\n  Contents 2 0 R  \\n  Resources 3 0 R\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Parent", ["Indirect", 1]],
      ["Contents", ["Indirect", 2]],
      ["Resources", ["Indirect", 3]],
    ],
  ])
}

///|
test "array with whitespace variations" {
  let s = b"[ 1   2\t3\n4\r5 ]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[1 2 3 4 5]")
  @json.inspect(obj, content=[
    "Array",
    [
      ["Integer", 1],
      ["Integer", 2],
      ["Integer", 3],
      ["Integer", 4],
      ["Integer", 5],
    ],
  ])
}

///|
test "dictionary with PDF catalog structure" {
  let s = b"<< /Type /Catalog /Pages 1 0 R /Outlines 2 0 R >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Type Catalog  \\n  Pages 1 0 R  \\n  Outlines 2 0 R\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Type", ["Name", "Catalog"]],
      ["Pages", ["Indirect", 1]],
      ["Outlines", ["Indirect", 2]],
    ],
  ])
}

///|
test "array with PDF dash pattern" {
  let s = b"[3 2 1 4]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[3 2 1 4]")
  @json.inspect(obj, content=[
    "Array",
    [["Integer", 3], ["Integer", 2], ["Integer", 1], ["Integer", 4]],
  ])
}

///|
test "array with scientific notation numbers" {
  let s = b"[1e5 -2.5e-3 3.14E+2]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[100000 -0.0025 314]")
  @json.inspect(obj, content=[
    "Array",
    [["Real", 100000], ["Real", -0.0025], ["Real", 314]],
  ])
}

///|
test "array with zero values" {
  let s = b"[0 0.0 -0 -0.0]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[0 0 0 0]")
  @json.inspect(obj, content=[
    "Array",
    [["Integer", 0], ["Real", 0], ["Integer", 0], ["Real", 0]],
  ])
}

///|
test "array with large numbers" {
  let s = b"[999999999 -999999999 1.7976931348623157e308]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="[999999999 -999999999 1.7976931348623157e+308]",
  )
  @json.inspect(obj, content=[
    "Array",
    [
      ["Integer", 999999999],
      ["Integer", -999999999],
      ["Real", 1.7976931348623157e+308],
    ],
  ])
}

///|
test "array with special float values" {
  let s = b"[0.1 0.01 0.001 10.0 100.0 1000.0]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[0.1 0.01 0.001 10 100 1000]")
  @json.inspect(obj, content=[
    "Array",
    [
      ["Real", 0.1],
      ["Real", 0.01],
      ["Real", 0.001],
      ["Real", 10],
      ["Real", 100],
      ["Real", 1000],
    ],
  ])
}

///|
test "array with empty string" {
  let s = b"[<> /Name <>]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[() Name ()]")
  @json.inspect(obj, content=[
    "Array",
    [["String", ""], ["Name", "Name"], ["String", ""]],
  ])
}

///|
test "array for PDF rectangle" {
  let s = b"[0 0 612 792]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[0 0 612 792]")
  @json.inspect(obj, content=[
    "Array",
    [["Integer", 0], ["Integer", 0], ["Integer", 612], ["Integer", 792]],
  ])
}

///|
test "array for PDF transformation matrix" {
  let s = b"[1 0 0 1 72 720]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[1 0 0 1 72 720]")
  @json.inspect(obj, content=[
    "Array",
    [
      ["Integer", 1],
      ["Integer", 0],
      ["Integer", 0],
      ["Integer", 1],
      ["Integer", 72],
      ["Integer", 720],
    ],
  ])
}

///|
test "array for PDF color space" {
  let s = b"[/DeviceRGB]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[DeviceRGB]")
  @json.inspect(obj, content=["Array", [["Name", "DeviceRGB"]]])
}

///|
test "array with PDF procedure set" {
  let s = b"[/PDF /Text /ImageB /ImageC /ImageI]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[PDF Text ImageB ImageC ImageI]")
  @json.inspect(obj, content=[
    "Array",
    [
      ["Name", "PDF"],
      ["Name", "Text"],
      ["Name", "ImageB"],
      ["Name", "ImageC"],
      ["Name", "ImageI"],
    ],
  ])
}

///|
test "array with mixed real and integer" {
  let s = b"[72 72.0 144 144.0]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="[72 72 144 144]")
  @json.inspect(obj, content=[
    "Array",
    [["Integer", 72], ["Real", 72], ["Integer", 144], ["Real", 144]],
  ])
}

///|
test "array with all basic types combined" {
  let s = b"[123 3.14 true false null /Name <48656C6C6F> 456 0 R]"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="[123 3.14 true false null Name (Hello) 456 0 R]",
  )
  @json.inspect(obj, content=[
    "Array",
    [
      ["Integer", 123],
      ["Real", 3.14],
      ["Boolean", true],
      ["Boolean", false],
      "Null",
      ["Name", "Name"],
      ["String", "Hello"],
      ["Indirect", 456],
    ],
  ])
}
