package main;

import "core:mem";
import "core:fmt";
import "core:strings";
import "core:os";



assert_token :: proc(l: ^Lexer, kind: TokenKind) {
  assert(l.token.kind == kind);
  next_token(l);
}

assert_num :: proc(l: ^Lexer, i: int) {
  assert(l.token.kind == .NUMBER && l.token.intval == i);
  next_token(l);
}

assert_string :: proc(l: ^Lexer, s: string) {
  assert(l.token.kind == .NAME && s == l.token.stringval);
  next_token(l);
}



test_lex :: proc(l: ^Lexer) {
  file_bytes, success := os.read_entire_file("./test1.stak");
  if !success {
	  fmt.println("Could not open source file");
	  os.exit(1);
  }
  // NOTE(josh): a whole copy just to insert a null terminator?  okay . . .
  // maybe we can just write our own read_entire_file function instead.  
  // or even memory mapped file?  That sounds fun
  source_stream := make([]byte, len(file_bytes) + 1);
  defer delete(source_stream);
  copy(source_stream, file_bytes);
  source_stream[len(file_bytes)] = 0;


  init_lexer(l, source_stream, "./test1.stak");
  assert_string(l, "fun");
  assert_string(l, "factorial");
  assert_token(l, .LPAREN);
  assert_string(l, "n");
  assert_token(l, .RPAREN);
  assert_token(l, .LBRACE);
  assert_string(l, "if");
  assert_token(l, .LPAREN);
  assert_string(l, "n");
  assert_token(l, .LTE);
  assert_num(l, 1);
  assert_token(l, .SEMICOLON);
  assert_token(l, .RPAREN);
  assert_token(l, .LBRACE);
  assert_string(l, "return");
  assert_num(l, 1);
  assert_token(l, .RBRACE);
  assert_string(l, "else");
  assert_token(l, .LBRACE);
  assert_string(l, "return");
  assert_string(l, "factorial");
  assert_token(l, .LPAREN);
  assert_string(l, "n");
  assert_token(l, .MINUS);
  assert_num(l, 1);
  assert_token(l, .RPAREN);
  assert_token(l, .SEMICOLON);
  assert_token(l, .RBRACE);
  assert_token(l, .RBRACE);
  assert_token(l, .EOF);
}