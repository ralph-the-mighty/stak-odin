package main;

import "core:fmt";

with_raw :: proc() {
  Kind :: enum {
    A,
    B
  };

  A :: struct {
    intval: int
  };

  B :: struct {
    stringval: string
  };

  C :: struct {
    kind: Kind,
    using _ :struct #raw_union {
      a: A,
      b: B
    }
  };

  x: C;
  x.kind = Kind.A;
  x.a.intval = 4;


  x.kind = Kind.B;
  x.b.stringval = "asdf";
  

  fmt.println(x.a);
}



with_union :: proc() {
  ExprInt :: struct {
    intval: int
  };

  ExprString :: struct {
    stringval: string
  };

  Expr :: struct {
    kind: union {
      ExprInt, 
      ExprString
    }

  };

  Stmt :: struct {
    name: string,
    rhs: ^Expr,
  };

  AstNode :: struct {
    kind: union {
      Stmt, Expr
    }
  };

  node := new(AstNode);
  exp_ptr := cast(^Expr) (node);
  //exp_ptr.stringval = "asdf";
  fmt.println(exp_ptr);



  NODE :: proc(k: ^$T) -> ^AstNode {
    n := cast(^AstNode) k;
    return n;
  }



  fmt.println(cast(^AstNode)exp_ptr);
  fmt.println(cast(^ExprString)NODE(exp_ptr));



  // l1 := new(ExprString);
  // fmt.println(l1);
  // l2 := cast(^Expr)l1;
  // fmt.println(l2);
  // //l2 := 






}

  
scratch :: proc() {

  //with_raw();
  //with_union();

  // B :: struct {
  //   b: int
  // };

  // C :: struct {
  //   c: int
  // };

  // A :: struct {
  //   kind: union {
  //     B,
  //     C
  //   }
  // };

  // a: A;
  // a.kind = B{b = 5};
  // a_ptr := &a;

  // switch kind in &a_ptr.kind {
  //   case C:
  //     fmt.println("Case C!");
  //     fmt.println(kind);
  //   case B:
  //     fmt.println("Case B!");
  //     fmt.println(kind);
  //   case:
  //     fmt.println("Default!");
  // }


  //fmt.println(context.allocator);



  
  // ints: [dynamic]int;

  // for i in 0..10 {
  //   append(&ints, i);
  // }

  // fmt.println(ints);

  // for i in ints {
  //   fmt.println(i);
  // }


  // A :: struct {
  //   a: int
  // }; 

  // B :: struct {
  //   b: int
  // };


  // C :: union {
  //   A,
  //   B
  // };



  // c: C;
  // c = A{a=1};
  // fmt.println(c);


  // x: int;
  // {
  //   x := 3;
  //   fmt.printf("new x: %d\n", x);
  // }
  // fmt.printf("old x: %d\n", x);


  fmt.printf("%*s%s\n", 10, "", "Hello, world!");


}

