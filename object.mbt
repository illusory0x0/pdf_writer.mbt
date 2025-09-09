///|
/// 
/// escape sequences:
/// 
/// `\n`, `\r`, `\t`, `\b`, `\f`, `\\`, `\(`, `\)`, `\\`, 
/// 
/// `\ddd` ddd is octal number.
fn write_pdf_string(
  pdf_string : Bytes,
  buffer : @fmt.Memory,
  start : Int,
) -> Int {
  let mut offset = start
  offset += @fmt.Format::write(b"(", buffer, offset)
  for x in pdf_string {
    match x {
      '(' | ')' | '\\' as c => {
        offset += @fmt.Format::write(b"\\", buffer, offset)
        buffer[offset] = c
        offset += 1
      }
      '\n' => offset += @fmt.Format::write(b"\\n", buffer, offset)
      '\r' => offset += @fmt.Format::write(b"\\r", buffer, offset)
      '\t' => offset += @fmt.Format::write(b"\\t", buffer, offset)
      '\b' => offset += @fmt.Format::write(b"\\b", buffer, offset)
      '\x0c' => offset += @fmt.Format::write(b"\\f", buffer, offset)
      c => {
        // here we do not handle octal escape sequence for some non-printable ASCII characters
        buffer[offset] = c
        offset += 1
      }
    }
  }
  offset += @fmt.Format::write(b")", buffer, offset)
  offset - start
}

///|
fn write_pdf_name(pdf_name : Bytes, buffer : @fmt.Memory, start : Int) -> Int {
  let mut offset = start
  if needs_processing(pdf_name) {
    if pdf_name == b"" || pdf_name[0] != '/' {
      println("warning: bad name")
      offset += @fmt.Format::write(b"/", buffer, offset)
    } else {
      offset += @fmt.Format::write(b"/", buffer, offset)
      offset += write_pdf_name_inner(pdf_name, buffer, offset)
    }
  } else {
    offset += @fmt.Format::write(pdf_name, buffer, offset)
  }
  offset - start
}

///|
const HEX_DIGITS = b"0123456789ABCDEF"

///|
/// 
/// `#xx` where `xx` is the two-digit hexadecimal representation of the character's byte value.
fn write_pdf_name_inner(
  pdf_name : @bytes.View,
  buffer : @fmt.Memory,
  start : Int,
) -> Int {
  let mut offset = start
  for ch in pdf_name {
    match ch {
      '\x00' => {
        println("Warning: name \{pdf_name} contains the null character\n")
        offset += @fmt.Format::write(b"#00", buffer, offset)
      }
      // outside the range of ``!'' (0x21) to ``~'' (0x7E)
      // should be written in `#xx` notation
      //
      h if h < '\x21' || h > '\x7e' || is_delimiter(h) || h == '#' => {
        offset += @fmt.Format::write(b"#", buffer, offset)
        // write high nibble
        offset += @fmt.Format::write(
          HEX_DIGITS[h.to_int() / 16],
          buffer,
          offset,
        )
        // write low nibble
        offset += @fmt.Format::write(
          HEX_DIGITS[h.to_int() % 16],
          buffer,
          offset,
        )
      }
      h => {
        buffer[offset] = h
        offset += 1
      }
    }
  }
  offset - start
}

///|
fn needs_processing(pdf_name : Bytes) -> Bool {
  if pdf_name.length() < 2 {
    // b"/" is empty pdf object's name
    false
  } else {
    // ignore the leading '/'
    pdf_name[1:]
    .iter()
    .any(x => x < '\x21' || x > '\x7e' || is_delimiter(x) || x == '#')
  }
}

///|
fn is_delimiter(x : Byte) -> Bool {
  match x {
    '(' | ')' | '<' | '>' | '[' | ']' | '{' | '}' | '/' | '%' => true
    _ => false
  }
}

///|
pub impl @fmt.Format for Object with write(
  value : Object,
  buffer : @fmt.Memory,
  start : Int,
) -> Int {
  try {
    match value {
      Null => @fmt.Format::write(b"null", buffer, start)
      Boolean(true) => @fmt.Format::write(b"true", buffer, start)
      Boolean(false) => @fmt.Format::write(b"false", buffer, start)
      Integer(n) => @fmt.Format::write(n, buffer, start)
      Real(r) => @fmt.Format::write(r, buffer, start)
      String(s) => write_pdf_string(s, buffer, start)
      Name(n) => write_pdf_name(n, buffer, start)
      Array(elts) => {
        let mut offset = start
        match elts {
          [] => offset += @fmt.Format::write(b"[]", buffer, offset)
          [x] => {
            offset += @fmt.Format::write(b"[", buffer, offset)
            offset += @fmt.Format::write(x, buffer, offset)
            offset += @fmt.Format::write(b"]", buffer, offset)
          }
          [x, .. xs] => {
            offset += @fmt.Format::write(b"[", buffer, offset)
            offset += @fmt.Format::write(x, buffer, offset)
            for x in xs {
              offset += @fmt.Format::write(b" ", buffer, offset)
              offset += @fmt.Format::write(x, buffer, offset)
            }
            offset += @fmt.Format::write(b"]", buffer, offset)
          }
        }
        offset - start
      }
      Dictionary(entries) => {
        let mut offset = start
        offset += @fmt.Format::write(b"<<\n", buffer, offset)
        match entries {
          [] => ()
          [(key, value)] => {
            offset += @fmt.Format::write(b"  ", buffer, offset)
            offset += @fmt.Format::write(key, buffer, offset)
            offset += @fmt.Format::write(b" ", buffer, offset)
            offset += @fmt.Format::write(value, buffer, offset)
          }
          [(key, value), .. xs] => {
            offset += @fmt.Format::write(b"  ", buffer, offset)
            offset += @fmt.Format::write(key, buffer, offset)
            offset += @fmt.Format::write(b" ", buffer, offset)
            offset += @fmt.Format::write(value, buffer, offset)
            for x in xs {
              let (key, value) = x
              offset += @fmt.Format::write(b"  ", buffer, offset)
              offset += @fmt.Format::write(b"\n  ", buffer, offset)
              offset += @fmt.Format::write(key, buffer, offset)
              offset += @fmt.Format::write(b" ", buffer, offset)
              offset += @fmt.Format::write(value, buffer, offset)
            }
          }
        }
        offset += @fmt.Format::write(b"\n>>", buffer, offset)
        offset - start
      }
      Stream(dict, data) => {
        let mut offset = start
        offset += @fmt.Format::write(dict, buffer, offset)
        offset += @fmt.Format::write(b"\nstream\n", buffer, offset)
        offset += @fmt.Format::write(data.inner(), buffer, offset)
        offset += @fmt.Format::write(b"\nendstream", buffer, offset)
        offset - start
      }
      Indirect(n) => @fmt.format_write(b"{} 0 R", [n], buffer, start)
    }
  } catch {
    _ => panic()
  }
}

///|
pub impl @fmt.Format for Object with count(value : Object) -> Int {
  match value {
    Null => 4 // "null"
    Boolean(true) => 4 // "true"
    Boolean(false) => 5 // "false"
    Integer(n) => @fmt.Format::count(n)
    Real(r) => @fmt.Format::count(r)
    String(s) => s.length() * 2 + 2 // simplified as requested: multiply by 2 + parentheses
    Name(n) => n.length() * 2 // simplified as requested: multiply by 2
    Array(elts) =>
      match elts {
        [] => 2 // "[]"
        [x] => 2 + @fmt.Format::count(x) // "[" + element + "]"
        _ => {
          // "[" + first_element + (" " + element)* + "]"
          let content_count = elts.fold(init=0, (acc, x) => acc +
            @fmt.Format::count(x))
          let spaces_count = elts.length() - 1 // spaces between elements
          2 + content_count + spaces_count
        }
      }
    Dictionary(entries) =>
      match entries {
        [] => 6 // "<<\n\n>>"
        [(key, value)] =>
          // "<<\n  " + key + " " + value + "\n>>"
          6 + 2 + key.length() * 2 + 1 + @fmt.Format::count(value)
        [(key, value), .. xs] => {
          // "<<\n  " + first_entry + ("\n  " + key + " " + value)* + "\n>>"
          let mut total = 6 +
            2 +
            key.length() * 2 +
            1 +
            @fmt.Format::count(value)
          for x in xs {
            let (k, v) = x
            total += 4 + k.length() * 2 + 1 + @fmt.Format::count(v) // "\n  " + key + " " + value
          }
          total
        }
      }
    Stream(dict, data) =>
      // dict + "\nstream\n" + data + "\nendstream"
      @fmt.Format::count(dict) + 9 + data.inner().length() + 10
    Indirect(n) => @fmt.Format::count(n) + 4 // number + " 0 R"
  }
}
