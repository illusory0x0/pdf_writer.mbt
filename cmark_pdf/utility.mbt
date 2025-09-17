///|
fn bytes_of_string(s : String) -> Bytes {
  let len = s.length()
  let buf = FixedArray::make(len, b'\x00')
  for i in 0..<len {
    let code_unit = s[i]
    if Char::is_ascii(code_unit.unsafe_to_char()) {
      buf[i] = code_unit.to_byte()
    } else {
      buf[i] = b'?'
    }
  }
  buf.unsafe_reinterpret_as_bytes()
}
