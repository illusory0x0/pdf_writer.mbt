///|
pub impl ToJson for LexFile with to_json(self) {
  {
    "header": self.header,
    "body": self.body,
    "xref_table": self.xref_table,
    "trailer": @helper.ascii_string_of_bytesview(self.trailer),
    "start_xref_pos": self.start_xref_bytes_offset,
  }
}

///|
pub impl ToJson for LexHeader with to_json(self) {
  { "major": self.major, "minor": self.minor }
}

///|
pub impl ToJson for LexObj with to_json(self) {
  {
    "bytes_offset": self.start_bytes_offset,
    "object_num": self.object_num,
    "generation_num": self.generation_num,
    "obj_bytes": @helper.ascii_string_of_bytesview(self.obj_bytes),
  }
}

///|
pub impl ToJson for LexBody with to_json(self) {
  self.0.to_json()
}

///|
pub impl ToJson for LexXRefTable with to_json(self) {
  { "entries": self.entries, "start_num": self.start_num }
}

///|
pub impl ToJson for LexXRefEntry with to_json(self) {
  {
    "bytes_offset": self.bytes_offset,
    "generation_num": self.generation_num,
    "state": self.state,
  }
}

///|
pub impl ToJson for LexEntryState with to_json(self) {
  match self {
    InUse => "InUse"
    Free => "Free"
  }
}

///|
test "ToJson implementations" {
  let in_use : LexEntryState = InUse
  let free : LexEntryState = Free
  @json.inspect(in_use, content="InUse")
  @json.inspect(free, content="Free")
  let header : LexHeader = { major: 1, minor: 7 }
  @json.inspect(header, content={ "major": 1, "minor": 7 })
  let entry : LexXRefEntry = {
    bytes_offset: 123,
    generation_num: 0,
    state: InUse,
  }
  @json.inspect(entry, content={
    "bytes_offset": 123,
    "generation_num": 0,
    "state": "InUse",
  })
  let test_bytes = b"Hello PDF"
  let obj : LexObj = {
    start_bytes_offset: 100,
    object_num: 1,
    generation_num: 0,
    obj_bytes: test_bytes[:],
  }
  @json.inspect(obj, content={
    "bytes_offset": 100,
    "object_num": 1,
    "generation_num": 0,
    "obj_bytes": "Hello PDF",
  })
}

///|
pub impl[T : ToJson] ToJson for LexResult[T] with to_json(self) {
  {
    "value": self.value,
    "start_bytes_offset": self.start_bytes_offset,
    "end_bytes_offset": self.end_bytes_offset,
    "rest": @helper.ascii_string_of_bytesview(self.rest),
  }
}
