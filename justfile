build:
  node codegen_pdf_object_parser/main.mjs

fmt-json:
    fd moon.mod.json -x npx prettier --write {}
    fd moon.pkg.json -x npx prettier --write {}
   