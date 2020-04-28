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

@static
token_to_string := map[TokenKind]string {
  .NUMBER = "int",
	.NAME = "name",
	.MUL = "*",
	.DIV = "/",
	.MOD = "%",
	.AND = "&",
	.PLUS = "+",
	.MINUS = "-",
	.OR = "|",
	.XOR = "^",
	.LT = "<",
	.GT = ">",
	.LTE = "<=",
	.GTE = ">=",
	.EQ = "==",
	.NEQ = "!=",
	.OR_OR = "||",
	.AND_AND = "&&",
	.ASSIGN = "=",
	.NOT = "!",
	.BIT_NOT = "~",
	.LPAREN = "(",
	.RPAREN = ")",
	.LBRACE = "[",
	.RBRACE = "]",
	.COMMA = ",",
	.EOF = "EOF"
};

//lexing


Loc :: struct {
  line_number: uint,
  column: uint,
  filename: string
}


Token :: struct {
  kind: TokenKind,
  stringval: string,
  intval: int,
  loc_start: Loc,
  loc_end: Loc
}





Lexer :: struct {
  index: uint,
  stream: []byte,
  token: Token,

  loc: Loc
}


init_lexer :: proc(l: ^Lexer, stream: []byte, filename: string) {
  l.stream = stream;
  l.loc = Loc{filename = filename, line_number = 1};
  l.index = 0;
  next_token(l);
}

advance :: proc(l: ^Lexer, amount: uint = 1) {
  l.index += amount;
  l.loc.column += amount;

  if l.stream[l.index] == '\r' && l.stream[l.index + 1] == '\n' { //TODO(josh): generalize this, add tabs, etc
    l.index += 2;
    l.loc.column = 0;
    l.loc.line_number += 1;
  } else if l.stream[l.index] == '\n' {
    l.index += 1;
    l.loc.column = 0;
    l.loc.line_number += 1;
  }
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
    token.loc_start = l.loc;
    //alphnum
    token.kind = .NAME;
    for isalnum(stream[index]) {
      advance(l);
    }
    token.stringval = intern_string(string(stream[start:index]));
    token.loc_end = l.loc;
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
  token.loc_start = l.loc;
  token.kind = .NUMBER;
	val := 0;
	base := 10;
	if (stream[index] == '0') {
		advance(l);
		if (stream[index] == 'x' || stream[index] == 'X') {
			//hexadecimal
			base = 16;
      advance(l);
		} else if (stream[index] == 'b' || stream[index] == 'B') {
      //binary
			base = 2;
      advance(l);
		}
	}

	for {
    digit, ok := digit_table[stream[index]];
    if !ok do break;
		if (digit >= base) {
			parse_error_here(l, fmt.tprintf("malformed integer: found character %c while parsing integer of base %d", stream[index], base));
      os.exit(1);
		}
		val *= base;
		val += digit;
    advance(l);
	}
	token.intval = val;
  token.loc_end = l.loc;
}


parse_error_here :: proc(l: ^Lexer, msg: string) {
  parse_error(l, msg, l.loc);
}


parse_error :: proc(l: ^Lexer, msg: string, using loc: Loc) {
  fmt.printf("%s(%d, %d): parse error: %s", filename, line_number, column, msg);
  os.exit(1);
}



set_token :: proc(l: ^Lexer, kind: TokenKind, length: uint = 1) {
  l.token.kind = kind;
  l.token.loc_start = l.loc;
  advance(l, length);
  l.token.loc_end = l.loc;
}


next_token :: proc(using l: ^Lexer) {

  //skip whitespace
  for iswhitespace(stream[index]) {
    advance(l);
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
      set_token(l, .PLUS);
    case '-':
      set_token(l, .MINUS);
    case '*':
      set_token(l, .MUL);
    case '/':
      set_token(l, .DIV);
    case '%':
      set_token(l, .MOD);
    case '^':
      set_token(l, .XOR);
    case '~':
      set_token(l, .BIT_NOT);
    case '(':
      set_token(l, .LPAREN);
    case ')':
      set_token(l, .RPAREN);
    case '{':
      set_token(l, .LBRACE);
    case '}':
      set_token(l, .RBRACE);
    case ',':
      set_token(l, .COMMA);
    case '!':
      if stream[index + 1] == '=' {
        set_token(l, .NEQ, 2);
      } else {
        set_token(l, .NOT, 2);
      }
    case '<':
      if stream[index + 1] == '=' {
        set_token(l, .LTE, 2);
      } else {
        set_token(l, .LT);
      }
    case '>':
      if stream[index + 1] == '=' {
        set_token(l, .GTE, 2);
      } else {
        set_token(l, .GT);
      }
    case '=':
      if stream[index + 1] == '=' {
        set_token(l, .EQ, 2);
      } else {
        set_token(l, .ASSIGN);
      }
    case '&':
      if stream[index + 1] == '&' {
        set_token(l, .AND_AND, 2);
      } else {
        set_token(l, .AND);
      }
    case '|':
      if stream[index + 1] == '|' {
        set_token(l, .OR_OR, 2);
      } else {
        set_token(l, .OR);
      }
    case:
      parse_error_here(l, fmt.tprintf("Illegal Token: %c", stream[index]));
  }
}



expect_token :: proc(l: ^Lexer, kind: TokenKind) {
  if(l.token.kind == kind) {
    next_token(l);
  } else {
    parse_error(l, fmt.tprintf("Expected '%s', but found '%s'", 
                                    token_to_string[kind], 
                                    token_to_string[l.token.kind]),
                                    l.token.loc_start);
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
    parse_error_here(l, "Only parsing number vals at the moment");
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
