///|
pub(all) struct Stream(Bytes)

///|
/// pdf object 
pub(all) enum Object {
  /// `null` keyword
  Null
  /// `true` or `false` keyword
  Boolean(Bool)
  Integer(Int)
  Real(Double)
  /// PDF string can be represented in two ways:
  /// - `Literal string`: enclosed in parentheses `(...)`
  /// - `Hexadecimal string`: enclosed in angle brackets `<...>`
  ///
  /// those reprentations are for parsing.
  /// here all encoded as bytes sequence.
  ///
  String(Bytes)
  /// although SOLIDUS `/` is not considered as part of the name in PDF spec,
  /// But here we include it as part of the name.
  Name(Bytes)
  /// PDF array object is surrounded by square brackets, separated by whitespace.
  /// `[a b c ...]` 
  Array(Array[Object])
  /// PDF dictionary object is surrounded by double angle brackets.
  /// `<< /Key1 Value1 /Key2 Value2 ... >>`
  /// keys are PDF names, values are PDF objects.
  Dictionary(Array[(Bytes, Object)])
  /// PDF stream object is a sequence of binary bytes.
  /// 
  /// `
  /// <dictionary>
  /// stream
  /// ...
  /// endstream
  /// `
  ///
  /// dictionary: 
  ///
  /// - `/Length <n>` is **required**, where `<n>` is the length of the stream in bytes.
  ///
  /// - `/Filter <name|array>` is **optional**, if present, the stream data is encoded.
  ///
  /// - `/DecodeParms <dictionary|array>` is **optional**, if present, it specifies the parameters for the filters.
  ///
  /// other entries are optional and not listed here.
  ///
  Stream(Object, Stream)
  /// it should be positive integer, by default with 0 integer generation number
  ///
  /// `<n> <m> R`
  ///
  /// <n> is indirect object number
  /// <m> is generation number, by default 0
  ///
  /// indirect object definition:
  /// `
  /// <n> <m> obj
  /// ...
  /// endobj
  /// `
  Indirect(Int)
}

///|
/// 
/// [PDF – Graphic Operators – Cheat Sheet](https://pdfa.org/wp-content/uploads/2023/08/PDF-Operators-CheatSheet.pdf)
/// 
pub(all) enum GraphicOperator {
  // set line width
  Op_w(Double)
  // set line cap
  Op_J(Int)
  // set line join 
  Op_j(Int)
  // set miter limit
  Op_M(Double)
  // set dash pattern
  Op_d(Array[Double], Double)
  // set rendering intent 
  Op_ri(Bytes)
  // set flatness
  Op_i(Double)
  // set graphics state from dictionary 
  Op_gs(Bytes)
  // save graphics state to stack 
  Op_q
  // restore graphics state from stack 
  Op_Q
  // modify CTM by concatenation 
  Op_cm(TransformMatrix)
  // begin a new subpath 
  Op_m(Double, Double)
  // append a straight segment 
  Op_l(Double, Double)
  // cubic bezier 
  Op_c(Double, Double, Double, Double, Double, Double)
  // cubic bezier 
  Op_v(Double, Double, Double, Double)
  // cubic bezier  
  Op_y(Double, Double, Double, Double)
  // close subpath  
  Op_h
  // append rectangle 
  Op_re(Double, Double, Double, Double)
  // stroke a path 
  Op_S
  // close and stroke path 
  Op_s
  // fill path, non-zero 
  Op_f
  // fill path, non-zero 
  Op_F
  // f* operator. fill path, even-odd 
  Op_f_star
  // fill and stroke path, non-zero 
  Op_B
  // B* operator. fill and stroke path, even-odd
  Op_B_star
  // close fill and stroke, non-zero 
  Op_b
  // b* operator. close fill and stroke, even-odd 
  Op_b_star
  // path no-op
  Op_n
  // clipping path, even-odd
  Op_W
  // clipping path, non-zero 
  Op_W_star
  // begin a text object 
  Op_BT
  // end a text object 
  Op_ET
  // set character spacing 
  Op_Tc(Double)
  // set word spacing 
  Op_Tw(Double)
  // set horizontal scaling 
  Op_Tz(Double)
  // set leading 
  Op_TL(Double)
  // set font size 
  Op_Tf(Bytes, Double)
  // set text rendering mode 
  Op_Tr(Int)
  // set text rise 
  Op_Ts(Double)
  // move to next line, with `x` and `y` offset. 
  Op_Td(Double, Double)
  // ditto, but set leading 
  Op_TD(Double, Double)
  // set text and line matrices 
  Op_Tm(TransformMatrix)
  // T* operator. move text to the next line 
  Op_T_star
  // show text string 
  Op_Tj(Bytes)
  // show text string 
  Op_TJ(Object)
  // move to next line and show text 
  Op_single_quote(Bytes)
  // ditto, extra parameters 
  Op_double_quote(Double, Double, Bytes)
  // set glyph width info 
  Op_d0(Double, Double)
  // set glyph width info 
  Op_d1(Double, Double, Double, Double, Double, Double)
  // set color space 
  Op_CS(Bytes)
  // set color space for nonstroking operations 
  Op_cs(Bytes)
  // set color in current color space 
  Op_SC(Array[Double])
  // set color in current color space for nonstroking operations 
  Op_sc(Array[Double])
  // set color in current color space 
  Op_SCN(Array[Double])
  // set color in current color space for nonstroking operations 
  Op_scn(Array[Double])
  // set color in current color space with name 
  Op_SCNName(Bytes, Array[Double])
  //  set color in current color space for nonstroking operations with name 
  Op_scnName(Bytes, Array[Double])
  // set gray 
  Op_G(Double)
  // set gray nonstroking 
  Op_g(Double)
  // set stroking color 
  Op_RG(Double, Double, Double)
  // set painting color 
  Op_rg(Double, Double, Double)
  // set CMYK stroking 
  Op_K(Double, Double, Double, Double)
  // set CMYK nonstroking 
  Op_k(Double, Double, Double, Double)
  // shading pattern 
  Op_sh(Bytes)
  // inline image dictionary, previous decodeparams if any, data 
  InlineImage(Object, Object?, FixedArray[Byte])
  // introduce an XObject 
  Op_Do(Bytes)
  // marked content point 
  Op_MP(Bytes)
  // property list 
  Op_DP(Bytes, Object)
  // begin marked content sequence 
  Op_BMC(Bytes)
  // property list 
  Op_BDC(Bytes, Object)
  // end of marked content sequence
  Op_EMC
  // start compatibility mode 
  Op_BX
  // end compatibility mode 
  OP_EX
  // unknown operand / operator sequence 
  Op_Unknown(Bytes)
  // comments are silently ignored when reading, but can be written for debug 
  Op_Comment(Bytes)
}

///|
pub(all) struct File {
  major : Int
  minor : Int
  objects : Array[Object]
  trailer : Object
}

///|
///  
pub(all) struct TransformMatrix {
  a : Double
  b : Double
  c : Double
  d : Double
  e : Double
  f : Double
}
