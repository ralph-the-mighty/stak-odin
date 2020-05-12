package main;
import "core:os";
import "core:fmt";



TokenKind :: enum {
  NUMBER,
  //keyword tokens
  VAR,
  IF,
  ELSE,
  WHILE,
  FUN,
  PRINT,
	NAME,

	//mul associativity
  FIRST_BINARY_OP,
	MUL = FIRST_BINARY_OP,
	DIV,
	MOD,
	AND,
	//add associativity
	PLUS,
	MINUS,
	OR,
	XOR,
	//cmp associativity
	LT,
	GT,
	LTE,
	GTE,
  EQ,
  NEQ,

	OR_OR,
	AND_AND,
  LAST_BINARY_OP = AND_AND,
	
  
  ASSIGN,
	NOT,
	BIT_NOT,

	//grouping tokens
	LPAREN,
	RPAREN,
	LBRACE,
	RBRACE,
  LBRACKET,
  RBRACKET,
	COMMA,	
  SEMICOLON,
	EOF,
};

@static
token_to_string := map[TokenKind]string {
  .NUMBER = "int",
	.NAME = "name",
  .WHILE = "while",
  .PRINT = "print",
  .VAR = "var",
  .IF = "if",
  .ELSE = "else",
  .FUN = "fun",
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
	.LBRACE = "{",
	.RBRACE = "}",
  .LBRACKET = "[",
  .RBRACKET = "]",
	.COMMA = ",",
  .SEMICOLON = ";",
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

@static
name_to_kind := map[string]TokenKind {
  "while" = .WHILE,
  "if" = .IF,
  "else" = .ELSE,
  "var" = .VAR,
  "fun" = .FUN,
  "print" = .PRINT
};


scan_identifier :: proc(using l: ^Lexer)  {
    start := index;
    token.loc_start = l.loc;
    //alphnum
    for isalnum(stream[index]) {
      advance(l);
    }
    name := string(stream[start:index]);
    kind, ok := name_to_kind[name];
    if ok {
      token.kind = kind;
    } else {
      token.kind = .NAME;
    }
    token.stringval = name;
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
  fmt.printf("%s(%d, %d): Parse Error: %s", filename, line_number, column, msg);
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
    case ';':
      set_token(l, .SEMICOLON);
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



expect_token :: proc(l: ^Lexer, kind: TokenKind) -> Token {
  t: Token;
  if(l.token.kind == kind) {
    t = l.token;
    next_token(l);
  } else {
    parse_error(l, fmt.tprintf("Expected '%s', but found '%s'", 
                                    token_to_string[kind], 
                                    token_to_string[l.token.kind]),
                                    l.token.loc_start);
  }
  return t;
}

match_token :: proc(l: ^Lexer, kind: TokenKind) -> bool {
  if l.token.kind == kind {
    next_token(l);
    return true;
  }
  return false;
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
  } else if match_token(l, .LPAREN) {
    node = parse_expr(l);
    expect_token(l, .RPAREN);
  } else {
    parse_error_here(l,
      fmt.tprintf("trying to parse expression value (only numbers allowed atm) and found '%s' token", token_to_string[l.token.kind]));
  }
  return node;
}

parse_expr_unary :: proc(l: ^Lexer) -> ^Expr {
  expr: ^Expr;
  if(l.token.kind == .PLUS || l.token.kind == .MINUS) {
    expr = new(Expr);
    op := token_to_op[l.token.kind];
    next_token(l);
    expr.kind = ExprUnary{op, parse_expr_unary(l)};
  } else {
    expr = parse_expr_val(l);
  }
  return expr;
}


@static
token_to_op := map[TokenKind]Operator{
  .MUL = .MUL,
	.DIV = .DIV,
 	.MOD = .MOD,
	.AND = .AND,
  .PLUS = .PLUS,
	.MINUS = .MINUS,
	.OR = .OR,
	.XOR = .XOR,
	.LT = .LT,
	.GT = .GT,
	.LTE = .LTE,
	.GTE = .GTE,
	.EQ = .EQ,
	.NEQ = .NEQ,
	.OR_OR = .OR_OR,
	.AND_AND = .AND_AND,
	.NOT = .NOT,
	.BIT_NOT = .BIT_NOT,
};


@static
precedence_table := map[TokenKind]int{
  
  .MUL     = 5,
  .DIV     = 5,
  .AND     = 5,
  .MOD     = 5,
  
  .PLUS    = 4,
  .MINUS   = 4,
  .OR      = 4,
  .XOR     = 4,

  .LT      = 3,
  .LTE     = 3,
  .GT      = 3,
  .GTE     = 3,
  .EQ      = 3,
  .NEQ     = 3,
  .AND_AND = 2,
  .OR_OR   = 1
};


is_binary_op :: proc(kind: TokenKind) -> bool {
  return kind >= .FIRST_BINARY_OP && kind <= .LAST_BINARY_OP;
}


parse_expr_binary :: proc(l: ^Lexer, precedence := -999) -> ^Expr {
  expr := parse_expr_unary(l);
  for is_binary_op(l.token.kind) && (precedence_table[l.token.kind] >= precedence) {
    prec := precedence_table[l.token.kind];
    lhs := expr;
    op := token_to_op[l.token.kind];
    next_token(l);
    rhs := parse_expr_binary(l, prec);
    expr = new(Expr);
    expr.kind = ExprBinary{op, lhs, rhs};
  }
  return expr;
}


parse_expr :: proc(l: ^Lexer) -> ^Expr {
  return parse_expr_binary(l);
}



parse_stmt :: proc(l: ^Lexer) -> ^Stmt {
  stmt := new(Stmt);
  if match_token(l, .PRINT) {
    stmt.kind = StmtPrint{rhs = parse_expr(l)}; 
    expect_token(l, .SEMICOLON);
  } else if match_token(l, .IF) {
    cond := parse_expr(l);
    
    expect_token(l, .LBRACE);
    if_body := parse_block(l);
    expect_token(l, .RBRACE);

    else_body: ^StmtBlock;
    if(match_token(l, .ELSE)) {
      expect_token(l, .LBRACE);
      else_body = parse_block(l);
      expect_token(l, .RBRACE);
    }
    stmt.kind = StmtIf{cond, if_body, else_body};
  } else {
    panic("Not Implemented!");
  }
  return stmt;
}


parse_block :: proc(l: ^Lexer) -> ^StmtBlock {
  block := new(StmtBlock);
  for l.token.kind != .RBRACE && l.token.kind != .EOF {
    append_elem(&block.stmts, parse_stmt(l));
  }
  return block;
}


parse_decl_var :: proc(l: ^Lexer) -> ^Decl {
  decl := new(Decl);
  name := expect_token(l, .NAME).stringval;

  initializer: ^Expr;
  if(match_token(l, .ASSIGN)) {
    initializer = parse_expr(l);
  }
  expect_token(l, .SEMICOLON);
  decl.kind = DeclVar{name, initializer};
  return decl;
}

parse_decl_fun ::proc(l: ^Lexer) -> ^Decl {
  decl := new(Decl);
  name := expect_token(l, .NAME).stringval;
  expect_token(l, .LPAREN);
  expect_token(l, .RPAREN);

  
  body: ^StmtBlock;
  if(match_token(l, .LBRACE)) {
    body = parse_block(l);
    expect_token(l, .RBRACE);
  }
  decl.kind = DeclFun{name, body};
  return decl;
}


parse_decl :: proc(l: ^Lexer) -> ^Decl {
  decl: ^Decl;
  if(match_token(l, .VAR)) {
    decl = parse_decl_var(l);
  } else if(match_token(l, .FUN)) {
    decl = parse_decl_fun(l);
  } else {
    parse_error(l, "Only global variables and function declarations are allowed at the top level", l.token.loc_start);
  }
  return decl;
}


parse_program :: proc(l: ^Lexer) -> ^Ast {
  ast := new(Ast);
  for l.token.kind != .EOF {
    append_elem(&ast.decls, parse_decl(l));
  }
  expect_token(l, TokenKind.EOF);
  return ast;
}