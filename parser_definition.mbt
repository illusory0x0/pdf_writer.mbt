///|
pub suberror ParseError {
  UnexpectedToken(Token, (Position, Position), Array[TokenKind])
  UnexpectedEndOfInput(Position, Array[TokenKind])
}

///|
typealias Error as YYObj

///|
priv suberror YYObj_Void

///|
priv suberror YYObj_Int Int

///|
priv suberror YYObj_Atom Atom

///|
priv suberror YYObj_Bytes Bytes

///|
priv suberror YYObj_Double Double

///|
priv suberror YYObj_Object Object

///|
priv suberror YYObj_INDIRECT INDIRECT

///|
priv suberror YYObj_PDF_Array PDF_Array

///|
priv suberror YYObj_NonEmptyElems NonEmptyElems

///|
typealias (YYSymbol) -> YYDecision as YYState

///|
typealias (Position, ArrayView[(YYObj, Position, Position)]) -> YYObj as YYAction

///|
priv enum YYDecision {
  Accept
  Shift(YYState)
  Reduce(Int, YYSymbol, YYAction)
  ReduceNoLookahead(Int, YYSymbol, YYAction)
  Error
}

///|
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
  T_NULL
  T_TRUE
  T_FALSE
  T_INTEGER
  T_REAL
  T_STRING
  T_NAME
  T_INDIRECT
  T_EOF
  NT_parse
  NT_Atom
  NT_NonEmptyElems
  NT_PDF_Array
  EOI
}

// Workaround for EOI unused warning

///|
fn init {
  match (EOI : YYSymbol) {
    EOI => ()
    _ => ()
  }
}

// file:///./parser.mbty
// 77|     PDF_Array EOF { $1 }

///|
fn yy_action_0(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_PDF_Array(_dollar1)
  YYObj_Object(
    {
      ()
      _dollar1
    },
  )
}

// file:///./parser.mbty
// 91|    Atom { [$1] }

///|
fn yy_action_1(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_Atom(_dollar1)
  YYObj_NonEmptyElems(
    {
      ()
      [_dollar1]
    },
  )
}

// file:///./parser.mbty
// 81|    NAME { Name($1) }

///|
fn yy_action_2(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_Bytes(_dollar1)
  YYObj_Atom(
    {
      ()
      Name(_dollar1)
    },
  )
}

// file:///./parser.mbty
// 82|    STRING { String($1) }

///|
fn yy_action_3(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_Bytes(_dollar1)
  YYObj_Atom(
    {
      ()
      String(_dollar1)
    },
  )
}

// file:///./parser.mbty
// 83|    INTEGER { Integer($1) }

///|
fn yy_action_4(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_Int(_dollar1)
  YYObj_Atom(
    {
      ()
      Integer(_dollar1)
    },
  )
}

// file:///./parser.mbty
// 84|    REAL { Real($1) }

///|
fn yy_action_5(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_Double(_dollar1)
  YYObj_Atom(
    {
      ()
      Real(_dollar1)
    },
  )
}

// file:///./parser.mbty
// 85|    NULL { Null }

///|
fn yy_action_6(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  YYObj_Atom(
    {
      ()
      Null
    },
  )
}

// file:///./parser.mbty
// 86|    TRUE { Boolean(true) }

///|
fn yy_action_7(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  YYObj_Atom(
    {
      ()
      Boolean(true)
    },
  )
}

// file:///./parser.mbty
// 87|    FALSE { Boolean(false) }

///|
fn yy_action_8(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  YYObj_Atom(
    {
      ()
      Boolean(false)
    },
  )
}

// file:///./parser.mbty
// 88|    INDIRECT { Indirect($1.object_num) }

///|
fn yy_action_9(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_INDIRECT(_dollar1)
  YYObj_Atom(
    {
      ()
      Indirect(_dollar1.object_num)
    },
  )
}

// file:///./parser.mbty
// 92|    NonEmptyElems Atom { $1.push($2)
// 93|      $1 }

///|
fn yy_action_10(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[0].0 is YYObj_NonEmptyElems(_dollar1)
  guard _args[1].0 is YYObj_Atom(_dollar2)
  YYObj_NonEmptyElems(
    {
      ()
      _dollar1.push(_dollar2)
      _dollar1
    },
  )
}

// file:///./parser.mbty
// 97|    LEFT_SQUARE_BRACKET NonEmptyElems RIGHT_SQUARE_BRACKET { Array($2) }

///|
fn yy_action_11(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  guard _args[1].0 is YYObj_NonEmptyElems(_dollar2)
  YYObj_PDF_Array(
    {
      ()
      Array(_dollar2)
    },
  )
}

// file:///./parser.mbty
// 96|    LEFT_SQUARE_BRACKET RIGHT_SQUARE_BRACKET { Object::Array([]) }

///|
fn yy_action_12(
  _last_pos : Position,
  _args : ArrayView[(YYObj, Position, Position)],
) -> YYObj {
  YYObj_PDF_Array(
    {
      ()
      Object::Array([])
    },
  )
}

///|
fn yy_input(
  token : Token,
  _start_pos : Position,
  _end_pos : Position,
) -> (YYSymbol, YYObj) {
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
    NULL => (T_NULL, YYObj_Void)
    TRUE => (T_TRUE, YYObj_Void)
    FALSE => (T_FALSE, YYObj_Void)
    INTEGER(data) => (T_INTEGER, YYObj_Int(data))
    REAL(data) => (T_REAL, YYObj_Double(data))
    STRING(data) => (T_STRING, YYObj_Bytes(data))
    NAME(data) => (T_NAME, YYObj_Bytes(data))
    INDIRECT(data) => (T_INDIRECT, YYObj_INDIRECT(data))
    EOF => (T_EOF, YYObj_Void)
  }
}

///|
fn yy_state_0(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    NT_parse => Shift(yy_state_1)
    T_LEFT_SQUARE_BRACKET => Shift(yy_state_2)
    NT_PDF_Array => Shift(yy_state_16)
    _ => Error
  }
}

///|
fn yy_state_1(_lookahead : YYSymbol) -> YYDecision {
  Accept
}

///|
fn yy_state_2(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_RIGHT_SQUARE_BRACKET => Shift(yy_state_3)
    NT_NonEmptyElems => Shift(yy_state_4)
    T_INDIRECT => Shift(yy_state_7)
    T_FALSE => Shift(yy_state_8)
    T_TRUE => Shift(yy_state_9)
    T_NULL => Shift(yy_state_10)
    T_REAL => Shift(yy_state_11)
    T_INTEGER => Shift(yy_state_12)
    T_STRING => Shift(yy_state_13)
    T_NAME => Shift(yy_state_14)
    NT_Atom => Shift(yy_state_15)
    _ => Error
  }
}

///|
fn yy_state_3(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_PDF_Array, yy_action_12)
}

///|
fn yy_state_4(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_RIGHT_SQUARE_BRACKET => Shift(yy_state_5)
    NT_Atom => Shift(yy_state_6)
    T_INDIRECT => Shift(yy_state_7)
    T_FALSE => Shift(yy_state_8)
    T_TRUE => Shift(yy_state_9)
    T_NULL => Shift(yy_state_10)
    T_REAL => Shift(yy_state_11)
    T_INTEGER => Shift(yy_state_12)
    T_STRING => Shift(yy_state_13)
    T_NAME => Shift(yy_state_14)
    _ => Error
  }
}

///|
fn yy_state_5(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(3, NT_PDF_Array, yy_action_11)
}

///|
fn yy_state_6(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_NonEmptyElems, yy_action_10)
}

///|
fn yy_state_7(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_9)
}

///|
fn yy_state_8(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_8)
}

///|
fn yy_state_9(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_7)
}

///|
fn yy_state_10(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_6)
}

///|
fn yy_state_11(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_5)
}

///|
fn yy_state_12(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_4)
}

///|
fn yy_state_13(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_3)
}

///|
fn yy_state_14(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_Atom, yy_action_2)
}

///|
fn yy_state_15(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(1, NT_NonEmptyElems, yy_action_1)
}

///|
fn yy_state_16(_lookahead : YYSymbol) -> YYDecision {
  match _lookahead {
    T_EOF => Shift(yy_state_17)
    _ => Error
  }
}

///|
fn yy_state_17(_lookahead : YYSymbol) -> YYDecision {
  ReduceNoLookahead(2, NT_parse, yy_action_0)
}

///|
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
  let mut lookahead : (YYSymbol, (YYObj, Position, Position), Token?)? = None
  let mut last_shifted_state_stack = state_stack
  while true {
    let decision = match state(EOI) {
      ReduceNoLookahead(_) | Accept as t => t
      _ =>
        match lookahead {
          Some(la) => state(la.0)
          None =>
            if cursor < tokens.length() {
              let (token, start_pos, end_pos) = tokens[cursor]
              cursor += 1
              let (symbol, data) = yy_input(token, start_pos, end_pos)
              lookahead = Some(
                (symbol, (data, start_pos, end_pos), Some(token)),
              )
              state(symbol)
            } else {
              lookahead = Some((EOI, (YYObj_Void, last_pos, last_pos), None))
              state(EOI)
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
      | ReduceNoLookahead(count, symbol, action) =>
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
              | ReduceNoLookahead(count, symbol, action) =>
                continue (count, symbol, action)
              _ => panic()
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

///|
fn error(
  stack : @list.List[YYState],
  token : Token?,
  loc : (Position, Position),
) -> Unit raise ParseError {
  let expected = []
  fn try_add(symbol : YYSymbol, kind : TokenKind) {
    fn go(stack : @list.List[YYState]) {
      match stack {
        Empty => ()
        More(state, ..) =>
          match state(symbol) {
            Accept | Shift(_) => expected.push(kind)
            Reduce(count, symbol, _) | ReduceNoLookahead(count, symbol, _) => {
              fn inner_go(stack : @list.List[YYState], count, symbol) {
                let stack = stack.drop(count)
                guard stack is More(state, ..)
                match state(symbol) {
                  Shift(state) => go(@list.cons(state, stack))
                  Reduce(count, symbol, _)
                  | ReduceNoLookahead(count, symbol, _) =>
                    inner_go(stack, count, symbol)
                  _ => panic()
                }
              }

              inner_go(stack, count, symbol)
            }
            Error => ()
          }
      }
    }

    go(stack)
  }

  for
    term in (
      [
        (T_LEFT_PARENTHESIS, TK_LEFT_PARENTHESIS),
        (T_RIGHT_PARENTHESIS, TK_RIGHT_PARENTHESIS),
        (T_LEFT_CURLY_BRACE, TK_LEFT_CURLY_BRACE),
        (T_RIGHT_CURLY_BRACE, TK_RIGHT_CURLY_BRACE),
        (T_LEFT_SQUARE_BRACKET, TK_LEFT_SQUARE_BRACKET),
        (T_RIGHT_SQUARE_BRACKET, TK_RIGHT_SQUARE_BRACKET),
        (T_LESS_THAN_SIGN, TK_LESS_THAN_SIGN),
        (T_GREATER_THAN_SIGN, TK_GREATER_THAN_SIGN),
        (T_SOLIDUS, TK_SOLIDUS),
        (T_DICT_BEGIN, TK_DICT_BEGIN),
        (T_DICT_END, TK_DICT_END),
        (T_NULL, TK_NULL),
        (T_TRUE, TK_TRUE),
        (T_FALSE, TK_FALSE),
        (T_INTEGER, TK_INTEGER),
        (T_REAL, TK_REAL),
        (T_STRING, TK_STRING),
        (T_NAME, TK_NAME),
        (T_INDIRECT, TK_INDIRECT),
        (T_EOF, TK_EOF),
      ] : Array[(YYSymbol, TokenKind)]) {
    try_add(term.0, term.1)
  }
  match token {
    None => raise UnexpectedEndOfInput(loc.1, expected)
    Some(token) => raise UnexpectedToken(token, loc, expected)
  }
}

///|
pub fn parse(
  tokens : Array[(Token, Position, Position)],
  initial_pos? : Position,
) -> Object raise ParseError {
  yy_parse(
    tokens,
    yy_state_0,
    it => {
      guard it is YYObj_Object(result)
      result
    },
    initial_pos?,
  )
}
