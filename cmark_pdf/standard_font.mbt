///|
impl Show for StandardFont with to_string(self) {
  match self {
    TimesRoman => "Times-Roman"
    TimesBold => "Times-Bold"
    TimesItalic => "Times-Italic"
    TimesBoldItalic => "Times-BoldItalic"
    Helvetica => "Helvetica"
    HelveticaBold => "Helvetica-Bold"
    HelveticaOblique => "Helvetica-Oblique"
    HelveticaBoldOblique => "Helvetica-BoldOblique"
    Courier => "Courier"
    CourierBold => "Courier-Bold"
    CourierOblique => "Courier-Oblique"
    CourierBoldOblique => "Courier-BoldOblique"
    Symbol => "Symbol"
    ZapfDingbats => "ZapfDingbats"
  }
}

///|
impl Show for StandardFont with output(self, logger) {
  logger.write_string(self.to_string())
}
