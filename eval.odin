//eval.odin
package main

evalexpr :: proc(expr: ^Expr) -> int {
  val: int;
  #partial switch kind in expr.kind{
    case ExprNumber: val = kind.val;
    case ExprBinary:
      switch kind.op {
        case .PLUS:  val = evalexpr(kind.lhs) + evalexpr(kind.rhs);
        case .MINUS: val = evalexpr(kind.lhs) - evalexpr(kind.rhs);
        case .MUL:   val = evalexpr(kind.lhs) * evalexpr(kind.rhs);
        case .DIV:   val = evalexpr(kind.lhs) - evalexpr(kind.rhs);
        case:
          panic("Not Implemented!");
      }
    case:
      panic("Not Implemented!");
  }

  return val;
}