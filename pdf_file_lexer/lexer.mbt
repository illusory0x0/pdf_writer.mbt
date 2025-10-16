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
  lexmatch input with longest {
    (
      ("%PDF-" ("\d+" as major) "." ("\d+" as minor) "(\r\n)|\r|\n") as all,
      rest
    ) => {
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
    lexmatch rest with longest {
      // Parse object header first, then handwrite non-greedy content parsing
      (
        (
          ("\d+" as obj_num)
          "[ ]+"
          ("\d+" as gen_num)
          "[ ]+"
          "obj"
          "(\r\n)|\r|\n"
        ) as header,
        rest_after_header
      ) => {
        // Handwritten non-greedy search for first "endobj"
        let endobj_pattern = b"endobj"
        let mut obj_content_end = 0
        let mut found_endobj = false

        // Search for first occurrence of "endobj"
        while obj_content_end + endobj_pattern.length() <=
              rest_after_header.length() {
          let slice = rest_after_header[obj_content_end:obj_content_end +
            endobj_pattern.length()]
          if slice == endobj_pattern[:] {
            found_endobj = true
            break
          }
          obj_content_end += 1
        }
        if not(found_endobj) {
          break // No "endobj" found, stop parsing
        }
        let obj_bytes = rest_after_header[:obj_content_end]
        let rest_after_endobj = rest_after_header[obj_content_end +
          endobj_pattern.length():]

        // Now match the newline after "endobj"
        lexmatch rest_after_endobj with longest {
          ("(\r\n)|\r|\n" as newline, r) => {
            let all_length = header.length() +
              obj_content_end +
              endobj_pattern.length() +
              newline.length()
            let object_num = try! @lexer_bytes.tokenize_int(obj_num)
            let generation_num = try! @lexer_bytes.tokenize_int(gen_num)

            // Store the START position of this object before updating bytes_offset
            let object_start_position = bytes_offset
            bytes_offset += all_length
            let obj = Obj::{
              bytes_offset: object_start_position, // FIX: Use START position, not end position
              object_num,
              generation_num,
              obj_bytes,
            }
            rest = r
            body.push(obj)
          }
          _ => break // No valid newline after "endobj", stop parsing
        }
      }
      ("(\r\n)|\r|\n" as all, r) => {
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
  lexmatch input with longest {
    (
      (
        ("\d+" as offset_str)
        " "
        ("\d+" as gen_str)
        " "
        "n"
        "[ ]*"
        "( \r)|( \n)|(\r\n)|\n|\r"
      ) as all,
      rest
    ) => {
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
      (
        ("\d+" as offset_str)
        " "
        ("\d+" as gen_str)
        " "
        "f"
        "[ ]*"
        "( \r)|( \n)|(\r\n)|\n|\r"
      ) as all,
      rest
    ) => {
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
        "Invalid xref entry format in \{start_bytes_offset}, input `\{try! @encoding/utf8.decode(input)}`",
      )
  }
}

///|
pub fn tokenize_xref_table(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[XRefTable] raise LexError {
  lexmatch input with longest {
    (
      (
        "xref"
        "(\r\n)|\r|\n"
        ("\d+" as start_num_str)
        " "
        ("\d+" as count_str)
        "(\r\n)|\r|\n"
      ) as header,
      rest
    ) => {
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
    _ =>
      raise LexError(
        (
          $| Invalid xref table format in \{start_bytes_offset}
          $|
          $| input: \{try! @encoding/utf8.decode(input)}
        ),
      )
  }
}

///|
pub fn tokenize_trailer(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[BytesView] raise LexError {
  lexmatch input with longest {
    // Parse trailer header first, then handwrite non-greedy content parsing
    (("trailer" "(\r\n)|\r|\n") as header, rest_after_header) => {
      // Handwritten non-greedy search for first "startxref" (preceded by newline)
      let startxref_pattern = b"startxref"
      let mut trailer_content_end = 0
      let mut found_startxref = false

      // Search for first occurrence of "\nstartxref" or "\r\nstartxref" or "\rstartxref"
      while trailer_content_end + startxref_pattern.length() <=
            rest_after_header.length() {
        // Check if we're at a potential startxref location
        if trailer_content_end + startxref_pattern.length() <=
          rest_after_header.length() {
          let slice = rest_after_header[trailer_content_end:trailer_content_end +
            startxref_pattern.length()]
          if slice == startxref_pattern[:] {
            // Found "startxref", but need to check if it's preceded by newline
            if trailer_content_end == 0 {
              // At the very beginning, this shouldn't happen in valid PDF
              found_startxref = true
              break
            } else {
              // Check if preceded by newline
              let prev_char = rest_after_header[trailer_content_end - 1]
              if prev_char == '\n' || prev_char == '\r' {
                found_startxref = true
                break
              }
            }
          }
        }
        trailer_content_end += 1
      }
      if not(found_startxref) {
        raise LexError("No 'startxref' found after trailer")
      }

      // Extract trailer dictionary content (excluding the final newline before startxref)
      let mut dict_end = trailer_content_end
      // Remove trailing newline if present
      if dict_end > 0 {
        let last_char = rest_after_header[dict_end - 1]
        if last_char == '\n' || last_char == '\r' {
          dict_end -= 1
          // Also remove \r if we have \r\n
          if dict_end > 0 &&
            last_char == '\n' &&
            rest_after_header[dict_end - 1] == '\r' {
            dict_end -= 1
          }
        }
      }
      let trailer_dict = rest_after_header[:dict_end]
      let rest_at_newline = rest_after_header[dict_end:]

      // Now match the newline before "startxref"
      lexmatch rest_at_newline with longest {
        ("(\r\n)|\r|\n" as newline, rest) => {
          let all_length = header.length() + dict_end + newline.length()
          LexResult::{
            value: trailer_dict,
            bytes_offset: start_bytes_offset + all_length,
            rest,
          }
        }
        _ => raise LexError("Expected newline before 'startxref'")
      }
    }
    _ => raise LexError("Invalid trailer format")
  }
}

///|
pub fn tokenize_startxref(
  input : BytesView,
  start_bytes_offset : Int,
) -> LexResult[Int] raise LexError {
  lexmatch input with longest {
    (
      ("startxref" "(\r\n)|\r|\n" ("\d+" as offset_str) "(\r\n)|\r|\n" "%%EOF") as all,
      rest
    ) => {
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
  lexmatch input with longest {
    // Parse comment start marker first, then handwrite length-limited content parsing
    ("%" as _percent, rest_after_percent) => {
      // Handwritten comment parsing with DoS protection (max 1024 chars)
      let max_comment_length = 1024
      let mut comment_content_end = 0
      let mut found_newline = false
      let mut is_eof_comment = false

      // Search for newline or end of input, with length limit
      while comment_content_end < rest_after_percent.length() &&
            comment_content_end < max_comment_length {
        let char = rest_after_percent[comment_content_end]
        if char == '\r' || char == '\n' {
          found_newline = true
          break
        }
        comment_content_end += 1
      }

      // If we reached end of input without newline, it's an EOF comment
      if not(found_newline) &&
        comment_content_end == rest_after_percent.length() {
        is_eof_comment = true
      }
      if is_eof_comment {
        // Comment at EOF without trailing newline - safe to consume all remaining
        1 + comment_content_end // 1 for the '%' character
      } else if found_newline {
        // Comment with newline - match the newline using lexmatch
        let rest_at_newline = rest_after_percent[comment_content_end:]
        lexmatch rest_at_newline with longest {
          ("(\r\n)|\r|\n" as newline, _rest) =>
            1 + comment_content_end + newline.length()
          _ => // 1 for the '%' character
            0 // Shouldn't happen since we found newline, but safety fallback
        }
      } else {
        // Hit length limit without finding newline - truncate comment for DoS protection
        1 + comment_content_end // 1 for the '%' character
      }
    }

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

///|
test {
  let input = b"4 0 obj \x0a<<\x0a/Border [0 0 0]\x0a/Subtype /Link\x0a/C [0 0 0]\x0a/A \x0a<<\x0a/URI (http://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2006:033:0001:0017:EN:PDF#page=8)\x0a/S /URI\x0a>>\x0a/Type /Annot\x0a/Rect [312 719 469 735]\x0a>>\x0aendobj"
  let result = tokenize_body(input, 0)
  @json.inspect(result, content={
    "value": [],
    "bytes_offset": 0,
    "rest": "4 0 obj \\n<<\\n/Border [0 0 0]\\n/Subtype /Link\\n/C [0 0 0]\\n/A \\n<<\\n/URI (http://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2006:033:0001:0017:EN:PDF#page=8)\\n/S /URI\\n>>\\n/Type /Annot\\n/Rect [312 719 469 735]\\n>>\\nendobj",
  })
}
