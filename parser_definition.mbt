
pub suberror ParseError {
  UnexpectedToken(Token, (Position, Position), Array[TokenKind])
  UnexpectedEndOfInput(Position, Array[TokenKind])
}

typealias Error as YYObj

priv suberror YYObj_Void

priv suberror YYObj_Int Int

priv suberror YYObj_Unit Unit

priv suberror YYObj_Bytes Bytes

priv suberror YYObj_Double Double

typealias (YYSymbol) -> YYDecision as YYState

typealias (Position, ArrayView[(YYObj, Position, Position)]) -> YYObj as YYAction

priv enum YYDecision {
  Accept
  Shift(YYState)
  Reduce(Int, YYSymbol, YYAction)
  ReduceNoLookahead(Int, YYSymbol, YYAction)
  Error
}

priv enum YYSymbol {
  T_LEFT_PARENTHESIS
  T_RIGHT_PARENTHESIS
  T_LEFT_CURLY_BRACE
  T_RIGHT_CURLY_BRACE
  T_LEFT_SQUARE_BRACKET
  T_RIGHT_SQUARE_BRACKET
  T_LESS_THAN_SIGN
  T_GREATER_THAN_SIGN
  T_SOLIDUS
  T_DICT_BEGIN
  T_DICT_END
  T_TRUE
  T_FALSE
  T_INTEGER
  T_REAL
  T_STRING
  T_NAME
  T_EOF
  NT_parse
  EOI
}

// Workaround for EOI unused warning
fn init {
  match (EOI : YYSymbol) {
    EOI => ()
    _ => ()
  }
}

// file:///./parser.mbty
// 73|     EOF { $1 }
fn yy_action_0(_last_pos : Position, _args : ArrayView[(YYObj, Position, Position)]) -> YYObj {
  let _dollar1 = ()
  YYObj_Unit({();  _dollar1 })
}

fn yy_input(token : Token, _start_pos : Position, _end_pos : Position) -> (YYSymbol, YYObj) {
  match token {
    LEFT_PARENTHESIS => (T_LEFT_PARENTHESIS, YYObj_Void)
    RIGHT_PARENTHESIS => (T_RIGHT_PARENTHESIS, YYObj_Void)
    LEFT_CURLY_BRACE => (T_LEFT_CURLY_BRACE, YYObj_Void)
    RIGHT_CURLY_BRACE => (T_RIGHT_CURLY_BRACE, YYObj_Void)
    LEFT_SQUARE_BRACKET => (T_LEFT_SQUARE_BRACKET, YYObj_Void)
    RIGHT_SQUARE_BRACKET => (T_RIGHT_SQUARE_BRACKET, YYObj_Void)
    LESS_THAN_SIGN => (T_LESS_THAN_SIGN, YYObj_Void)
    GREATER_THAN_SIGN => (T_GREATER_THAN_SIGN, YYObj_Void)
    SOLIDUS => (T_SOLIDUS, YYObj_Void)
    DICT_BEGIN => (T_DICT_BEGIN, YYObj_Void)
    DICT_END => (T_DICT_END, YYObj_Void)
    TRUE => (T_TRUE, YYObj_Void)
    FALSE => (T_FALSE, YYObj_Void)
    INTEGER(data) => (T_INTEGER, YYObj_Int(data))
    REAL(data) => (T_REAL, YYObj_Double(data))
    STRING(data) => (T_STRING, YYObj_Bytes(data))
    NAME(data) => (T_NAME, YYObj_Bytes(data))
    EOF => (T_EOF, YYObj_Void)
  }
}

fn yy_state_0(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_parse => Shift(yy_state_1)
    T_EOF => Shift(yy_state_2)
    _ => Error
  }
}

fn yy_state_1(_lookahead : YYSymbol) -> YYDecision {
  Accept
}

fn yy_state_2(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_parse, yy_action_0)
}

fn[T] yy_parse(
  tokens : Array[(Token, Position, Position)],
  start : YYState,
  return_ : (YYObj) -> T,
  initial_pos? : Position,
) -> T raise ParseError {
  let mut cursor = 0
  let mut state_stack : @list.List[YYState] = @list.cons(start, @list.empty())
  let data_stack : Array[(YYObj, Position, Position)] = []
  let mut last_pos = initial_pos.unwrap_or(tokens[0].1)
  let mut state = start
  let mut lookahead : Option[(YYSymbol, (YYObj, Position, Position), Token?)] = None
  let mut last_shifted_state_stack = state_stack
  while true {
    let decision = match state(EOI) {
      ReduceNoLookahead(_) | Accept as t => t
      _ => {
        match lookahead {
          Some(la) => state(la.0)
          None => {
            if cursor < tokens.length() {
              let (token, start_pos, end_pos) = tokens[cursor]
              cursor += 1
              let (symbol, data) = yy_input(token, start_pos, end_pos)
              lookahead = Some((symbol, (data, start_pos, end_pos), Some(token)))
              state(symbol)
            } else {
              lookahead = Some((EOI, (YYObj_Void, last_pos, last_pos), None))
              state(EOI)
            }
          }
        }
      }
    }
    match decision {
      Accept => return return_(data_stack.unsafe_pop().0)
      Shift(next_state) => {
        guard lookahead is Some(la)
        data_stack.push(la.1)
        state_stack = @list.cons(next_state, state_stack)
        last_shifted_state_stack = state_stack
        state = next_state
        last_pos = la.1.2
        lookahead = None
      }
      Reduce(count, symbol, action)
      | ReduceNoLookahead(count, symbol, action) => {
        loop (count, symbol, action) {
          _ => {
            let args = data_stack[data_stack.length() - count:]
            let data = action(last_pos, args)
            let (start_pos, end_pos) = if args.length() == 0 {
              (last_pos, last_pos)
            } else {
              (args[0].1, args[args.length() - 1].2)
            }
            for i in 0..<count {
              ignore(data_stack.unsafe_pop())
              state_stack = state_stack.unsafe_tail()
            }
            state = state_stack.unsafe_head()
            data_stack.push((data, start_pos, end_pos))
            match state(symbol) {
              Accept => return return_(data_stack.unsafe_pop().0)
              Shift(next_state) => {
                state_stack = @list.cons(next_state, state_stack)
                state = next_state
              }
              Reduce(count, symbol, action)
              | ReduceNoLookahead(count, symbol, action) => continue (count, symbol, action)
              _ => panic()
            }
          }
        }
      }
      Error => {
        let (_, (_, start_pos, end_pos), token) = lookahead.unwrap()
        error(last_shifted_state_stack, token, (start_pos, end_pos))
      }
    }
  }
  panic()
}

fn error(stack : @list.List[YYState], token : Token?, loc : (Position, Position)) -> Unit raise ParseError {
  let expected = []
  fn try_add(symbol : YYSymbol, kind : TokenKind) {
    fn go(stack : @list.List[YYState]) {
      match stack {
        Empty => ()
        More(state, ..) => {
          match state(symbol) {
            Accept | Shift(_) => expected.push(kind)
            Reduce(count, symbol, _) | ReduceNoLookahead(count, symbol, _) => {
              fn inner_go(stack : @list.List[YYState], count, symbol) {
                let stack = stack.drop(count)
                guard stack is More(state, ..)
                match state(symbol) {
                  Shift(state) => go(@list.cons(state, stack))
                  Reduce(count, symbol, _) | ReduceNoLookahead(count, symbol, _) => inner_go(stack, count, symbol)
                  _ => panic()
                }
              }
              inner_go(stack, count, symbol)
            }
            Error => ()
          }
        }
      }
    }
    go(stack)
  }
  for term in ([(T_LEFT_PARENTHESIS, TK_LEFT_PARENTHESIS), (T_RIGHT_PARENTHESIS, TK_RIGHT_PARENTHESIS), (T_LEFT_CURLY_BRACE, TK_LEFT_CURLY_BRACE), (T_RIGHT_CURLY_BRACE, TK_RIGHT_CURLY_BRACE), (T_LEFT_SQUARE_BRACKET, TK_LEFT_SQUARE_BRACKET), (T_RIGHT_SQUARE_BRACKET, TK_RIGHT_SQUARE_BRACKET), (T_LESS_THAN_SIGN, TK_LESS_THAN_SIGN), (T_GREATER_THAN_SIGN, TK_GREATER_THAN_SIGN), (T_SOLIDUS, TK_SOLIDUS), (T_DICT_BEGIN, TK_DICT_BEGIN), (T_DICT_END, TK_DICT_END), (T_TRUE, TK_TRUE), (T_FALSE, TK_FALSE), (T_INTEGER, TK_INTEGER), (T_REAL, TK_REAL), (T_STRING, TK_STRING), (T_NAME, TK_NAME), (T_EOF, TK_EOF)] : Array[(YYSymbol, TokenKind)]) {
    try_add(term.0, term.1)
  }
  match token {
    None => raise UnexpectedEndOfInput(loc.1, expected)
    Some(token) => raise UnexpectedToken(token, loc, expected)
  }
}

pub fn parse(tokens : Array[(Token, Position, Position)], initial_pos? : Position) -> Unit raise ParseError {
  yy_parse(
    tokens,
    yy_state_0,
    (it) => {
      guard it is YYObj_Unit(result)
      result
    },
    initial_pos?,
  )
}
