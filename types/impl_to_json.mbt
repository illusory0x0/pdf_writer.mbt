///|
/// ToJson pub implementation for GraphicOperator
pub impl ToJson for GraphicOperator with to_json(self) {
  match self {
    Op_w(width) => { "op": "w", "width": width }
    Op_J(cap) => { "op": "J", "cap": cap }
    Op_j(join) => { "op": "j", "join": join }
    Op_M(limit) => { "op": "M", "limit": limit }
    Op_d(pattern, phase) => { "op": "d", "pattern": pattern, "phase": phase }
    Op_ri(intent) =>
      { "op": "ri", "intent": @helper.ascii_string_of_bytesview(intent[:]) }
    Op_i(flatness) => { "op": "i", "flatness": flatness }
    Op_gs(name) =>
      { "op": "gs", "name": @helper.ascii_string_of_bytesview(name[:]) }
    Op_q => { "op": "q" }
    Op_Q => { "op": "Q" }
    Op_cm(matrix) => { "op": "cm", "matrix": matrix }
    Op_m(x, y) => { "op": "m", "x": x, "y": y }
    Op_l(x, y) => { "op": "l", "x": x, "y": y }
    Op_c(x1, y1, x2, y2, x3, y3) =>
      { "op": "c", "x1": x1, "y1": y1, "x2": x2, "y2": y2, "x3": x3, "y3": y3 }
    Op_v(x2, y2, x3, y3) =>
      { "op": "v", "x2": x2, "y2": y2, "x3": x3, "y3": y3 }
    Op_y(x1, y1, x3, y3) =>
      { "op": "y", "x1": x1, "y1": y1, "x3": x3, "y3": y3 }
    Op_h => { "op": "h" }
    Op_re(x, y, width, height) =>
      { "op": "re", "x": x, "y": y, "width": width, "height": height }
    Op_S => { "op": "S" }
    Op_s => { "op": "s" }
    Op_f => { "op": "f" }
    Op_F => { "op": "F" }
    Op_f_star => { "op": "f*" }
    Op_B => { "op": "B" }
    Op_B_star => { "op": "B*" }
    Op_b => { "op": "b" }
    Op_b_star => { "op": "b*" }
    Op_n => { "op": "n" }
    Op_W => { "op": "W" }
    Op_W_star => { "op": "W*" }
    Op_BT => { "op": "BT" }
    Op_ET => { "op": "ET" }
    Op_Tc(spacing) => { "op": "Tc", "spacing": spacing }
    Op_Tw(spacing) => { "op": "Tw", "spacing": spacing }
    Op_Tz(scale) => { "op": "Tz", "scale": scale }
    Op_TL(leading) => { "op": "TL", "leading": leading }
    Op_Tf(font, size) =>
      {
        "op": "Tf",
        "font": @helper.ascii_string_of_bytesview(font[:]),
        "size": size,
      }
    Op_Tr(mode) => { "op": "Tr", "mode": mode }
    Op_Ts(rise) => { "op": "Ts", "rise": rise }
    Op_Td(x, y) => { "op": "Td", "x": x, "y": y }
    Op_TD(x, y) => { "op": "TD", "x": x, "y": y }
    Op_Tm(matrix) => { "op": "Tm", "matrix": matrix }
    Op_T_star => { "op": "T*" }
    Op_Tj(text) =>
      { "op": "Tj", "text": @helper.ascii_string_of_bytesview(text[:]) }
    Op_TJ(array) => { "op": "TJ", "array": array }
    Op_single_quote(text) =>
      { "op": "'", "text": @helper.ascii_string_of_bytesview(text[:]) }
    Op_double_quote(w, c, text) =>
      {
        "op": "\"",
        "word_spacing": w,
        "char_spacing": c,
        "text": @helper.ascii_string_of_bytesview(text[:]),
      }
    Op_d0(x, y) => { "op": "d0", "x": x, "y": y }
    Op_d1(x, y, llx, lly, urx, ury) =>
      {
        "op": "d1",
        "x": x,
        "y": y,
        "llx": llx,
        "lly": lly,
        "urx": urx,
        "ury": ury,
      }
    Op_CS(name) =>
      { "op": "CS", "name": @helper.ascii_string_of_bytesview(name[:]) }
    Op_cs(name) =>
      { "op": "cs", "name": @helper.ascii_string_of_bytesview(name[:]) }
    Op_SC(values) => { "op": "SC", "values": values }
    Op_sc(values) => { "op": "sc", "values": values }
    Op_SCN(values) => { "op": "SCN", "values": values }
    Op_scn(values) => { "op": "scn", "values": values }
    Op_SCNName(name, values) =>
      {
        "op": "SCN",
        "name": @helper.ascii_string_of_bytesview(name[:]),
        "values": values,
      }
    Op_scnName(name, values) =>
      {
        "op": "scn",
        "name": @helper.ascii_string_of_bytesview(name[:]),
        "values": values,
      }
    Op_G(gray) => { "op": "G", "gray": gray }
    Op_g(gray) => { "op": "g", "gray": gray }
    Op_RG(r, g, b) => { "op": "RG", "r": r, "g": g, "b": b }
    Op_rg(r, g, b) => { "op": "rg", "r": r, "g": g, "b": b }
    Op_K(c, m, y, k) => { "op": "K", "c": c, "m": m, "y": y, "k": k }
    Op_k(c, m, y, k) => { "op": "k", "c": c, "m": m, "y": y, "k": k }
    Op_sh(name) =>
      { "op": "sh", "name": @helper.ascii_string_of_bytesview(name[:]) }
    InlineImage(dict, data) =>
      {
        "op": "BI/ID/EI",
        "dict": dict,
        "data": @helper.ascii_string_of_bytesview(data[:]),
      }
    Op_Do(name) =>
      { "op": "Do", "name": @helper.ascii_string_of_bytesview(name[:]) }
    Op_MP(tag) =>
      { "op": "MP", "tag": @helper.ascii_string_of_bytesview(tag[:]) }
    Op_DP(tag, properties) =>
      {
        "op": "DP",
        "tag": @helper.ascii_string_of_bytesview(tag[:]),
        "properties": properties,
      }
    Op_BMC(tag) =>
      { "op": "BMC", "tag": @helper.ascii_string_of_bytesview(tag[:]) }
    Op_BDC(tag, properties) =>
      {
        "op": "BDC",
        "tag": @helper.ascii_string_of_bytesview(tag[:]),
        "properties": properties,
      }
    Op_EMC => { "op": "EMC" }
    Op_BX => { "op": "BX" }
    OP_EX => { "op": "EX" }
    Op_Unknown(data) =>
      { "op": "Unknown", "data": @helper.ascii_string_of_bytesview(data[:]) }
    Op_Comment(text) =>
      { "op": "Comment", "text": @helper.ascii_string_of_bytesview(text[:]) }
  }
}

///|
/// ToJson pub implementation for File
pub impl ToJson for File with to_json(self) {
  {
    "major": self.major,
    "minor": self.minor,
    "objects": self.objects,
    "trailer": self.trailer,
  }
}

///|
/// ToJson pub implementation for TransformMatrix
pub impl ToJson for TransformMatrix with to_json(self) {
  {
    "a": self.a,
    "b": self.b,
    "c": self.c,
    "d": self.d,
    "e": self.e,
    "f": self.f,
  }
}

///|
/// ToJson pub implementation for ContentStream
pub impl ToJson for ContentStream with to_json(self) {
  { "operators": self.0 }
}

///|
/// ToJson pub implementation for StandardFont
pub impl ToJson for StandardFont with to_json(self) {
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
