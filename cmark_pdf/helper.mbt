///|
fn make_pdf(catalog : @pdf.Object, objects : Array[@pdf.Object]) -> @pdf.File {
  @pdf.File::{
    major: 1,
    minor: 4,
    trailer: Dictionary([("/Size", Integer(5)), ("/Root", catalog)]),
    objects,
  }
}

///|
fn define_font_item(name~ : Bytes, font~ : @pdf.Object) -> (Bytes, @pdf.Object) {
  (name, font)
}

///|
fn define_fonts(fonts~ : Array[(Bytes, @pdf.Object)]) -> (Bytes, @pdf.Object) {
  ("/Font", Dictionary(fonts))
}

///|
fn define_pages(pages~ : Array[@pdf.Object]) -> @pdf.Object {
  Dictionary([
    ("/Type", Name("/Pages")),
    ("/Kids", Array(pages)),
    ("/Count", Integer(pages.length())),
  ])
}

///|
fn define_page(
  contents~ : @pdf.Object,
  parent~ : @pdf.Object,
  resources~ : Array[(Bytes, @pdf.Object)],
) -> @pdf.Object {
  Dictionary([
    ("/Type", Name("/Page")),
    ("/Contents", contents),
    ("/Parent", parent),
    (
      "/MediaBox",
      Array([Integer(0), Integer(0), Real(595.2765), Real(841.89105)]),
    ),
    ("/Resources", Dictionary(resources)),
  ])
}

///|
fn define_catalog(pages~ : @pdf.Object) -> @pdf.Object {
  Dictionary([("/Type", Name("/Catalog")), ("/Pages", pages)])
}

///|
fn bytes_of_memory(mem : @fmt.Memory, len : Int) -> Bytes {
  Bytes::makei(len, i => mem[i])
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

///|
/// 
/// PDF Font types:
/// 
/// Subtype Value 
/// `Type0` 
/// `Type1`
/// `MMType1`
/// `Type3`
/// `TrueType`  A font based on the TrueType font format.
/// `CIDFontType0`
/// `CIDFontType2`

///| ToUnicode CMaps:
/// 
/// ISO 32000-2:2020(E) 9.10.3 ToUnicode CMaps
/// 
/// CMap has special syntax embedded in PDF stream object.
/// 
/// you can find full examples via following partial example:
/// 
/// <n> 0 obj 
/// <cmap-dictionary>
/// stream
/// /CIDInit /ProcSet findresource begin
/// ... CMap content ...
/// end 
/// endstream
/// endobj
///
