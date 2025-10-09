///|
suberror LexError String derive(Show)

///|
pub(all) struct LexResult[T] {
  value : T
  bytes_offset : Int
  rest : BytesView
} derive(Show)

///|
pub fn tokenize_header(input : BytesView) -> LexResult[Header] raise LexError {
  lexmatch input {
    ("%PDF-" ("\d+" as major) "." ("\d+" as minor) "(\r\n)|\r|\n") as all, rest => {
      let major = try! @lexer_bytes.tokenize_int(major)
      let minor = try! @lexer_bytes.tokenize_int(minor)
      LexResult::{
        value: Header::{ major, minor },
        bytes_offset: all.length(),
        rest,
      }
    }
    _ => raise LexError("invalid PDF header")
  }
}

///|
pub fn tokenize_body(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[Body] {
  let mut bytes_offset = start_bytes_offset
  let mut rest = input
  let body = []
  for {
    lexmatch rest {
      // TODO: CRITICAL - Replace ".*" pattern! This will match EVERYTHING until "endobj"
      // including binary data, other PDF structures, or entire file if "endobj" missing.
      // Security risk: memory exhaustion, parser confusion. Use proper PDF object parsing.
      (
        ("\d+" as obj_num)
        "[ ]+"
        ("\d+" as gen_num)
        "[ ]+"
        "obj"
        "(\r\n)|\r|\n"
        (".*" as obj_bytes)
        "endobj"
        "(\r\n)|\r|\n"
      ) as all, r => {
        let object_num = try! @lexer_bytes.tokenize_int(obj_num)
        let generation_num = try! @lexer_bytes.tokenize_int(gen_num)
        bytes_offset += all.length()
        let obj = Obj::{ bytes_offset, object_num, generation_num, obj_bytes }
        rest = r
        body.push(obj)
      }
      "(\r\n)|\r|\n" as all, r => {
        bytes_offset += all.length()
        rest = r
      }
      _ => break
    }
  }
  LexResult::{ value: body, bytes_offset, rest }
}

///|
/// Handle two character end-of-line sequences per PDF specification:
/// SP CR, SP LF, or CR LF
/// 
/// Also accepts single character sequences (\n, \r) for backward compatibility.
/// This not equals to end-of-line marker in PDF spec.
pub fn tokenize_xref_entry(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[XRefEntry] raise LexError {
  lexmatch input {
    (
      ("\d+" as offset_str)
      " "
      ("\d+" as gen_str)
      " "
      "n"
      "[ ]*"
      "( \r)|( \n)|(\r\n)|\n|\r"
    ) as all, rest => {
      let bytes_offset = try! @lexer_bytes.tokenize_int(offset_str)
      let generation_num = try! @lexer_bytes.tokenize_int(gen_str)
      let state = EntryState::InUse
      LexResult::{
        value: XRefEntry::{ bytes_offset, generation_num, state },
        bytes_offset: start_bytes_offset + all.length(),
        rest,
      }
    }
    (
      ("\d+" as offset_str)
      " "
      ("\d+" as gen_str)
      " "
      "f"
      "[ ]*"
      "( \r)|( \n)|(\r\n)|\n|\r"
    ) as all, rest => {
      let bytes_offset = try! @lexer_bytes.tokenize_int(offset_str)
      let generation_num = try! @lexer_bytes.tokenize_int(gen_str)
      let state = EntryState::Free
      LexResult::{
        value: XRefEntry::{ bytes_offset, generation_num, state },
        bytes_offset: start_bytes_offset + all.length(),
        rest,
      }
    }
    _ =>
      raise LexError(
        "Invalid xref entry format in \{start_bytes_offset}, \{try! @encoding/utf8.decode(input)}",
      )
  }
}

///|
pub fn tokenize_xref_table(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[XRefTable] raise LexError {
  lexmatch input {
    (
      "xref"
      "(\r\n)|\r|\n"
      ("\d+" as start_num_str)
      " "
      ("\d+" as count_str)
      "(\r\n)|\r|\n"
    ) as header, rest => {
      let start_num = try! @lexer_bytes.tokenize_int(start_num_str)
      let count = try! @lexer_bytes.tokenize_int(count_str)
      let mut current_rest = rest
      let mut current_offset = start_bytes_offset + header.length()
      let entries = []
      for i = 0; i < count; i = i + 1 {
        let entry_result = tokenize_xref_entry(current_rest, current_offset)
        entries.push(entry_result.value)
        current_rest = entry_result.rest
        current_offset = entry_result.bytes_offset
      }
      LexResult::{
        value: XRefTable::{ entries, start_num },
        bytes_offset: current_offset,
        rest: current_rest,
      }
    }
    _ => raise LexError("Invalid xref table format in \{start_bytes_offset}")
  }
}

///|
pub fn tokenize_trailer(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[BytesView] raise LexError {
  lexmatch input {
    // TODO: CRITICAL - "[^s]*" pattern is problematic! Matches any chars except 's',
    // stops at first 's' rather than proper "startxref". Could match across PDF structures.
    // Use proper PDF dictionary syntax: "<<[^>]*>>" or implement full dictionary parser.
    ("trailer" "(\r\n)|\r|\n" ("[^s]*" as trailer_dict) "(\r\n)|\r|\n") as all, rest =>
      LexResult::{
        value: trailer_dict,
        bytes_offset: start_bytes_offset + all.length(),
        rest,
      }
    _ => raise LexError("Invalid trailer format")
  }
}

///|
pub fn tokenize_startxref(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[Int] raise LexError {
  lexmatch input {
    ("startxref" "(\r\n)|\r|\n" ("\d+" as offset_str) "(\r\n)|\r|\n" "%%EOF") as all, rest => {
      let xref_offset = try! @lexer_bytes.tokenize_int(offset_str)
      LexResult::{
        value: xref_offset,
        bytes_offset: start_bytes_offset + all.length(),
        rest,
      }
    }
    _ => raise LexError("Invalid startxref format")
  }
}

///|
/// return advance offset
pub fn skip_comment(input : BytesView) -> Int {
  lexmatch input {
    // PDF Comments (% until end of line, including the end-of-line marker)  
    // Handles all three PDF end-of-line markers: \r\n, \r, \n
    // TODO: Add length limit to prevent DoS - use "%[^\r\n]{0,1024}(\r\n|\r|\n)"
    "%[^\r\n]*(\r\n|\r|\n)" as comment, _rest => comment.length()

    // PDF Comments at end of file (% until end of input without end-of-line)
    // This pattern handles comments at EOF WITHOUT trailing newlines
    // Example: "1 0 obj % comment" (comment at end with no newline)
    // TODO: CRITICAL - This pattern matches to END OF FILE! Could consume entire input.
    // Add length limit: "%[^\r\n]{0,1024}$" to prevent DoS attacks.
    "%[^\r\n]*$" as comment, _rest => comment.length()

    // If input doesn't start with a comment, return 0 (no bytes skipped)
    _ => 0
  }
}

///|
pub fn tokenize_file(input : BytesView) -> LexResult[File] raise LexError {
  // Parse header
  let header_result = tokenize_header(input)

  // Skip any comments after header
  let mut current_rest = header_result.rest
  let mut current_offset = header_result.bytes_offset
  let comment_skip1 = skip_comment(current_rest)
  if comment_skip1 > 0 {
    current_rest = current_rest[comment_skip1:]
    current_offset += comment_skip1
  }

  // Parse body
  let body_result = tokenize_body(current_rest, current_offset)

  // Skip any comments after body
  current_rest = body_result.rest
  current_offset = body_result.bytes_offset
  let comment_skip2 = skip_comment(current_rest)
  if comment_skip2 > 0 {
    current_rest = current_rest[comment_skip2:]
    current_offset += comment_skip2
  }

  // Parse xref table
  let xref_result = tokenize_xref_table(current_rest, current_offset)

  // Skip any comments after xref table
  current_rest = xref_result.rest
  current_offset = xref_result.bytes_offset
  let comment_skip3 = skip_comment(current_rest)
  if comment_skip3 > 0 {
    current_rest = current_rest[comment_skip3:]
    current_offset += comment_skip3
  }

  // Parse trailer
  let trailer_result = tokenize_trailer(current_rest, current_offset)

  // Skip any comments after trailer
  current_rest = trailer_result.rest
  current_offset = trailer_result.bytes_offset
  let comment_skip4 = skip_comment(current_rest)
  if comment_skip4 > 0 {
    current_rest = current_rest[comment_skip4:]
    current_offset += comment_skip4
  }

  // Parse startxref
  let startxref_result = tokenize_startxref(current_rest, current_offset)

  // Construct the complete File
  LexResult::{
    value: File::{
      header: header_result.value,
      body: body_result.value,
      xref_table: xref_result.value,
      trailer: trailer_result.value,
      start_xref_pos: startxref_result.value,
    },
    bytes_offset: startxref_result.bytes_offset,
    rest: startxref_result.rest,
  }
}
