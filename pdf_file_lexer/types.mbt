///|
pub(all) struct File {
  header : Header
  body : Body
  /// FIXME: support multiple xref tables
  /// 
  /// in the `ISO 32000-2:2020 (PDF 2.0)`, section 7.5.8.3 and 7.5.8.4,
  ///
  /// it explains PDF has three kinds of xref table:
  ///
  /// - standard cross-reference table:
  ///
  ///   syntax: xref...trailer
  ///
  /// - cross-reference stream:
  ///
  ///   syntax: <<\Type \XRef...>> stream... endstream endobj,
  ///   stream data is three fields specified field bytes length by `/W` array of integers.
  ///
  /// - hybrid cross-reference table:
  /// 
  ///   syntax: xref<empty>trailer <<\XRefStm _ ...>>,
  ///   1. `/XRefStm` specifies the byte offset of cross-reference stream object,
  ///   2. standard cross-reference table is empty.
  /// 
  /// the compatibility design:
  /// *new* PDF writer generates the PDF file, the *old* PDF reader can read the *original* content but cannot read the *modified* content.
  /// *new* PDF reader can read the *modified* content, first this readers should handle the `/XRefStm` entry, then read the `/Prev` entry in the main standard cross-reference table.
  /// *old* PDF writer cannot modify the *new* PDF writer generated PDF file, because the *old* PDF writer ignore the `/XRefStm` entry any modification is *non-sense*.
  ///
  xref_table : XRefTable
  trailer : BytesView
  start_xref_bytes_offset : Int
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
struct Body(FixedArray[Obj]) derive(Eq, Show)

///|
pub fn Body::length(self : Body) -> Int = "%fixedarray.length"

///|
pub fn Body::op_get(self : Body, index : Int) -> Obj = "%fixedarray.get"

///|
pub fn Body::from(array : Array[Obj]) -> Body {
  Body(FixedArray::from_array(array))
}

///|
pub fn Body::iter(self : Body) -> Iter[Obj] {
  FixedArray::iter(self.0)
}

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
