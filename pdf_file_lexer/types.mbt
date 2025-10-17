///|
pub(all) struct File {
  header : Header
  body : Body
  xref_table : XRefTable
  trailer : BytesView
  start_xref_pos : Int
} derive(Eq, Show)

///|
pub(all) struct Header {
  major : Int
  minor : Int
} derive(Eq, Show)

///|
pub(all) struct Obj {
  /// 0-based position in the file
  /// this is used to validate xref table entries
  start_bytes_offset : Int
  object_num : Int
  generation_num : Int
  obj_bytes : BytesView
} derive(Eq, Show)

///|
pub(all) struct Body(Array[Obj]) derive(Eq, Show)

///|
pub(all) struct XRefTable {
  entries : Array[XRefEntry]
  start_num : Int
} derive(Eq, Show)

///|
pub(all) struct XRefEntry {
  bytes_offset : Int
  /// most of cases is 0
  generation_num : Int
  state : EntryState
} derive(Eq, Show)

///|
pub(all) enum EntryState {
  InUse
  Free
} derive(Eq, Show)
