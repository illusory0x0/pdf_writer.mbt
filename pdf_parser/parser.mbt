///|
/// Main parser function that converts raw PDF bytes to a structured PDF file
pub fn parse(input : BytesView) -> @pdf.File raise {
  // Step 1: Use pdf_file_lexer to tokenize the entire PDF file structure
  let file_result = @pdf_file_lexer.tokenize_file(input) // Let LexError propagate
  let pdf_file = file_result.value

  // Step 2: Parse each object in the body using pdf_object_parser
  let parsed_objects = []
  for obj in pdf_file.body {
    let parsed_obj = parse_pdf_object(obj.obj_bytes) // Let ParseError propagate
    parsed_objects.push(parsed_obj)
  }

  // Step 3: Parse the trailer dictionary
  let trailer_dict = parse_pdf_object(pdf_file.trailer)

  // Step 4: Construct the final @pdf.File structure
  @pdf.File::{
    major: pdf_file.header.major,
    minor: pdf_file.header.minor,
    objects: parsed_objects,
    trailer: trailer_dict,
  }
}

///|
/// Parse a PDF object from its byte representation
fn parse_pdf_object(obj_bytes : BytesView) -> @pdf.Object raise {
  // TODO: 
  // lexmatch might has some bug, here use `to_bytes()` as a workaround
  let tokens = @pdf_object_parser.tokenize(obj_bytes.to_bytes())

  // Parse the tokens using the PDF object parser
  let parsed_obj = @pdf_object_parser.parse(tokens) // Let ParseError propagate
  parsed_obj
}
