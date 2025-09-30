///|
fn bytes_of_memory(mem : @fmt.Memory, len : Int) -> Bytes {
  Bytes::makei(len, i => mem[i])
}

///|
fn string_of_pdf_object(obj : @pdf.Object) -> String {
  let buf = @fmt.Memory::make(@fmt.Format::count(obj), 0)
  let ofs = @fmt.Format::write(obj, buf, 0)
  let bytes = bytes_of_memory(buf, ofs)
  ascii_string_of_bytesview(bytes)
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

///|
test "empty dictionary" {
  let s = b"<< >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="<<\\n\\n>>")
  @json.inspect(obj, content=["Dictionary", []])
}

///|
test "dictionary with single entry" {
  let s = b"<< /Type /Font >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(string_of_pdf_object(obj), content="<<\\n  Type Font\\n>>")
  @json.inspect(obj, content=["Dictionary", [["Type", ["Name", "Font"]]]])
}

///|
test "dictionary with multiple entries" {
  let s = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Type Font  \\n  Subtype Type1  \\n  BaseFont Helvetica\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Type", ["Name", "Font"]],
      ["Subtype", ["Name", "Type1"]],
      ["BaseFont", ["Name", "Helvetica"]],
    ],
  ])
}

///|
test "dictionary with integer values" {
  let s = b"<< /Width 612 /Height 792 /Count 5 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Width 612  \\n  Height 792  \\n  Count 5\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Width", ["Integer", 612]],
      ["Height", ["Integer", 792]],
      ["Count", ["Integer", 5]],
    ],
  ])
}

///|
test "dictionary with real values" {
  let s = b"<< /X 72.5 /Y 144.25 /Scale 1.5 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  X 72.5  \\n  Y 144.25  \\n  Scale 1.5\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["X", ["Real", 72.5]], ["Y", ["Real", 144.25]], ["Scale", ["Real", 1.5]]],
  ])
}

///|
test "dictionary with boolean values" {
  let s = b"<< /Visible true /Hidden false /Required true >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Visible true  \\n  Hidden false  \\n  Required true\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Visible", ["Boolean", true]],
      ["Hidden", ["Boolean", false]],
      ["Required", ["Boolean", true]],
    ],
  ])
}

///|
test "dictionary with null values" {
  let s = b"<< /Parent null /Next null /Prev 123 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Parent null  \\n  Next null  \\n  Prev 123\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["Parent", "Null"], ["Next", "Null"], ["Prev", ["Integer", 123]]],
  ])
}

///|
test "dictionary with string values" {
  let s = b"<< /Title <48656C6C6F> /Author <576F726C64> >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Title (Hello)  \\n  Author (World)\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["Title", ["String", "Hello"]], ["Author", ["String", "World"]]],
  ])
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
test "dictionary with image XObject structure" {
  let s = b"<< /Type /XObject /Subtype /Image /Width 100 /Height 200 /BitsPerComponent 8 /ColorSpace /DeviceRGB >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Type XObject  \\n  Subtype Image  \\n  Width 100  \\n  Height 200  \\n  BitsPerComponent 8  \\n  ColorSpace DeviceRGB\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Type", ["Name", "XObject"]],
      ["Subtype", ["Name", "Image"]],
      ["Width", ["Integer", 100]],
      ["Height", ["Integer", 200]],
      ["BitsPerComponent", ["Integer", 8]],
      ["ColorSpace", ["Name", "DeviceRGB"]],
    ],
  ])
}

///|
test "dictionary with empty strings" {
  let s = b"<< /EmptyString <> /NonEmpty <48656C6C6F> >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  EmptyString ()  \\n  NonEmpty (Hello)\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["EmptyString", ["String", ""]], ["NonEmpty", ["String", "Hello"]]],
  ])
}

///|
test "dictionary with image XObject structure" {
  let s = b"<< /Type /XObject /Subtype /Image /Width 100 /Height 200 /BitsPerComponent 8 /ColorSpace /DeviceRGB >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Type XObject  \\n  Subtype Image  \\n  Width 100  \\n  Height 200  \\n  BitsPerComponent 8  \\n  ColorSpace DeviceRGB\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Type", ["Name", "XObject"]],
      ["Subtype", ["Name", "Image"]],
      ["Width", ["Integer", 100]],
      ["Height", ["Integer", 200]],
      ["BitsPerComponent", ["Integer", 8]],
      ["ColorSpace", ["Name", "DeviceRGB"]],
    ],
  ])
}

///|
test "dictionary with negative numbers" {
  let s = b"<< /X -72 /Y -144 /Offset -3.5 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  X -72  \\n  Y -144  \\n  Offset -3.5\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["X", ["Integer", -72]],
      ["Y", ["Integer", -144]],
      ["Offset", ["Real", -3.5]],
    ],
  ])
}

///|
test "dictionary with scientific notation" {
  let s = b"<< /Large 1e6 /Small 2.5e-3 /Medium 3.14E+2 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Large 1000000  \\n  Small 0.0025  \\n  Medium 314\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Large", ["Real", 1000000]],
      ["Small", ["Real", 0.0025]],
      ["Medium", ["Real", 314]],
    ],
  ])
}

///|
test "dictionary with zero values" {
  let s = b"<< /Zero 0 /ZeroReal 0.0 /NegZero -0 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Zero 0  \\n  ZeroReal 0  \\n  NegZero 0\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Zero", ["Integer", 0]],
      ["ZeroReal", ["Real", 0]],
      ["NegZero", ["Integer", 0]],
    ],
  ])
}

///|
test "dictionary with empty strings" {
  let s = b"<< /EmptyString <> /NonEmpty <48656C6C6F> >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  EmptyString ()  \\n  NonEmpty (Hello)\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["EmptyString", ["String", ""]], ["NonEmpty", ["String", "Hello"]]],
  ])
}

///|
test "dictionary with all null values" {
  let s = b"<< /A null /B null /C null >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  A null  \\n  B null  \\n  C null\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["A", "Null"], ["B", "Null"], ["C", "Null"]],
  ])
}

///|
test "dictionary with all boolean combinations" {
  let s = b"<< /True true /False false /AlsoTrue true /AlsoFalse false >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  True true  \\n  False false  \\n  AlsoTrue true  \\n  AlsoFalse false\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["True", ["Boolean", true]],
      ["False", ["Boolean", false]],
      ["AlsoTrue", ["Boolean", true]],
      ["AlsoFalse", ["Boolean", false]],
    ],
  ])
}

///|
test "dictionary with long hex strings" {
  let s = b"<< /Data <48656C6C6F20576F726C64> /Short <41> >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Data (Hello World)  \\n  Short (A)\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [["Data", ["String", "Hello World"]], ["Short", ["String", "A"]]],
  ])
}

///|
test "dictionary with precision real numbers" {
  let s = b"<< /Pi 3.14159265 /E 2.71828 /Sqrt2 1.414213 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Pi 3.14159265  \\n  E 2.71828  \\n  Sqrt2 1.414213\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Pi", ["Real", 3.14159265]],
      ["E", ["Real", 2.71828]],
      ["Sqrt2", ["Real", 1.414213]],
    ],
  ])
}

///|
test "dictionary with very large integers" {
  let s = b"<< /Large 2147483647 /Negative -2147483648 /Zero 0 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Large 2147483647  \\n  Negative -2147483648  \\n  Zero 0\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Large", ["Integer", 2147483647]],
      ["Negative", ["Integer", -2147483648]],
      ["Zero", ["Integer", 0]],
    ],
  ])
}

///|
test "dictionary with mixed indirect references" {
  let s = b"<< /Object1 123 0 R /Object2 456 0 R /Direct /Name >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Object1 123 0 R  \\n  Object2 456 0 R  \\n  Direct Name\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Object1", ["Indirect", 123]],
      ["Object2", ["Indirect", 456]],
      ["Direct", ["Name", "Name"]],
    ],
  ])
}

///|
test "dictionary with alternating types" {
  let s = b"<< /A 1 /B true /C <41> /D /Name /E null /F 3.14 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  A 1  \\n  B true  \\n  C (A)  \\n  D Name  \\n  E null  \\n  F 3.14\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["A", ["Integer", 1]],
      ["B", ["Boolean", true]],
      ["C", ["String", "A"]],
      ["D", ["Name", "Name"]],
      ["E", "Null"],
      ["F", ["Real", 3.14]],
    ],
  ])
}

///|
test "dictionary with only names" {
  let s = b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Type Font  \\n  Subtype Type1  \\n  BaseFont Helvetica\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Type", ["Name", "Font"]],
      ["Subtype", ["Name", "Type1"]],
      ["BaseFont", ["Name", "Helvetica"]],
    ],
  ])
}

///|
test "dictionary with only integers" {
  let s = b"<< /Width 100 /Height 200 /Depth 50 /Count 42 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Width 100  \\n  Height 200  \\n  Depth 50  \\n  Count 42\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Width", ["Integer", 100]],
      ["Height", ["Integer", 200]],
      ["Depth", ["Integer", 50]],
      ["Count", ["Integer", 42]],
    ],
  ])
}

///|
test "dictionary with only reals" {
  let s = b"<< /X 72.0 /Y 144.5 /Scale 1.0 /Opacity 0.75 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  X 72  \\n  Y 144.5  \\n  Scale 1  \\n  Opacity 0.75\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["X", ["Real", 72]],
      ["Y", ["Real", 144.5]],
      ["Scale", ["Real", 1]],
      ["Opacity", ["Real", 0.75]],
    ],
  ])
}

///|
test "dictionary with only booleans" {
  let s = b"<< /Visible true /Hidden false /Required true /Optional false >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Visible true  \\n  Hidden false  \\n  Required true  \\n  Optional false\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Visible", ["Boolean", true]],
      ["Hidden", ["Boolean", false]],
      ["Required", ["Boolean", true]],
      ["Optional", ["Boolean", false]],
    ],
  ])
}

///|
test "dictionary with only strings" {
  let s = b"<< /Title <48656C6C6F> /Author <576F726C64> /Subject <54657374> >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Title (Hello)  \\n  Author (World)  \\n  Subject (Test)\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Title", ["String", "Hello"]],
      ["Author", ["String", "World"]],
      ["Subject", ["String", "Test"]],
    ],
  ])
}

///|
test "dictionary with only indirect references" {
  let s = b"<< /Parent 1 0 R /Next 2 0 R /Prev 3 0 R /Root 4 0 R >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  Parent 1 0 R  \\n  Next 2 0 R  \\n  Prev 3 0 R  \\n  Root 4 0 R\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["Parent", ["Indirect", 1]],
      ["Next", ["Indirect", 2]],
      ["Prev", ["Indirect", 3]],
      ["Root", ["Indirect", 4]],
    ],
  ])
}

///|
test "dictionary with single character keys" {
  let s = b"<< /A 1 /B 2 /C 3 /D 4 /E 5 >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  A 1  \\n  B 2  \\n  C 3  \\n  D 4  \\n  E 5\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["A", ["Integer", 1]],
      ["B", ["Integer", 2]],
      ["C", ["Integer", 3]],
      ["D", ["Integer", 4]],
      ["E", ["Integer", 5]],
    ],
  ])
}

///|
test "dictionary with long key names" {
  let s = b"<< /VeryLongKeyNameThatExceedsNormalLength 42 /AnotherExtremelyLongKeyName /Value >>"
  let tokens = tokenize(s)
  let obj = parse(tokens)
  inspect(
    string_of_pdf_object(obj),
    content="<<\\n  VeryLongKeyNameThatExceedsNormalLength 42  \\n  AnotherExtremelyLongKeyName Value\\n>>",
  )
  @json.inspect(obj, content=[
    "Dictionary",
    [
      ["VeryLongKeyNameThatExceedsNormalLength", ["Integer", 42]],
      ["AnotherExtremelyLongKeyName", ["Name", "Value"]],
    ],
  ])
}
