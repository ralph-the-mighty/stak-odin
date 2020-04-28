package main;

import "core:fmt";
import "core:strings";
import "core:os";
import "core:mem";


//string interning
interned : [dynamic]string;


intern_string :: proc(s: string) -> string {
  for it in interned {
    if len(it) == len(s) && strings.compare(it, s) == 0 {
      return it;
    }
  }
  cloned := strings.clone(s);
  append(&interned, cloned);
  return cloned;
}



lexer: Lexer;

main :: proc() {

  // scratch();
  // os.exit(1);

  // test_lex(&lexer);
  // os.exit(0);

  filename := "./test.stak";
  file_bytes, success := os.read_entire_file("./test.stak");

  if !success {
	  fmt.println("Could not open source file");
	  os.exit(1);
  }

  // NOTE(josh): a whole copy just to insert a null terminator?  okay . . .
  // maybe we can just write our own read_entire_file function instead.  
  // or even memory mapped file?  That sounds fun
  source_stream := make([]byte, len(file_bytes) + 1);
  copy(source_stream, file_bytes);
  source_stream[len(file_bytes)] = 0;


  init_lexer(&lexer, source_stream, filename);
  ast : ^Expr = parse_program(&lexer);
  print_expr(ast);


}