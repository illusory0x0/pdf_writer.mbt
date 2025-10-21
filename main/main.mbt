///|
fn main {
  let args = @sys.get_cli_args()
  let path = args[1]
  let input = try! @fs.read_file_to_bytes(path)
  let result = try! @pdf_parser.parse(input)
  ignore(result)
}
