// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

// import os
// import strings
// import compiler.util
import compiler.ast
import compiler.token
import compiler.prefs
import compiler.errors

const (
	max_nr_errors                 = 300
	match_exhaustive_cutoff_limit = 10
	int_min                       = int(0x80000000)
	int_max                       = 0x7FFFFFFF
)

pub struct Checker {
	pref &prefs.Preferences
pub mut:
	table         &ast.Table
	file          &ast.File = 0
	nr_errors     int
	nr_warnings   int
	errors        []errors.Report
	warnings      []errors.Report
	error_lines   []int // para evitar imprimir multiple errores para la misma linea :)
	expected_type ast.Type
	cur_script    &ast.ScriptDecl
	const_decl    string
	const_names   []string
	in_for_count  int // si checker está actualmente en un bucle for
mut:
	expr_level     int // para evitar una recursion infinita que implique bugs del compilador
	errors_details []string
	loop_label     string // obtiene valor cuando se está dentro de un bucle for etiquetado
}

pub fn new_checker(table &ast.Table, pref &prefs.Preferences) Checker {
	return Checker{
		table: table
		pref: pref
		cur_script: 0
	}
}

pub fn (mut c Checker) check(ast_file &ast.File) {
	c.file = ast_file
	for stmt in ast_file.prog.stmts {
		c.expr_level = 0
		c.stmt(stmt)
	}
	c.check_scope_vars(c.file.prog.scope)
}

pub fn (mut c Checker) check_scope_vars(sc &ast.Scope) {
	for _, obj in sc.objects {
		match obj {
			ast.Var {
				if !obj.is_used && obj.name[0] != `_` {
					c.warn("variable '$obj.name' no usada", obj.pos)
				}
			}
			else {}
		}
	}
	for _, child in sc.children {
		c.check_scope_vars(child)
	}
}

fn (mut c Checker) check_div_by_zero(expr ast.Expr, op_kind token.Kind) {
	match mut expr {
		ast.IntegerLiteral {
			if expr.lit.int() == 0 {
				c.error('division por zero', expr.pos)
			}
		}
		else {}
	}
}

/*
[inline]
fn (mut c Checker) check_loop_label(label string, pos token.Position) {
	if label.len == 0 {
		return
	}
	if c.loop_label.len != 0 {
		c.error("nesting of labelled 'for' loops is not supported", pos)
		return
	}
	c.loop_label = label
}
*/
//¿como te fue en el paseo?
fn (mut c Checker) stmt(node ast.Stmt) {
	if node is ast.CallStmt {
		println(node)
	}
	match mut node {
		ast.Block {
			//c.stmts(node.stmts)
		}
		ast.ExprStmt {
			node.typ = c.expr(node.expr)
			c.expected_type = .unknown
		}
		ast.CallStmt { // call my_script;
			if !c.table.exists_script(node.script) {
				c.error("no existe un script con este nombre", node.pos)
			}
			println('call')
		}
		ast.IfStmt {
			if c.expr(node.cond) != .bool {
				c.error("se espera una expresión condicional", node.pos)
			}
		}
		else {println(typeof(node).name)} // TODO: implementar el resto de las declaraciones
	}
}

// Expresiones ============================================
pub fn (mut c Checker) expr(node ast.Expr) ast.Type {
	c.expr_level++
	defer {
		c.expr_level--
	}
	if c.expr_level > 200 {
		c.error('checker: too many expr levels: ${c.expr_level}', node.position())
		return .unknown
	}
	match mut node {
		ast.BoolLiteral {
			return .bool
		}
		/*ast.Ident {
			res := c.ident(mut node)
			return res
		}*/
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
		else {}
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
		}
		.key_and, .key_or {
			if infix_expr.left_type != ast.Type.bool {
				c.error('left operand for `$infix_expr.op` is not a boolean', infix_expr.left.position())
			}
			if infix_expr.right_type != ast.Type.bool {
				c.error('right operand for `$infix_expr.op` is not a boolean', infix_expr.right.position())
			}
			// use `()` to make the boolean expression clear error
			// for example: `(a && b) || c` instead of `a && b || c`
			if mut infix_expr.left is ast.InfixExpr {
				if infix_expr.left.op != infix_expr.op && infix_expr.left.op in [.key_and, .key_or] {
					c.error('use `()` to make the boolean expression clear', infix_expr.pos)
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
