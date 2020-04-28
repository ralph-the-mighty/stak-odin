package main;
import "core:fmt";
import "core:os";



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

Token :: struct {
  kind: TokenKind,
  stringval: string,
  intval: int
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


parse_error :: proc(l: ^Lexer, msg: string) {
  fmt.println(msg);
  os.exit(1);
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
      parse_error(l, "Illegal Token!");
  }
}



expect_token :: proc(l: ^Lexer, kind: TokenKind) {
  if(l.token.kind == kind) {
    next_token(l);
  } else {
    parse_error(l, "Expected token of one type, but got a different type!");
  }
}


peek_token :: proc(l: ^Lexer) -> Token {
  copy := l;
  next_token(copy);
  return copy.token;
}


parse_expr_val :: proc(l: ^Lexer) -> ^Expr {
  node := new(Expr);
  if l.token.kind == .NUMBER {
    node.kind = ExprNumber{val = l.token.intval};
    next_token(l);
  } else if l.token.kind == .LPAREN {
    next_token(l);
    node = parse_expr(l);
    expect_token(l, .RPAREN);
  } else {
    parse_error(l, "Only parsing number vals at the moment");
  }
  return node;
}




parse_expr_mul :: proc(l: ^Lexer) -> ^Expr {
  expr := parse_expr_val(l);
  for l.token.kind == .MUL || l.token.kind == .DIV {
    lhs := expr;
    op : Operator;
    if(l.token.kind == .MUL) {
      next_token(l);
      op = .MUL;
    } else {
      assert(l.token.kind == .DIV);
      next_token(l);
      op = .DIV;
    }
    rhs := parse_expr_val(l);
    expr = new(Expr);
    expr.kind = ExprBinary{op, lhs, rhs};
  }
  return expr;
}



parse_expr_plus :: proc(l: ^Lexer) -> ^Expr {
  expr := parse_expr_mul(l);
  for l.token.kind == .PLUS || l.token.kind == .MINUS {
    
    lhs := expr;
    op : Operator;

    if(l.token.kind == .PLUS) {
      next_token(l);
      op = .PLUS;
    } else {
      assert(l.token.kind == .MINUS);
      next_token(l);
      op = .MINUS;
    }
    rhs := parse_expr_mul(l);
    expr = new(Expr);
    expr.kind = ExprBinary{op, lhs, rhs};
  }
  return expr;
}


parse_expr :: proc(l: ^Lexer) -> ^Expr {
  return parse_expr_plus(l);
}


parse_program :: proc(l: ^Lexer) -> ^Expr {
  expr := parse_expr(l);
  expect_token(l, TokenKind.EOF);
  return expr;
}





print_stmt :: proc(node: ^Stmt) {
  panic("Not Implemented!");
}



@static
operator_to_string := map[Operator]string{
  .PLUS = "+",
  .MINUS = "-",
  .MUL = "*",
  .DIV = "/"
};

print_expr :: proc(node: ^Expr) {
  switch kind in node.kind {
    case ExprBinary:
      fmt.print("(");
      fmt.printf("%s ", operator_to_string[kind.op]);
      print_expr(kind.lhs);
      fmt.print(" ");
      print_expr(kind.rhs);
      fmt.print(")");
    case ExprNumber:
      fmt.print(kind.val);
    case:
      fmt.println(node);
      panic("Not implemented!");
  }
}


print_node :: proc(node: ^AstNode) {
  switch kind in &node.kind {
    case Expr:
      print_expr(kind);
    case Stmt:
      print_stmt(kind);
    case:
      panic("Not Implemented!");
  }
}
