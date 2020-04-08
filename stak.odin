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



 TokenKind :: enum {
	NUMBER,
	NAME,

	//mul associativity
	FIRST_MUL,
	MUL = FIRST_MUL,
	DIV,
	MOD,
	AND,
	LAST_MUL = AND,


	//add associativity
	FIRST_ADD,
	PLUS = FIRST_ADD,
	MINUS,
	OR,
	XOR,
	LAST_ADD = XOR,

	//cmp associativity
	FIRST_CMP,
	LT = FIRST_CMP,
	GT,
	LTE,
	GTE,
	EQ,
	NEQ,
	LAST_CMP = NEQ,

	OR_OR,
	AND_AND,
	ASSIGN,
	NOT,
	BIT_NOT,

	//grouping tokens
	LPAREN,
	RPAREN,
	LBRACE,
	RBRACE,
	COMMA,
	
	EOF,
};

//lexing
when false {
  Token :: struct {
    kind: TokenKind,
    using _ : struct #raw_union {
      stringval: string,
      intval: int
    }
  }
} else {
  Token :: struct {
    kind: TokenKind,
    stringval: string,
    intval: int
  }
}



Lexer :: struct {
  index: int,
  stream: []byte,
  token: Token,
}


init_lexer :: proc(l: ^Lexer, stream: []byte) {
  l.stream = stream;
  l.index = 0;
  next_token(l);
}


isalnum :: proc(character: byte) -> bool {
  return (character >= '0' && character <= '9') ||
         (character >= 'A' && character <= 'Z') ||
         (character >= 'a' && character <= 'z');
}


iswhitespace :: proc(character: byte) -> bool {
  switch(character) {
    case ' ', '\n', '\r', '\t', '\f', '\v':
      return true;
  }
  return false;
}


scan_identifier :: proc(using l: ^Lexer)  {
    start := index;
    //alphnum
    token.kind = .NAME;
    for isalnum(stream[index]) {
      index += 1;
    }
    token.stringval = intern_string(string(stream[start:index]));
}


@static
digit_table := map[byte]int{
  '0' = 0,
  '1' = 1,
  '2' = 2,
  '3' = 3,
  '4' = 4,
  '5' = 5,
  '6' = 6,
  '7' = 7,
  '8' = 8,
  '9' = 9,
  'a' = 10, 'A' = 10,
  'b' = 11, 'B' = 11,
  'c' = 12, 'C' = 12,
  'd' = 13, 'D' = 13,
  'e' = 14, 'E' = 14,
  'f' = 15, 'F' = 15
};

scan_int :: proc(using l: ^Lexer) {
  token.kind = .NUMBER;
	val := 0;
	base := 10;
	if (stream[index] == '0') {
		index += 1;
		if (stream[index] == 'x' || stream[index] == 'X') {
			//hexadecimal
			base = 16;
      index += 1;
		} else if (stream[index] == 'b' || stream[index] == 'B') {
      //binary
			base = 2;
      index += 1;
		}
	}

	for {
    digit, ok := digit_table[stream[index]];
    if !ok do break;
		if (digit >= base) {
			fmt.printf("malformed integer: expected base %d, but got digit %c", base, stream[index]);
      os.exit(1);
		}
		val *= base;
		val += digit;
    index += 1;
	}
	token.intval = val;
}


next_token :: proc(using l: ^Lexer) {

  //skip whitespace
  for iswhitespace(stream[index]) {
    index += 1;
  }



  switch(stream[index]) {
    case 'A'..'Z', 'a'..'z':
      scan_identifier(l);
    case '0'..'9':
      scan_int(l);
    case 0:
      token.kind = .EOF;
      token.intval = 0;
    case '+':
      token.kind = .PLUS;
      index += 1;
    case '-':
      token.kind = .MINUS;
      index += 1;
    case '*':
      token.kind = .MUL;
      index += 1;
    case '/':
      token.kind = .DIV;
      index += 1;
    case '%':
      token.kind = .MOD;
      index += 1;
    case '^':
      token.kind = .XOR;
      index += 1;
    case '~':
      token.kind = .BIT_NOT;
      index += 1;
    case '(':
      token.kind = .LPAREN;
      index += 1;
    case ')':
      token.kind = .RPAREN;
      index += 1;
    case '{':
      token.kind = .LBRACE;
      index += 1;
    case '}':
      token.kind = .RBRACE;
      index += 1;
    case ',':
      token.kind = .COMMA;
      index += 1;
    case '!':
      if stream[index + 1] == '=' {
        token.kind = .NEQ;
        index += 2;
      } else {
        token.kind = .NOT;
        index += 1;
      }
    case '<':
      if stream[index + 1] == '=' {
        token.kind = .LTE;
        index += 2;
      } else {
        token.kind = .LT;
        index += 1;
      }
    case '>':
      if stream[index + 1] == '=' {
        token.kind = .GTE;
        index += 2;
      } else {
        token.kind = .GT;
        index += 1;
      }
    case '=':
      if stream[index + 1] == '=' {
        token.kind = .EQ;
        index += 2;
      } else {
        token.kind = .ASSIGN;
        index += 1;
      }
    case '&':
      if stream[index + 1] == '&' {
        token.kind = .AND;
        index += 2;
      } else {
        token.kind = .AND_AND;
        index += 1;
      }
    case '|':
      if stream[index + 1] == '|' {
        token.kind = .OR_OR;
        index += 2;
      } else {
        token.kind = .OR;
        index += 1;
      }
    case:
      fmt.println("ILLEGAL TOKEN");
      os.exit(1);
  }
}

lexer: Lexer;

main :: proc() {

  test_lex(&lexer);
  os.exit(0);

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


  init_lexer(&lexer, source_stream);

  for lexer.token.kind != TokenKind.EOF {
    fmt.println(lexer.token);
    next_token(&lexer);
  }
  fmt.println(interned);
}