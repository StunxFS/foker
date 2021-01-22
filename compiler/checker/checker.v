// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

// import os
// import strings
// import compiler.token
import compiler.util
import compiler.ast
import compiler.prefs

// import compiler.errors
const (
	max_nr_errors                 = 300
	match_exhaustive_cutoff_limit = 10
	int_min                       = int(0x80000000)
	int_max                       = 0x7FFFFFFF
)

pub struct Checker {
	pref &prefs.Preferences
pub mut:
	table       &ast.Table
	file        &ast.File = 0
	nr_errors   int
	nr_warnings int
	// errors        []errors.Report
	// warnings      []errors.Report
	error_lines   []int // para evitar imprimir multiple errores para la misma linea :)
	expected_type ast.Type
	cur_script    &ast.ScriptDecl
	const_decl    string
	in_for_count  int // si checker está actualmente en un bucle for
mut:
	expr_level     int // para evitar una recursion infinita que implique bugs en el compilador
	errors_details []string
	loop_label     string // obtiene valor cuando se está dentro de un bucle for etiquetado
	has_main       bool
	constants      map[string]int
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

pub fn (mut c Checker) check_files(ast_files []ast.File) {
	for mut ast_file in ast_files {
		c.check(ast_file)
	}
	if !c.pref.is_library && !c.has_main {
		util.err('Este script no tiene una entrada principal (script main {})')
	}
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
fn (mut c Checker) stmt(node ast.Stmt) {
	match mut node {
		ast.AssignStmt {
			c.assign_stmt(mut node)
		}
		ast.ScriptDecl {
			if node.name == 'main' && !c.has_main {
				c.has_main = true
			}
			for stmt in node.stmts {
				c.stmt(stmt)
			}
		}
		ast.Block {
			for stmt in node.stmts {
				c.stmt(stmt)
			}
		}
		ast.ExprStmt {
			node.typ = c.expr(node.expr)
			c.expected_type = .unknown
		}
		ast.CallStmt { // call my_script;
			if !c.table.exists_script(node.script) {
				c.error('no existe un script con este nombre', node.pos)
			}
		}
		ast.Const {
			node.typ = c.expr(node.expr)
			c.expected_type = .unknown
		}
		ast.IfStmt {
			for branch in node.branches {
				if !branch.is_else && c.expr(branch.cond) != .bool {
					c.error('se espera una expresión condicional', branch.cond.position())
				}
			}
		}
		else {} // TODO: implementar el resto de las declaraciones
	}
}

pub fn (mut c Checker) assign_stmt(mut assign_stmt ast.AssignStmt) {
	defer {
		c.expected_type = .unknown
	}
	// izquierda
	is_decl := assign_stmt.is_decl
	left := assign_stmt.left
	mut left_type := assign_stmt.left_type
	is_blank_ident := left.is_blank_ident()
	// derecha
	right := assign_stmt.right
	mut right_type := c.expr(right)
	// le damos el tipo de la expresión a la variable
	// si esta no la tiene definida
	if left_type == .unknown {
		left_type = right_type
	}
	if (left_type == .string || right_type == .string) && is_decl {
		c.error("no se puede declarar variables de tipo string, use 'text' para esto",
			assign_stmt.pos)
	}
	if right_type == .string && !is_decl {
		c.error("no se pueden usar valores de tipo string en variables, use 'text' para esto",
			assign_stmt.pos)
	}
	c.expected_type = left_type
	if is_decl {
		if left_type == ast.Type.int {
			mut expr := right
			mut negative := false
			if right is ast.PrefixExpr {
				expr = right.right
				if right.op == .minus {
					negative = true
				}
			}
			if mut expr is ast.IntegerLiteral {
				mut is_large := false
				if expr.lit.len > 8 {
					val := expr.lit.i64()
					if (!negative && val > int_max) || (negative && -val < int_min) {
						is_large = true
					}
				}
				if is_large {
					c.error('desbordamiento en tipo implícito `int`, use conversión de tipo explícito en su lugar',
						expr.pos)
				}
			}
		}
	}
	match mut left {
		ast.Ident {
			if left.kind == .blank_ident {
				left_type = right_type
				assign_stmt.left_type = right_type
				if assign_stmt.op != .assign {
					c.error("no se puede modificar el identificador '_' en blanco", left.pos)
				}
			} else if left.obj !is ast.Var {
				c.error("no se puede asignar a $left.kind '$left.name'", left.pos)
			} else {
				if assign_stmt.left_type == .unknown {
					assign_stmt.left_type = left_type
				}
				if left_type != .unknown {
					match mut left.obj {
						ast.Var { left.obj.typ = left_type }
						else {}
					}
				}
			}
		}
		/*
		ast.PrefixExpr {
			if is_decl {
				c.error('sin nombre en el lado izquierdo de `=`', left.pos)
			}
		}
		*/
		else {
			if is_decl {
				c.error("sin nombre en el lado izquierdo de '='", left.position())
			}
		}
	}
	if !is_blank_ident && (is_decl && assign_stmt.offset == '') {
		$if debug ? {
			println('$left_type = $right_type')
		}
		// Dual sides check (compatibility check)
		c.check_expected(right_type, left_type) or {
			name := (left as ast.Ident).name
			c.error("no se le puede asignar un valor a '$name': $err", right.position())
		}
	}
}
