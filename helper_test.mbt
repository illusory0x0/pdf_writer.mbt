///|
fn make_pdf(catalog : Int, objects : Array[Object]) -> File {
  @pdf.File::{
    major: 1,
    minor: 4,
    trailer: Dictionary([("/Size", Integer(5)), ("/Root", Indirect(catalog))]),
    objects,
  }
}

///|
let default_font : Object = Dictionary([
  ("/Type", Name("/Font")),
  ("/Subtype", Name("/Type1")),
  ("/BaseFont", Name("/Helvetica")),
])

///|
fn define_font_item(name : Bytes, font : Object) -> (Bytes, Object) {
  (name, font)
}

///|
fn define_fonts(fonts : Array[(Bytes, Object)]) -> (Bytes, Object) {
  ("/Font", Dictionary(fonts))
}

///|
fn define_xobject(xobjs : Array[(Bytes, Object)]) -> (Bytes, Object) {
  ("/XObject", Dictionary(xobjs))
}

///|
fn define_pages(pages : Array[Int]) -> Object {
  Dictionary([
    ("/Type", Name("/Pages")),
    ("/Kids", Array(pages.map(Indirect(_)))),
    ("/Count", Integer(pages.length())),
  ])
}

///|
fn define_page(
  contents : Int,
  parent : Int,
  resources : Array[(Bytes, Object)],
) -> Object {
  Dictionary([
    ("/Type", Name("/Page")),
    ("/Contents", Indirect(contents)),
    ("/Parent", Indirect(parent)),
    (
      "/MediaBox",
      Array([Integer(0), Integer(0), Real(595.2765), Real(841.89105)]),
    ),
    ("/Resources", Dictionary(resources)),
  ])
}

///|
fn define_catalog(pages : Int) -> Object {
  Dictionary([("/Type", Name("/Catalog")), ("/Pages", Indirect(pages))])
}

///|
fn define_jpeg_image(
  image : Bytes,
  width : Int,
  height : Int,
  bpc : Int,
  icc : Int,
) -> Object {
  let obj = @pdf.Dictionary([
    ("/Type", Name("/XObject")),
    ("/Subtype", Name("/Image")),
    ("/Width", Integer(width)),
    ("/Height", Integer(height)),
    ("/ColorSpace", Array([Name("/ICCBased"), Indirect(icc)])),
    ("/BitsPerComponent", Integer(bpc)),
    ("/Filter", Name("/DCTDecode")),
    ("/Length", Integer(image.length())),
  ])
  Stream(obj, Stream(image))
}

///|
fn define_icc(icc : Bytes) -> Object {
  Stream(
    Dictionary([
      ("/Length", Integer(icc.length())),
      ("/N", Integer(3)),
      ("/Range", Array([0, 1, 0, 1, 0, 1].map(Integer(_)))),
    ]),
    icc,
  )
}

///|
fn string_of_memory(mem : @fmt.Memory, len : Int) -> String {
  let buf = StringBuilder::new(size_hint=len)
  for i in 0..<len {
    buf.write_char(mem[i].to_char())
  }
  buf.to_string()
}

///|
fn bytes_of_memory(mem : @fmt.Memory, len : Int) -> Bytes {
  Bytes::makei(len, i => mem[i])
}

///|
fn write_graphics_operator_sequence(
  xs : Array[@pdf.GraphicOperator],
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
/// 
/// PDF object stream 
/// 
/// `/Filter` schemas:
/// 
///   FILTER name         Parameters     Description
/// - `/ASCIIHexDecode`   no             ASCII hexadecimal encoding
/// - `/ASCII85Decode`    no             ASCII base-85 encoding
/// - `/LZWDecode`        no             LZW compression
/// - `/FlateDecode`      yes            Flate (zlib/deflate) compression
/// - `/CCITTFaxDecode`   yes            CCITT Group 3 or 4 compression for monochrome images(1 bit per pixel)
/// - `/JBIG2Decode`      yes            JBIG2 compression for monochrome images(1 bit per pixel)
/// - `/DCTDecode`        no             JPEG compression 
/// - `/JPXDecode`        no             JPEG 2000 compression
/// - `/Crypt`            yes            Decryption filter
