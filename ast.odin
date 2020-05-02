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

StmtIf :: struct {
  condition: ^Expr,
  if_body: ^StmtBlock,
  else_body: ^StmtBlock
}

StmtAssign :: struct {
  ident: string,
  rhs: ^Expr
}

StmtBlock :: struct {
  stmts: [dynamic]^Stmt
}


Stmt :: struct {
  kind: union {
    StmtPrint,
    StmtAssign,
    StmtBlock,
    StmtIf
  }
}


DeclFun :: struct {
  name: string,
  body: ^StmtBlock
}


DeclVar :: struct {
  name: string,
  initializer: ^Expr
}


Decl :: struct {
  kind: union {
    DeclFun,
    DeclVar
  }
}



Ast :: struct {
  decls: [dynamic]^Decl
}
