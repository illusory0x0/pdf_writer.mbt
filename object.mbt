///|
fn write_pdf_object(obj : Object, buf : @fmt.Memory, start : Int) -> Int {
  try {
    match obj {
      Null => @fmt.Format::write(b"null", buf, start)
      Boolean(true) => @fmt.Format::write(b"true", buf, start)
      Boolean(false) => @fmt.Format::write(b"false", buf, start)
      Integer(n) => @fmt.Format::write(n, buf, start)
      Real(r) => @fmt.Format::write(r, buf, start)
      String(s) => write_pdf_string(s, buf, start)
      Name(n) => write_pdf_name(n, buf, start)
      Array(elts) => {
        let mut offset = start
        match elts {
          [] => offset += @fmt.Format::write(b"[]", buf, offset)
          [x] => {
            offset += @fmt.Format::write(b"[", buf, offset)
            offset += write_pdf_object(x, buf, offset)
            offset += @fmt.Format::write(b"]", buf, offset)
          }
          [x, .. xs] => {
            offset += @fmt.Format::write(b"[", buf, offset)
            offset += write_pdf_object(x, buf, offset)
            for x in xs {
              offset += @fmt.Format::write(b" ", buf, offset)
              offset += write_pdf_object(x, buf, offset)
            }
            offset += @fmt.Format::write(b"]", buf, offset)
          }
        }
        offset - start
      }
      Dictionary(entries) => {
        let mut offset = start
        offset += @fmt.Format::write(b"<<\n", buf, offset)
        match entries {
          [] => ()
          [(k, v)] => {
            offset += @fmt.Format::write(b"  ", buf, offset)
            offset += @fmt.Format::write(k, buf, offset)
            offset += @fmt.Format::write(b" ", buf, offset)
            offset += write_pdf_object(v, buf, offset)
          }
          [(k, v), .. xs] => {
            offset += @fmt.Format::write(b"  ", buf, offset)
            offset += @fmt.Format::write(k, buf, offset)
            offset += @fmt.Format::write(b" ", buf, offset)
            offset += write_pdf_object(v, buf, offset)
            for x in xs {
              let (k, v) = x
              offset += @fmt.Format::write(b"  ", buf, offset)
              offset += @fmt.Format::write(b"\n  ", buf, offset)
              offset += @fmt.Format::write(k, buf, offset)
              offset += @fmt.Format::write(b" ", buf, offset)
              offset += write_pdf_object(v, buf, offset)
            }
          }
        }
        offset += @fmt.Format::write(b"\n>>", buf, offset)
        offset - start
      }
      Stream(dict, data) => {
        let mut offset = start
        offset += write_pdf_object(dict, buf, offset)
        offset += @fmt.Format::write(b"\nstream\n", buf, offset)
        offset += @fmt.Format::write(data.inner(), buf, offset)
        offset += @fmt.Format::write(b"\nendstream", buf, offset)
        offset - start
      }
      Indirect(n) => @fmt.format_write(b"{} 0 R", [n], buf, start)
    }
  } catch {
    _ => panic()
  }
}

///|
fn count_pdf_object(obj : Object) -> Int {
  match obj {
    Stream(obj, stm) => count_pdf_object(obj) + stm.inner().length()
    Dictionary(entries) => {
      let mut total = 0
      for elem in entries {
        total += elem.0.length() * 2
        total += 1 // space
        total += count_pdf_object(elem.1)
        total += 2 // indent and newline
      }
      total + 4 // << \n and \n >>
    }
    Array(elts) => {
      let mut total = 0
      for elem in elts {
        total += count_pdf_object(elem)
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
      offset += @fmt.Format::write(b"/"[:], buf, offset)
    } else {
      offset += @fmt.Format::write(b"/"[:], buf, offset)
      offset += write_pdf_name_inner(n, buf, offset)
    }
  } else {
    offset += @fmt.Format::write(n[:], buf, offset)
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
        offset += @fmt.Format::write(b"#"[:], buf, offset)
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
fn write_pdf_header(pdf : Pdf, buf : @fmt.Memory, start : Int) -> Int {
  try {
    let mut offset = start
    offset += @fmt.format_write(
      "%PDF-{}.{}\n",
      [pdf.major, pdf.minor],
      buf,
      offset,
    )
    offset += @fmt.format_write(
      "%{}\n",
      [@fmt.BigEndian(0x80818283)],
      buf,
      offset,
    )
    offset - start
  } catch {
    _ => panic()
  }
}

///|
fn count_pdf_header(pdf : Pdf) -> Int {
  10 + @fmt.Format::count(pdf.major) + @fmt.Format::count(pdf.minor) + 12
}

///|
fn write_pdf_obj(obj : Object, n : Int, buf : @fmt.Memory, start : Int) -> Int {
  try {
    let mut offset = start
    offset += @fmt.format_write("{} 0 obj\n", [n], buf, offset)
    offset += write_pdf_object(obj, buf, offset)
    offset += @fmt.Format::write(b"\nendobj\n"[:], buf, offset)
    offset - start
  } catch {
    _ => panic()
  }
}

///|
fn count_pdf_obj(obj : Object, n : Int) -> Int {
  @fmt.Format::count(n) + 7 + count_pdf_object(obj) + 7
}

///|
fn memcpy(
  dst : @fmt.Memory,
  dst_ofs : Int,
  src : @fmt.Memory,
  src_ofs : Int,
  len : Int,
) -> Int {
  for i in 0..<len {
    dst[dst_ofs + i] = src[src_ofs + i]
  }
  len
}

///|
fn fill(mem : @fmt.Memory, ofs : Int, len : Int, value : Byte) -> Unit {
  for i in 0..<len {
    mem[ofs + i] = value
  }
}

///|
fn write_pdf_xref(xref_offset : Int, buf : @fmt.Memory, start : Int) -> Int {
  let mut offset = start
  // offset += @fmt.Format::write(xref_offset, buf, offset)
  let n = @fmt.Format::write(xref_offset, buf, offset)
  let padding_len = 10 - n
  memcpy(buf, padding_len + offset, buf, offset, n) |> ignore
  fill(buf, offset, padding_len, '0')
  offset += 10
  offset += @fmt.Format::write(b" 00000 n \n", buf, offset)
  offset - start
}

///|
fn count_pdf_xref(xref_offset : Int) -> Int {
  10 + 7
}

///|
fn write_pdf_xrefs(
  xref_offsets : Array[Int],
  buf : @fmt.Memory,
  start : Int,
) -> Int {
  try {
    let mut offset = start
    offset += @fmt.Format::write(b"xref\n", buf, offset)
    offset += @fmt.format_write(
      b"0 {}\n",
      [xref_offsets.length() + 1],
      buf,
      offset,
    )
    offset += @fmt.Format::write(b"0000000000 65535 f \n"[:], buf, offset)
    for xref_offset in xref_offsets {
      offset += write_pdf_xref(xref_offset, buf, offset)
    }
    offset - start
  } catch {
    _ => panic()
  }
}

///|
fn count_pdf_xrefs(xref_offsets : Array[Int]) -> Int {
  5 + 10 + 20 + xref_offsets.length() * count_pdf_xref(0)
}

///|
fn write_pdf_trailer(
  trailer_dict : Object,
  buf : @fmt.Memory,
  start : Int,
) -> Int {
  let mut offset = start
  offset += @fmt.Format::write(b"trailer\n", buf, offset)
  offset += write_pdf_object(trailer_dict, buf, offset)
  offset += @fmt.Format::write(b"\n"[:], buf, offset)
  offset - start
}

///|
fn count_pdf_trailer(trailer_dict : Object) -> Int {
  8 + count_pdf_object(trailer_dict) + 1
}
