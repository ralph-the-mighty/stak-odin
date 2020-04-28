package main;


Operator :: enum {
  PLUS,
  MINUS,
  MUL,
  DIV
}




ExprNumber :: struct {
  val: int,
}
  
ExprString :: struct {
  val: string,
}

ExprBinary :: struct {
  op: Operator,
  lhs: ^Expr,
  rhs: ^Expr
}

ExprUnary :: struct {
  op: Operator,
  child: ^Expr
}


Expr :: struct {
  kind: union {
    ExprNumber,
    ExprString,
    ExprBinary,
    ExprUnary
  }
}


StmtPrint :: struct {
  rhs: ^Expr
}

StmtDecl :: struct {
  ident: string
}

StmtAssign :: struct {
  ident: string,
  rhs: ^Expr
}



Stmt :: struct {
  kind: union {
    StmtPrint,
    StmtDecl,
    StmtAssign
  }
}



AstNode :: struct {
  kind: union {
    Expr,
    Stmt
  }
}
