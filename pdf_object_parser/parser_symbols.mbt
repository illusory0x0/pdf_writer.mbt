///|
/// parser symbol include terminals and non-terminals
/// 
/// terminal symbols are called `Token` in lexer
/// 
/// here we make MoonBit type corresponding to parser symbol names for simplicity
/// 
///

///|
/// terminal symbols
/// 
///

///|
/// Terminal symbol: Left parenthesis '('
type LEFT_PARENTHESIS

///|
/// Terminal symbol: Right parenthesis ')'
type RIGHT_PARENTHESIS

///|
/// Terminal symbol: Left curly brace '{'
type LEFT_CURLY_BRACE

///|
/// Terminal symbol: Right curly brace '}'
type RIGHT_CURLY_BRACE

///|
/// Terminal symbol: Left square bracket '['
type LEFT_SQUARE_BRACKET

///|
/// Terminal symbol: Right square bracket ']'
type RIGHT_SQUARE_BRACKET

///|
/// Terminal symbol:  
struct INDIRECT {
  object_num : Int
  generation_num : Int
} derive(Show, Eq)

///|
/// Terminal symbol: Less than sign '<'
type LESS_THAN_SIGN

///|
/// Terminal symbol: Greater than sign '>'
type GREATER_THAN_SIGN

///|
/// Terminal symbol: Solidus '/'
type SOLIDUS

///|
/// Terminal symbol: Dictionary begin marker
type DICT_BEGIN

///|
/// Terminal symbol: Dictionary end marker
type DICT_END

///|
/// Terminal symbol: Boolean true literal
type TRUE

///|
/// Terminal symbol: Boolean false literal
type FALSE

///|
/// Terminal symbol: End of file marker
type EOF

///|
/// Non-terminal symbol: Object represented as Atom
typealias Object as Atom

///|
/// Terminal symbol: Null value literal
type NULL

///|
/// Non-terminal symbol: Integer represented as Int
typealias Int as INTEGER

///|
/// Non-terminal symbol: Real number represented as Double
typealias Double as REAL

///|
/// Non-terminal symbol: String represented as Bytes
typealias Bytes as STRING

///|
/// Non-terminal symbol: Name represented as Bytes
typealias Bytes as NAME

///|
typealias Array[Atom] as NonEmptyElems

///|
typealias Object as PDF_Array

///|
typealias Object as PDF_Dict

///|
typealias Array[(NAME, Object)] as DictEntries

///|
typealias Object as PDF_Obj

///|
typealias Bytes as STREAM_BYTES
