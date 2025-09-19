///|
pub fn tokenize(input : @string.View) -> Array[(Token, Position, Position)] {
  let mut input = input
  let mut start_row = 0
  let mut start_col = 0
  let mut row = 0
  let mut col = 0
  let result = []
  fn push(tok : Token) -> Unit {
    let start = Position::{ row: start_row, col: start_col }
    let end = Position::{ row, col }
    start_row = row
    start_col = col
    result.push((tok, start, end))
  }

  for {
    lexmatch input {
      "" as s, rest => input = rest
      "(\r\n)|\n", rest => {
        row += 1
        col = 0
        input = rest
      }
      // match the end of input
      "$", _ => {
        push(EOF)
        break
      }
      _ => panic()
    }
  }
  result
}
