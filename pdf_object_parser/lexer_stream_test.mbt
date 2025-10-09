///|
test {
  let input = b"<<\n  /Length 53\n>>\nstream\n 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\nendstream\n"
  let tokens = tokenize(input).map(triple => triple.0)
  inspect(
    tokens,
    content="[DICT_BEGIN, NAME(/Length), INTEGER(53), DICT_END, STREAM_BYTES( 1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\\n), EOF]",
  )
  let input = b"stream\n1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\nendstream"
  let tokens = tokenize(input).map(triple => triple.0)
  inspect(
    tokens,
    content="[STREAM_BYTES(1 0 0 1 50 770 cm BT /F0 36 Tf (Hello, World!) Tj ET\\n), EOF]",
  )
}
