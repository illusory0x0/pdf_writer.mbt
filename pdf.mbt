///|
impl @fmt.Format for Pdf with write(
  value : Pdf,
  buffer : @fmt.Memory,
  start : Int,
) -> Int {
  try {
    let mut offset = start
    offset += write_pdf_header(value, buffer, offset)
    let xref_offsets = []
    for n, obj in value.objects.iter2() {
      let xref_offset = write_pdf_obj(obj, n + 1, buffer, offset)
      xref_offsets.push(xref_offset)
      offset += xref_offset
    }
    offset += write_pdf_xrefs(xref_offsets, buffer, offset)
    offset += write_pdf_trailer(value.trailer, buffer, offset)
    offset += @fmt.Format::write(b"startxref\n", buffer, offset)
    offset += @fmt.format_write(b"{}\n%%EOF\n", [offset], buffer, offset)
    offset - start
  } catch {
    _ => panic()
  }
}

///|
impl @fmt.Format for Pdf with count(value : Pdf) -> Int {
  let mut total = 0
  total += count_pdf_header(value)
  for n, obj in value.objects.iter2() {
    total += count_pdf_obj(obj, n + 1)
  }
  let xref_offsets = []
  for n, obj in value.objects.iter2() {
    let xref_offset = count_pdf_obj(obj, n + 1)
    xref_offsets.push(xref_offset)
  }
  total += count_pdf_xrefs(xref_offsets)
  total += count_pdf_trailer(value.trailer)
  total += 20 // startxref and %%EOF
  total
}
