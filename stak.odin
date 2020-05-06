package main;

import "core:fmt";
import "core:strings";
import "core:os";


lexer: Lexer;

main :: proc() {

  // scratch();
  // os.exit(0);

  // test_lex(&lexer);
  // os.exit(0);

  filename := "./test.stak";
  file_bytes, success := os.read_entire_file("./test.stak");

  if !success {
	  fmt.println("Could not open source file");
	  os.exit(1);
  }

  // TODO(josh): a whole copy just to insert a null terminator?  okay . . .
  // maybe we can just write our own read_entire_file function instead.  
  // or even memory mapped file?  That sounds fun
  source_stream := make([]byte, len(file_bytes) + 1);
  copy(source_stream, file_bytes);
  source_stream[len(file_bytes)] = 0;


  init_lexer(&lexer, source_stream, filename);
  ast : ^Ast = parse_program(&lexer);
  
  sb := strings.make_builder();
  defer strings.destroy_builder(&sb);
  print_ast(&sb, ast);
  fmt.print(strings.to_string(sb));


}