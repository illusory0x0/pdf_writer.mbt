///|
pub(all) enum Block {
  Heading(level~ : Int, text~ : String)
  Paragraph(Array[Inline])
  BlankLine
  CodeBlock(language~ : String, code~ : Array[Bytes])
  MoonBitCodeBlock(Array[Array[ColorSpaned]])
  Blocks(Array[Block])
  List(Array[Block])
} derive(Show, ToJson)

///|
pub(all) enum TokenStyle {
  Keyword
  Num
  Str
  Other
} derive(Show, ToJson)

///|
pub(all) enum Inline {
  Plain(String)
  StrongEmphasis(String)
  Emphasis(String)
  StrongEmphasis_Emphasis(String)
  CodeSpan(String)
} derive(Show, ToJson)

///|
pub(all) struct FlatHeading {
  num : Array[Int]
  text : String
} derive(Show, ToJson)

///|
pub(all) struct Doc(Array[Block]) derive(Show, ToJson)

///|
pub(all) struct Content(Array[@pdf.GraphicOperator])

///|
struct Canvas(Array[@pdf.GraphicOperator])

///|
/// 
/// The PostScript language names of 14 Type 1 fonts, known as the 
/// standard 14 fonts.
/// 
/// in PDF 1.0 to PDF 1.7, some PDF dictionary object fields is optional.
/// 
/// - `FirstChar` 
/// - `LastChar`
/// - `Widths`
/// - `FontDescriptor`
/// 
pub(all) enum StandardFont {
  TimesRoman
  TimesBold
  TimesItalic
  TimesBoldItalic
  Helvetica
  HelveticaBold
  HelveticaOblique
  HelveticaBoldOblique
  Courier
  CourierBold
  CourierOblique
  CourierBoldOblique
  Symbol
  ZapfDingbats
}
