///|
impl @fmt.Format for Content with write(self, buf, start) {
  let xs = self.0
  let mut offset = start
  for x in xs {
    offset += @fmt.Format::write(x, buf, offset)
  }
  offset - start
}

///|
impl @fmt.Format for Content with count(xs) {
  xs.0.fold(init=0, (acc, x) => @fmt.Format::count(x) + acc)
}

///|
fn Content::to_stream(self : Self) -> @pdf.Stream {
  let buffer = @fmt.Memory::make(@fmt.Format::count(self), 0)
  let offset = @fmt.Format::write(self, buffer, 0)
  let bytes = bytes_of_memory(buffer, offset)
  bytes
}

///|
fn Content::to_stream_object(self : Self) -> @pdf.Object {
  let stream = self.to_stream()
  let len = stream.0.length()
  @pdf.Object::Stream(Dictionary([("/Length", Integer(len))]), stream)
}
