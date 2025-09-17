///|
enum Block {
  Heading(level~ : Int, text~ : String)
  Paragraph(Array[String])
  BlankLine
} derive(@json.FromJson, ToJson)

///|
struct FlatHeading {
  num : Array[Int]
  text : String
} derive(@json.FromJson, ToJson)

///|
struct Doc(Array[Block]) derive(@json.FromJson, ToJson)

///|
struct Content(Array[@pdf.GraphicOperator])

///|
fn Content::iter(xs : Self) -> Iter[@pdf.GraphicOperator] {
  xs.0.iter()
}
