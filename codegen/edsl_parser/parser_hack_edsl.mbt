///|
#callsite(autofill(loc))
pub fn[Action] rule(action : Action, loc~ : SourceLoc) -> SourceLocation {
  ignore(action)
  loc.to_string() |> SourceLocation::from_string
}

///|
#callsite(autofill(loc))
pub fn current_source_location(loc~ : SourceLoc) -> SourceLocation {
  loc.to_string() |> SourceLocation::from_string
}

///|
pub struct SourceLocation {
  path : String
  start_row : Int
  start_col : Int
  end_row : Int
  end_col : Int
}

///|
pub fn SourceLocation::from_string(s : String) -> SourceLocation {
  // Parse strings like "/path/to/file.mbt:14:5-16:68" or "/path/to/file.mbt:14:5"

  // Helper function to find the colon that separates path from line:col
  fn find_path_colon(str : String) -> Int {
    // Look for patterns like ":14:5" or ":14:5-" from the end
    // We want the first colon in such a pattern
    let mut i = 0
    while i < str.length() {
      if str[i] == ':' {
        // Check if this looks like ":line:col" pattern
        let mut j = i + 1
        let mut first_num = 0
        // Parse first number (line)
        while j < str.length() && str[j] >= '0' && str[j] <= '9' {
          first_num = first_num * 10 + (str[j] - '0')
          j += 1
        }
        if first_num > 0 && j < str.length() && str[j] == ':' {
          // We have ":number:", now check for second number (column)
          j += 1
          let mut second_num = 0
          while j < str.length() && str[j] >= '0' && str[j] <= '9' {
            second_num = second_num * 10 + (str[j] - '0')
            j += 1
          }
          if second_num > 0 && (j == str.length() || str[j] == '-') {
            // Found ":line:col" or ":line:col-", this is our path colon
            return i
          }
        } else if first_num > 0 && (j == str.length() || str[j] == '-') {
          // Found ":line" or ":line-", this is our path colon
          return i
        }
      }
      i += 1
    }
    -1
  }

  // Helper function to find first occurrence of a character in StringView
  fn find_char_view(str : StringView, ch : Char) -> Int {
    let mut i = 0
    while i < str.length() {
      if str.get_char(i) == Some(ch) {
        return i
      }
      i += 1
    }
    -1
  }

  // Helper function to parse integer from StringView
  fn parse_int_safe_view(str : StringView) -> Int {
    let mut result = 0
    let mut i = 0
    while i < str.length() {
      match str.get_char(i) {
        Some(ch) if ch >= '0' && ch <= '9' =>
          result = result * 10 + (ch.to_int() - '0'.to_int())
        _ => break
      }
      i += 1
    }
    if result == 0 {
      1
    } else {
      result
    }
  }

  let last_colon_pos = find_path_colon(s)
  if last_colon_pos == -1 {
    // Fallback: assume entire string is path with default position
    return SourceLocation::{
      path: s,
      start_row: 1,
      start_col: 1,
      end_row: 1,
      end_col: 1,
    }
  }

  // Extract path and position parts
  let path = (try! s[0:last_colon_pos]).to_string()
  let position_part = try! s[last_colon_pos + 1:]

  // Find the first ':' in position part for row:col separation
  let colon_pos = find_char_view(position_part, ':')
  if colon_pos == -1 {
    // Only row number, no column
    let row = parse_int_safe_view(position_part)
    return SourceLocation::{
      path,
      start_row: row,
      start_col: 1,
      end_row: row,
      end_col: 1,
    }
  }
  let start_row_str = try! position_part[0:colon_pos]
  let rest = try! position_part[colon_pos + 1:]

  // Find start column part (before '-' if present)
  let dash_pos = find_char_view(rest, '-')
  let start_col_str = if dash_pos == -1 { rest } else { try! rest[0:dash_pos] }
  let start_row = parse_int_safe_view(start_row_str)
  let start_col = parse_int_safe_view(start_col_str)
  if dash_pos == -1 {
    // No range, end position same as start position
    return SourceLocation::{
      path,
      start_row,
      start_col,
      end_row: start_row,
      end_col: start_col,
    }
  }

  // Parse end position from range part
  let range_part = try! rest[dash_pos + 1:]
  let end_colon_pos = find_char_view(range_part, ':')
  if end_colon_pos == -1 {
    // Only end row, assume same column as start
    let end_row = parse_int_safe_view(range_part)
    return SourceLocation::{
      path,
      start_row,
      start_col,
      end_row,
      end_col: start_col,
    }
  }
  let end_row_str = try! range_part[0:end_colon_pos]
  let end_col_str = try! range_part[end_colon_pos + 1:]
  let end_row = parse_int_safe_view(end_row_str)
  let end_col = parse_int_safe_view(end_col_str)
  SourceLocation::{ path, start_row, start_col, end_row, end_col }
}

///|
pub fn read_code_snippet(loc : SourceLocation) -> String raise {
  let file = @fs.read_file_to_string(loc.path)

  // Split file content into lines and convert to array
  let lines = file.split("\n").collect()

  // Validate line numbers (1-indexed)
  if loc.start_row < 1 || loc.start_row > lines.length() {
    raise Failure(
      "Start row \{loc.start_row} is out of bounds (1-\{lines.length()})",
    )
  }
  if loc.end_row < 1 || loc.end_row > lines.length() {
    raise Failure(
      "End row \{loc.end_row} is out of bounds (1-\{lines.length()})",
    )
  }
  if loc.start_row > loc.end_row {
    raise Failure(
      "Start row \{loc.start_row} is greater than end row \{loc.end_row}",
    )
  }

  // Handle single line case
  if loc.start_row == loc.end_row {
    let line = lines[loc.start_row - 1] // Convert to 0-indexed
    let start_col = if loc.start_col < 1 { 1 } else { loc.start_col }
    let end_col = if loc.end_col < 1 { line.length() + 1 } else { loc.end_col }

    // Validate column bounds
    if start_col > line.length() + 1 {
      return "" // Empty if start column is beyond line end
    }
    let actual_end = if end_col > line.length() + 1 {
      line.length() + 1
    } else {
      end_col
    }
    let actual_start = start_col - 1 // Convert to 0-indexed
    let actual_end_idx = actual_end - 1 // Convert to 0-indexed
    if actual_start >= actual_end_idx {
      return ""
    }
    return line[actual_start:actual_end_idx].to_string()
  }

  // Handle multi-line case
  let result = []

  // First line: from start_col to end of line
  let first_line = lines[loc.start_row - 1]
  let start_col = if loc.start_col < 1 { 1 } else { loc.start_col }
  if start_col <= first_line.length() + 1 {
    let start_idx = start_col - 1 // Convert to 0-indexed
    let first_part = if start_idx < first_line.length() {
      first_line[start_idx:].to_string()
    } else {
      ""
    }
    result.push(first_part)
  }

  // Middle lines: entire lines
  for i = loc.start_row + 1; i < loc.end_row; i = i + 1 {
    result.push(lines[i - 1].to_string()) // Convert to 0-indexed and to String
  }

  // Last line: from beginning to end_col
  if loc.end_row > loc.start_row {
    let last_line = lines[loc.end_row - 1]
    let end_col = if loc.end_col < 1 {
      last_line.length() + 1
    } else {
      loc.end_col
    }
    let end_idx = if end_col > last_line.length() + 1 {
      last_line.length()
    } else {
      end_col - 1
    }
    let last_part = if end_idx > 0 {
      last_line[0:end_idx].to_string()
    } else {
      ""
    }
    result.push(last_part)
  }

  // Join with newlines
  result.join("\n")
}

///|
pub fn SourceLocation::split_file(
  file : String,
  locs : Array[SourceLocation],
) -> Array[StringView] {
  // Split file content into lines
  let lines = file.split("\n").collect()
  let result : Array[StringView] = []
  for loc in locs {
    // Validate line numbers (1-indexed)
    if loc.start_row < 1 ||
      loc.start_row > lines.length() ||
      loc.end_row < 1 ||
      loc.end_row > lines.length() ||
      loc.start_row > loc.end_row {
      // Skip invalid locations, add empty StringView
      result.push("".to_string())
      continue
    }

    // Handle single line case
    if loc.start_row == loc.end_row {
      let line = lines[loc.start_row - 1] // Convert to 0-indexed
      let start_col = if loc.start_col < 1 { 1 } else { loc.start_col }
      let end_col = if loc.end_col < 1 {
        line.length() + 1
      } else {
        loc.end_col
      }

      // Validate column bounds
      if start_col > line.length() + 1 {
        result.push("".to_string())
        continue
      }
      let actual_end = if end_col > line.length() + 1 {
        line.length() + 1
      } else {
        end_col
      }
      let actual_start = start_col - 1 // Convert to 0-indexed
      let actual_end_idx = actual_end - 1 // Convert to 0-indexed
      if actual_start >= actual_end_idx {
        result.push("".to_string())
      } else {
        result.push(try! line[actual_start:actual_end_idx])
      }
      continue
    }

    // Handle multi-line case
    let parts : Array[String] = []

    // First line: from start_col to end of line
    let first_line = lines[loc.start_row - 1]
    let start_col = if loc.start_col < 1 { 1 } else { loc.start_col }
    if start_col <= first_line.length() + 1 {
      let start_idx = start_col - 1 // Convert to 0-indexed
      let first_part = if start_idx < first_line.length() {
        (try! first_line[start_idx:]).to_string()
      } else {
        ""
      }
      parts.push(first_part)
    }

    // Middle lines: entire lines
    for i = loc.start_row + 1; i < loc.end_row; i = i + 1 {
      parts.push(lines[i - 1].to_string()) // Convert to 0-indexed and to String
    }

    // Last line: from beginning to end_col
    if loc.end_row > loc.start_row {
      let last_line = lines[loc.end_row - 1]
      let end_col = if loc.end_col < 1 {
        last_line.length() + 1
      } else {
        loc.end_col
      }
      let end_idx = if end_col > last_line.length() + 1 {
        last_line.length()
      } else {
        end_col - 1
      }
      let last_part = if end_idx > 0 {
        (try! last_line[0:end_idx]).to_string()
      } else {
        ""
      }
      parts.push(last_part)
    }

    // Join parts with newlines and convert to StringView
    let combined_content = parts.join("\n")
    result.push(combined_content)
  }
  result
}

///|
test "SourceLocation::split_file" {
  let file_content = "line 1\nline 2 with more text\nline 3\nline 4"

  // Test single line extraction
  let loc1 = SourceLocation::{
    path: "test.mbt",
    start_row: 2,
    start_col: 1,
    end_row: 2,
    end_col: 6,
  }

  // Test multi-line extraction
  let loc2 = SourceLocation::{
    path: "test.mbt",
    start_row: 2,
    start_col: 8,
    end_row: 3,
    end_col: 4,
  }
  let locations = [loc1, loc2]
  let results = SourceLocation::split_file(file_content, locations)
  inspect(results.length(), content="2")
  inspect(results[0].to_string(), content="line ")
  inspect(
    results[1].to_string(),
    content=(
      #|with more text
      #|lin
    ),
  )
}

///|
pub struct Parm {
  name : String
  typ : String
} derive(ToJson, @json.FromJson)

///|
pub struct Func {
  parms : Array[Parm]
  rslt_typ : String
  body : String
} derive(ToJson, @json.FromJson)

///|
pub fn Func::parse(s : StringView) -> Func {
  let parm_typ : Array[Parm] = []
  let mut rslt_typ = ""
  let mut body = ""

  // Find the "fn(" pattern
  let mut i = 0
  while i < s.length() - 2 {
    if s[i] == 'f' && s[i + 1] == 'n' && s[i + 2] == '(' {
      i += 3 // Skip "fn("
      break
    }
    i += 1
  }
  if i >= s.length() {
    return Func::{ parms: parm_typ, rslt_typ, body }
  }

  // Parse parameters
  while i < s.length() && s[i] != ')' {
    // Skip spaces
    while i < s.length() && s[i] == ' ' {
      i += 1
    }
    if i >= s.length() || s[i] == ')' {
      break
    }

    // Collect parameter name until ':'
    let name_start = i
    while i < s.length() && s[i] != ':' && s[i] != ')' {
      i += 1
    }
    if i >= s.length() || s[i] == ')' {
      break
    }
    let param_name = try! s[name_start:i].trim_space().to_string()
    i += 1 // Skip ':'

    // Skip spaces after colon
    while i < s.length() && s[i] == ' ' {
      i += 1
    }

    // Collect type until ',' or ')'
    let type_start = i
    while i < s.length() && s[i] != ',' && s[i] != ')' {
      i += 1
    }
    if type_start < i {
      let type_str = try! s[type_start:i].trim_space().to_string()
      parm_typ.push(Parm::{ name: param_name, typ: type_str })
    }

    // Skip comma if present
    if i < s.length() && s[i] == ',' {
      i += 1
    }
  }

  // Find the "->" for return type
  while i < s.length() - 1 {
    if s[i] == '-' && s[i + 1] == '>' {
      i += 2 // Skip "->"
      break
    }
    i += 1
  }

  // Skip spaces after "->"
  while i < s.length() && s[i] == ' ' {
    i += 1
  }

  // Collect return type until '{'
  let start = i
  while i < s.length() && s[i] != '{' {
    i += 1
  }
  if start < i {
    rslt_typ = try! s[start:i].trim_space().to_string()
  }

  // Parse function body
  if i < s.length() && s[i] == '{' {
    i += 1 // Skip opening '{'
    let body_start = i
    let mut brace_count = 1

    // Find matching closing brace
    while i < s.length() && brace_count > 0 {
      if s[i] == '{' {
        brace_count += 1
      } else if s[i] == '}' {
        brace_count -= 1
      }
      if brace_count > 0 {
        i += 1
      }
    }
    if body_start < i {
      body = try! s[body_start:i].trim_space().to_string()
    }
  }
  Func::{ parms: parm_typ, rslt_typ, body }
}

///|
/// 
/// `Func` is correspond to BNF production rule's action.
/// 
/// parameter type is correspond to non-terminal symbol or terminal symbol.
/// 
/// parameter name is action parameter which is need to map to `$N`, the first parameter is `$1`.
/// this function will replace Func::body's parameter name to `$N`. simply substitution.
/// 
/// result type is correspond to production rule's name which introduce non-terminal symbol.
/// 
/// 
pub fn Func::to_production_rule(typ : Func) -> String {
  // Build the parameter types for the production rule
  let rule_parts : Array[String] = []
  for parm in typ.parms {
    rule_parts.push(parm.typ)
  }
  let rule_lhs = rule_parts.join(" ")

  // Replace parameter names with $N in the body
  let mut body = typ.body
  for i = 0; i < typ.parms.length(); i = i + 1 {
    let parm_name = typ.parms[i].name
    let replacement = "$\{i + 1}"
    // Simple string replacement - replace parameter name with $N
    body = body.replace_all(old=parm_name, new=replacement)
  }

  // Format as production rule: "| rule_lhs { body }"
  "| \{rule_lhs} { \{body.trim_space()} }"
}

///|
/// 
/// Return the non-terminal symbol name which is correspond to production rule's name.
///
pub fn Func::name(self : Func) -> String {
  self.rslt_typ
}

///|
/// 
/// `Func` is production rule's action.
/// 
/// `Array[Func]` is production rules for every case of non-terminal symbol.
///
pub struct NonTerminal(Array[Func]) derive(ToJson, @json.FromJson)

///|
/// check all production rules have same result type which also means has the same non-terminal symbol name.
/// 
pub fn NonTerminal::emit(self : NonTerminal) -> String {
  if self.0.is_empty() {
    return ""
  }

  // Get the non-terminal name from the first function's result type
  let nonterminal_name = self.0[0].name()

  // Generate production rules for each function
  let rules : Array[String] = []
  for func in self.0 {
    rules.push(func.to_production_rule())
  }

  // Format as: "NonTerminal -> NonTerminal :\n  rule1\n  rule2\n;"
  let rules_str = rules.join("\n  ")
  "\{nonterminal_name} -> \{nonterminal_name} :\n  \{rules_str}\n;\n"
}

///|
pub fn NonTerminal::from(symbols : Array[SourceLocation]) -> NonTerminal raise {
  // Guard: check that all symbols have the same path
  if symbols.length() > 0 {
    let first_path = symbols[0].path
    for i = 1; i < symbols.length(); i = i + 1 {
      if symbols[i].path != first_path {
        fail(
          "All SourceLocation symbols must have the same path. Found '\{symbols[i].path}' but expected '\{first_path}'",
        )
      }
    }
  }
  let file = try! @fs.read_file_to_string(symbols[0].path)
  let snippets = SourceLocation::split_file(file, symbols)
  NonTerminal(snippets.map((s : StringView) => Func::parse(s.to_string())))
}
