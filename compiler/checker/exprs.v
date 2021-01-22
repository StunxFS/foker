// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

import compiler.ast
import compiler.token

/*
import compiler.prefs
import compiler.errors
*/
fn (mut c Checker) check_div_by_zero(expr ast.Expr, op_kind token.Kind) {
	match mut expr {
		ast.IntegerLiteral {
			if expr.lit.int() == 0 {
				c.error('la división por cero no está permitida', expr.pos)
			}
		}
		else {}
	}
}

pub fn (mut c Checker) expr(node ast.Expr) ast.Type {
	c.expr_level++
	defer {
		c.expr_level--
	}
	if c.expr_level > 200 {
		c.error('checker: demasiados niveles de expresión: $c.expr_level', node.position())
		return .unknown
	}
	match mut node {
		ast.BoolLiteral {
			return .bool
		}
		ast.Ident {
			return c.ident(mut node)
		}
		ast.IntegerLiteral {
			return .int
		}
		ast.StringLiteral, ast.FmtStringLiteral {
			return .string
		}
		ast.MovementExpr {
			return .movement
		}
		ast.InfixExpr {
			return c.infix_expr(mut node)
		}
		ast.PostfixExpr {
			return c.postfix_expr(mut node)
		}
		ast.PrefixExpr {
			return c.prefix_expr(mut node)
		}
		ast.ParExpr {
			return c.expr(node.expr)
		}
	}
	return .unknown
}

fn (mut c Checker) infix_expr(mut infix_expr ast.InfixExpr) ast.Type {
	former_expected_type := c.expected_type
	defer {
		c.expected_type = former_expected_type
	}
	c.expected_type = .unknown
	left_type := c.expr(infix_expr.left)
	infix_expr.left_type = left_type
	c.expected_type = left_type
	right_type := c.expr(infix_expr.right)
	infix_expr.right_type = right_type
	left_pos := infix_expr.left.position()
	right_pos := infix_expr.right.position()
	return_type := left_type
	match infix_expr.op {
		.plus, .minus, .mul, .div {
			if infix_expr.op == .div {
				c.check_div_by_zero(infix_expr.right, infix_expr.op)
			}
			if left_type == .bool || right_type == .bool {
				c.error('estas operaciones no están permitidas con bool/flags', infix_expr.pos)
			}
			if left_type == .string || right_type == .string {
				c.error('estas operaciones no están permitidas con strings', infix_expr.pos)
			}
		}
		.key_and, .key_or {
			if infix_expr.left_type != ast.Type.bool {
				c.error("operando izquierdo para '$infix_expr.op' no es un booleano",
					left_pos)
			}
			if infix_expr.right_type != ast.Type.bool {
				c.error("operando derecho para '$infix_expr.op' no es un booleano", right_pos)
			}
			// use `()` to make the boolean expression clear error
			// for example: `(a && b) || c` instead of `a && b || c`
			if mut infix_expr.left is ast.InfixExpr {
				if infix_expr.left.op != infix_expr.op && infix_expr.left.op in [.key_and, .key_or] {
					c.error("use '()' para aclarar la expresión booleana", infix_expr.pos)
				}
			}
		}
		else {}
	}
	return if infix_expr.op.is_relational() {
		ast.Type.bool
	} else {
		return_type
	}
}

pub fn (mut c Checker) postfix_expr(mut node ast.PostfixExpr) ast.Type {
	typ := c.expr(node.expr)
	if typ !in [.int, .long] {
		c.error("operación inválida: $node.op.str() ('$typ' no es un tipo numérico)",
			node.pos)
	}
	return typ
}

pub fn (mut c Checker) prefix_expr(mut node ast.PrefixExpr) ast.Type {
	right_type := c.expr(node.right)
	node.right_type = right_type
	if node.op == .bang && right_type != .bool {
		c.error('el operador ! solo se puede utilizar con tipos bool', node.pos)
	}
	return right_type
}

pub fn (mut c Checker) ident(mut ident ast.Ident) ast.Type {
	if ident.kind == .blank_ident {
		if ident.tok_kind != .assign {
			c.error("ident indefinido: '_' (solo se puede usar en asignaciones)", ident.pos)
		}
		return .unknown
	}
	// segundo uso
	if ident.kind in [.constant, .variable] {
		info := ident.obj
		if info is ast.Var {
			return info.typ
		} else if info is ast.Const {
			return info.typ
		}
	} else if ident.kind == .unresolved {
		// primer uso
		if obj := ident.scope.find(ident.name) {
			match mut obj {
				ast.Var {
					obj.is_used = true
					if ident.pos.pos < obj.pos.pos {
						c.error("variable '$ident.name' indefinida (usada antes de la declaración)",
							ident.pos)
					}
					typ := obj.typ
					if typ == .unknown {
						if obj.expr is ast.Ident {
							if obj.expr.kind == .unresolved {
								c.error("variable no resuelta: '$ident.name'", ident.pos)
								return .unknown
							}
						}
					}
					ident.kind = .variable
					return typ
				}
				else {}
			}
		}
	}
	if obj := c.file.prog.scope.find(ident.name) {
		match mut obj {
			ast.Const {
				mut typ := obj.typ
				if typ == .unknown {
					typ = c.expr(obj.expr)
				}
				ident.kind = .constant
				obj.typ = typ
				ident.obj = obj
				return typ
			}
			else {}
		}
	}
	c.error("variable o constante indefinida: '$ident.name'", ident.pos)
	return .unknown
}
