///|
pub(all) enum Block {
  Heading(level~ : Int, text~ : String)
  Paragraph(Array[String])
  BlankLine
} derive(@json.FromJson, ToJson)

///|
pub(all) struct FlatHeading {
  num : Array[Int]
  text : String
} derive(@json.FromJson, ToJson)

///|
pub(all) struct Doc(Array[Block]) derive(@json.FromJson, ToJson)

///|
pub(all) struct Content(Array[@pdf.GraphicOperator])

///|
fn Content::iter(xs : Self) -> Iter[@pdf.GraphicOperator] {
  xs.0.iter()
}

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
