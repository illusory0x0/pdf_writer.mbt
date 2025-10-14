build:
  moon test 
  .mooncakes/moonbitlang/yacc/moonyacc --mode only-tokens ./pdf_object_parser/parser.mbty -o ./pdf_object_parser/token.mbt && moonfmt -w ./pdf_object_parser/token.mbt
  .mooncakes/moonbitlang/yacc/moonyacc --no-comments --external-tokens ./pdf_object_parser/parser.mbty -o ./pdf_object_parser/parser.mbt && moonfmt -w ./pdf_object_parser/parser.mbt

fmt-json:
    fd moon.mod.json -x npx prettier --write {}
    fd moon.pkg.json -x npx prettier --write {}

soft-link-system-prompt:
  ln -s ../system-prompt/Agents.mbt.md moonbit-system-prompt.md   
   