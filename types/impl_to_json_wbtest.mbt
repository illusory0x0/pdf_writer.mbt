///|
test "ToJson for GraphicOperator" {
  let op1 = Op_w(1.5)
  let json1 = op1.to_json()
  @json.inspect(json1, content={ "op": "w", "width": 1.5 })
  let op2 = Op_Tj(b"Hello World")
  let json2 = op2.to_json()
  @json.inspect(json2, content={ "op": "Tj", "text": "Hello World" })
  let op3 = Op_q
  let json3 = op3.to_json()
  @json.inspect(json3, content={ "op": "q" })
}

///|
test "ToJson for File" {
  let file = File::{
    major: 1,
    minor: 7,
    objects: [Object::Null, Object::Boolean(true)],
    trailer: Object::Dictionary([]),
  }
  let json = file.to_json()
  @json.inspect(json, content={
    "major": 1,
    "minor": 7,
    "objects": ["Null", ["Boolean", true]],
    "trailer": ["Dictionary", []],
  })
}

///|
test "ToJson for TransformMatrix" {
  let matrix = TransformMatrix::{
    a: 1.0,
    b: 0.0,
    c: 0.0,
    d: 1.0,
    e: 0.0,
    f: 0.0,
  }
  let json = matrix.to_json()
  @json.inspect(json, content={
    "a": 1.0,
    "b": 0.0,
    "c": 0.0,
    "d": 1.0,
    "e": 0.0,
    "f": 0.0,
  })
}

///|
test "ToJson for ContentStream" {
  let stream = ContentStream([Op_q, Op_w(2.0), Op_Q])
  let json = stream.to_json()
  @json.inspect(json, content={
    "operators": [{ "op": "q" }, { "op": "w", "width": 2.0 }, { "op": "Q" }],
  })
}

///|
test "ToJson for StandardFont" {
  let font1 = TimesRoman
  let json1 = font1.to_json()
  @json.inspect(json1, content="Times-Roman")
  let font2 = HelveticaBold
  let json2 = font2.to_json()
  @json.inspect(json2, content="Helvetica-Bold")
  let font3 = CourierOblique
  let json3 = font3.to_json()
  @json.inspect(json3, content="Courier-Oblique")
}
