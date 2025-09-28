///|
/// C language style escaped sequence spec.
/// 
/// Warning: this escaped function not equal to PDF literal string escaped sequence.
///
/// This function is intended to be used in debugging, logging, etc.
///
pub fn ascii_string_of_bytes(bytes : Bytes) -> String {
  let buffer = StringBuilder::new(size_hint=bytes.length() * 2)
  for b in bytes {
    // if b is non printable, please escape it
    match b {
      '\\' => buffer.write_string("\\\\")
      '\n' => buffer.write_string("\\n")
      '\r' => buffer.write_string("\\r")
      '\t' => buffer.write_string("\\t")
      '\b' => buffer.write_string("\\b")
      '\x0c' => buffer.write_string("\\f") // form feed
      c if c.to_int() < 32 || c.to_int() > 126 => {
        // Non-printable ASCII: use octal escape sequence
        let code = c.to_int()
        buffer.write_string("\\")
        buffer.write_string((code / 64).to_string())
        buffer.write_string((code % 64 / 8).to_string())
        buffer.write_string((code % 8).to_string())
      }
      c => buffer.write_char(c.to_char())
    }
  }
  buffer.to_string()
}
