///|
fn string_of_memory(mem : @fmt.Memory, len : Int) -> String {
  let buf = StringBuilder::new(size_hint=len)
  for i in 0..<len {
    buf.write_char(mem[i].to_char())
  }
  buf.to_string()
}

///|
fn bytes_of_memory(mem : @fmt.Memory, len : Int) -> Bytes {
  Bytes::makei(len, i => mem[i])
}
