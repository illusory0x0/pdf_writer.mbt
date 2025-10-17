import * as cp from "node:child_process";


let result = null 

result = cp.execSync("moon run codegen_pdf_object_parser")
console.log(result.toString())

result = cp.execSync(".mooncakes/moonbitlang/yacc/moonyacc --mode only-tokens ./pdf_object_parser/parser.mbty -o ./pdf_object_parser/token.mbt")
console.log(result.toString())


result = cp.execSync(".mooncakes/moonbitlang/yacc/moonyacc --no-comments --external-tokens ./pdf_object_parser/parser.mbty -o ./pdf_object_parser/parser.mbt")
console.log(result.toString())

cp.execSync("moonfmt -w ./pdf_object_parser/token.mbt")

cp.execSync("moonfmt -w ./pdf_object_parser/parser.mbt")


// process.run