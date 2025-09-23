///|
test "Block::from_list_item with simple paragraph" {
  let md_str = "- Simple item"
  let doc = @cmark.Doc::from_string(md_str)
  let block = doc.block
  let block = Block::from_cmark(block)
  @json.inspect(block, content=[
    "List",
    [["Paragraph", [["Plain", "Simple item"]]]],
  ])
}

///|
test "Block::from_list_item with simple paragraph" {
  let md_str =
    #| - hello
    #| - world
  let doc = @cmark.Doc::from_string(md_str)
  let block = doc.block
  let block = Block::from_cmark(block)
  @json.inspect(block, content=[
    "List",
    [["Paragraph", [["Plain", "hello"]]], ["Paragraph", [["Plain", "world"]]]],
  ])
}
