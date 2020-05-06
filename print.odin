//print.odin
package main;
import "core:strings";
import "core:fmt";




indent_line :: proc(b: ^strings.Builder, depth: int) {
  for _ in 0..<(depth*2) {
    strings.write_byte(b, ' ');
  }
}


print_stmt :: proc(b: ^strings.Builder, stmt: ^Stmt, depth: int) {
  indent_line(b, depth);
  #partial switch kind in stmt.kind {
    case StmtPrint:
      fmt.sbprint(b, "print ");
      print_expr(b, kind.rhs);
    case StmtIf:
      fmt.sbprint(b, "if ");
      print_expr(b, kind.condition);
      fmt.sbprint(b, " {\n");
      print_block(b, kind.if_body, depth);
      indent_line(b, depth);
      fmt.sbprint(b, "}");
      if(kind.else_body != nil) {
        fmt.sbprint(b, " else {\n");
        print_block(b, kind.if_body, depth);
        indent_line(b, depth);
        fmt.sbprint(b, "}");
      }
    case:
      panic("Not Implemented!");
  }
  strings.write_byte(b, '\n');
}



@static
operator_to_string := map[Operator]string{
  .PLUS = "+",
  .MINUS = "-",
  .MUL = "*",
  .DIV = "/",
  .LT = "<",
  .LTE = "<=",
  .GT = ">",
  .GTE = ">=",
  .EQ = "=",
  .OR_OR = "||",
  .AND_AND = "&&",
  .EQ = "==",
  .NEQ = "!=",
  .AND = "&",
  .OR = "|",
};

print_expr :: proc(b: ^strings.Builder, node: ^Expr) {
  #partial switch kind in node.kind {
    case ExprBinary:
      fmt.sbprint(b, "(");
      fmt.sbprintf(b, "%s ", operator_to_string[kind.op]);
      print_expr(b, kind.lhs);
      fmt.sbprint(b, " ");
      print_expr(b, kind.rhs);
      fmt.sbprint(b, ")");
    case ExprNumber:
      fmt.sbprint(b, kind.val);
    case:
      fmt.println(node);
      panic("Not implemented!");
  }
}

print_block :: proc(b: ^strings.Builder, block: ^StmtBlock, depth := 0) {
  for stmt in block.stmts {
    print_stmt(b, stmt, depth + 1);
  }
}


print_decl :: proc(b: ^strings.Builder, decl: ^Decl) {
  #partial switch kind in decl.kind {
    case DeclFun:
      fmt.sbprintf(b, "fun %s ()", kind.name);
      fmt.sbprint(b, " {\n");
      print_block(b, kind.body);
      fmt.sbprint(b, "}\n");
    case:
      panic("Not implemented!");
  }
}


print_ast :: proc(b: ^strings.Builder, ast: ^Ast) {
  for decl in ast.decls {
    print_decl(b, decl);
  }
}
