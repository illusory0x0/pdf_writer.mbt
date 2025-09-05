///|
fn make_pdf(catalog : Int, objects : Array[Object]) -> File {
  File::{
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
  let obj = Dictionary([
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
