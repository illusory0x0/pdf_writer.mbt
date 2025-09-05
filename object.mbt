///|
fn write_pdf_string(s : Bytes, buf : @fmt.Memory, start : Int) -> Int {
  let mut offset = start
  offset += @fmt.Format::write(b"(", buf, offset)
  for x in s {
    match x {
      '(' | ')' | '\\' as c => {
        offset += @fmt.Format::write(b"\\", buf, offset)
        buf[offset] = c
        offset += 1
      }
      '\n' => offset += @fmt.Format::write(b"\\n", buf, offset)
      '\r' => offset += @fmt.Format::write(b"\\r", buf, offset)
      '\t' => offset += @fmt.Format::write(b"\\t", buf, offset)
      '\b' => offset += @fmt.Format::write(b"\\b", buf, offset)
      '\x0c' => offset += @fmt.Format::write(b"\\f", buf, offset)
      c => {
        buf[offset] = c
        offset += 1
      }
    }
  }
  offset += @fmt.Format::write(b")", buf, offset)
  offset - start
}

///|
fn write_pdf_name(n : Bytes, buf : @fmt.Memory, start : Int) -> Int {
  let mut offset = start
  if needs_processing(n) {
    if n == b"" || n[0] != '/' {
      println("warning: bad name")
      offset += @fmt.Format::write(b"/", buf, offset)
    } else {
      offset += @fmt.Format::write(b"/", buf, offset)
      offset += write_pdf_name_inner(n, buf, offset)
    }
  } else {
    offset += @fmt.Format::write(n, buf, offset)
  }
  offset - start
}

///|
fn hexbyte(x : Int) -> Byte {
  match x {
    0..=9 => Int::to_byte('0'.to_int() + x)
    10..=15 => Int::to_byte('A'.to_int() + (x - 10))
    _ => panic()
  }
}

///|
fn write_pdf_name_inner(n : @bytes.View, buf : @fmt.Memory, start : Int) -> Int {
  let mut offset = start
  for ch in n {
    match ch {
      '\x00' => {
        println("Warning: name \{n} contains the null character\n")
        offset += @fmt.Format::write(b"#00", buf, offset)
      }
      h if h < '\x21' || h > '\x7e' || is_delimiter(h) || h == '#' => {
        offset += @fmt.Format::write(b"#", buf, offset)
        buf[offset] = hexbyte(h.to_int() / 16)
        offset += 1
        buf[offset] = hexbyte(h.to_int() % 16)
        offset += 1
      }
      h => {
        buf[offset] = h
        offset += 1
      }
    }
  }
  offset - start
}

///|
fn needs_processing(s : Bytes) -> Bool {
  let l = s.length()
  if l < 2 {
    false
  } else {
    needs_processing_inner(s, 1, l)
  }
}

///|
fn needs_processing_inner(s : Bytes, p : Int, l : Int) -> Bool {
  p <= l - 1 &&
  (match s[p] {
    x if x < '\x21' || x > '\x7e' || is_delimiter(x) || x == '#' => true
    _ => needs_processing_inner(s, p + 1, l)
  })
}

///|
fn is_delimiter(x : Byte) -> Bool {
  match x {
    '(' | ')' | '<' | '>' | '[' | ']' | '{' | '}' | '/' | '%' => true
    _ => false
  }
}

///|
impl @fmt.Format for Object with write(
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
impl @fmt.Format for Object with count(value : Object) -> Int {
  match value {
    Stream(obj, stm) => @fmt.Format::count(obj) + stm.inner().length()
    Dictionary(entries) => {
      let mut total = 0
      for elem in entries {
        total += elem.0.length() * 2
        total += 1 // space
        total += @fmt.Format::count(elem.1)
        total += 2 // indent and newline
      }
      total + 4 // << \n and \n >>
    }
    Array(elts) => {
      let mut total = 0
      for elem in elts {
        total += @fmt.Format::count(elem)
        total += 1 // space
      }
      total
    }
    Name(bytes) => bytes.length() * 2
    String(bytes) => bytes.length() * 2
    Real(x) => @fmt.Format::count(x)
    Integer(x) => @fmt.Format::count(x)
    Boolean(_) => 5
    Null => 4
    Indirect(x) => @fmt.Format::count(x) + 5
  }
}
