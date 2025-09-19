build:
  moon test 
  .mooncakes/moonbitlang/yacc/moonyacc --mode only-tokens parser.mbty -o tokens.mbt
  .mooncakes/moonbitlang/yacc/moonyacc --no-comments --external-tokens parser.mbty -o parser.mbt

fmt-json: 
    find . -name *.mod.json -exec npx prettier --write {} \;
    find . -name *.pkg.json -exec npx prettier --write {} \;
    