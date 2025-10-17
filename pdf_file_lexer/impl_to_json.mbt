///|
pub impl ToJson for File with to_json(self) {
  {
    "header": self.header,
    "body": self.body,
    "xref_table": self.xref_table,
    "trailer": @helper.ascii_string_of_bytesview(self.trailer),
    "start_xref_pos": self.start_xref_pos,
  }
}

///|
pub impl ToJson for Header with to_json(self) {
  { "major": self.major, "minor": self.minor }
}

///|
pub impl ToJson for Obj with to_json(self) {
  {
    "bytes_offset": self.bytes_offset,
    "object_num": self.object_num,
    "generation_num": self.generation_num,
    "obj_bytes": @helper.ascii_string_of_bytesview(self.obj_bytes),
  }
}

///|
pub impl ToJson for Body with to_json(self) {
  self.0.to_json()
}

///|
pub impl ToJson for XRefTable with to_json(self) {
  { "entries": self.entries, "start_num": self.start_num }
}

///|
pub impl ToJson for XRefEntry with to_json(self) {
  {
    "bytes_offset": self.bytes_offset,
    "generation_num": self.generation_num,
    "state": self.state,
  }
}

///|
pub impl ToJson for EntryState with to_json(self) {
  match self {
    InUse => "InUse"
    Free => "Free"
  }
}

///|
test "ToJson implementations" {
  let in_use : EntryState = InUse
  let free : EntryState = Free
  @json.inspect(in_use, content="InUse")
  @json.inspect(free, content="Free")
  let header : Header = { major: 1, minor: 7 }
  @json.inspect(header, content={ "major": 1, "minor": 7 })
  let entry : XRefEntry = { bytes_offset: 123, generation_num: 0, state: InUse }
  @json.inspect(entry, content={
    "bytes_offset": 123,
    "generation_num": 0,
    "state": "InUse",
  })
  let test_bytes = b"Hello PDF"
  let obj : Obj = {
    bytes_offset: 100,
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
    "bytes_offset": self.bytes_offset,
    "rest": @helper.ascii_string_of_bytesview(self.rest),
  }
}

///|
test "LexResult ToJson implementation" {
  let test_bytes = b"remaining data"
  let lex_result : LexResult[Int] = {
    value: 42,
    bytes_offset: 100,
    rest: test_bytes[:],
  }
  @json.inspect(lex_result, content={
    "value": 42,
    "bytes_offset": 100,
    "rest": "remaining data",
  })
  let header : Header = { major: 1, minor: 7 }
  let lex_result_header : LexResult[Header] = {
    value: header,
    bytes_offset: 200,
    rest: b"more data"[:],
  }
  @json.inspect(lex_result_header, content={
    "value": { "major": 1, "minor": 7 },
    "bytes_offset": 200,
    "rest": "more data",
  })
}
