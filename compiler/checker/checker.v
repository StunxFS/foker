// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
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
	/*
	for stmt in ast_file.prog.stmts {
		c.expr_level = 0
		//c.stmt(stmt)
	}
	*/
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

fn (mut c Checker) check_div_mod_by_zero(expr ast.Expr, op_kind token.Kind) {
	match mut expr {
		ast.IntegerLiteral {
			if expr.lit.int() == 0 {
				c.error('division by zero', expr.pos)
			}
		}
		else {}
	}
}

// =============================================================================================
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

fn (mut c Checker) stmt(node ast.Stmt) {
	match mut node {
		ast.Block {
			//c.stmts(node.stmts)
		}
		ast.ExprStmt {
			node.typ = c.expr(node.expr)
			c.expected_type = .unknown
		}
		else {} // TODO: implementar el resto de las declaraciones
	}
}

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
			return .flag
		}
		ast.Ident {
			res := c.ident(mut node)
			return res
		}
		ast.IntegerLiteral {
			return .int
		}
		else {}
	}
}
*/
// =============================================================================================
pub fn (mut c Checker) warn(s string, pos token.Position) {
	allow_warnings := !(c.pref.optlevel == .fast || c.pref.warns_are_errors)
	c.warn_or_error(s, pos, allow_warnings)
}

pub fn (mut c Checker) error(message string, pos token.Position) {
	if c.pref.is_verbose {
		print_backtrace()
	}
	c.warn_or_error(message, pos, false)
}

fn (mut c Checker) warn_or_error(message string, pos token.Position, warn bool) {
	mut details := ''
	if c.errors_details.len > 0 {
		details = c.errors_details.join('\n')
		c.errors_details = []
	}
	if warn && !c.pref.skip_warnings {
		c.nr_warnings++
		wrn := errors.Report{
			message: message
			file_path: c.file.path
			pos: pos
			kind: .warning
		}
		c.file.warnings << wrn
		c.warnings << wrn
		return
	}
	if !warn {
		c.nr_errors++
		if pos.line_nr !in c.error_lines {
			err := errors.Report{
				message: message
				pos: pos
				file_path: c.file.path
				kind: .error
			}
			c.file.errors << err
			c.errors << err
			c.error_lines << pos.line_nr
		}
	}
}
