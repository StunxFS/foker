// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module textrbh

import os
import strings
import compiler.util
import compiler.ast
import compiler.about
import compiler.prefs

// import compiler.gen.fmttxt

pub struct Gen {
	prefs &prefs.Preferences
mut:
	table            &ast.Table
	file             &ast.File
	header           strings.Builder = strings.new_builder(100)
	includes         strings.Builder = strings.new_builder(100)
	defines          strings.Builder = strings.new_builder(100)
	snippets         strings.Builder = strings.new_builder(100)
	snippets2        strings.Builder = strings.new_builder(100) // para labels, if, etc
	strings          strings.Builder = strings.new_builder(100)
	strings_tmp      strings.Builder = strings.new_builder(100)
	moves            strings.Builder = strings.new_builder(100)
	moves_tmp        strings.Builder = strings.new_builder(100)
	flags            Data
	vars             Data
	dyn_offset       string = '0x800000'
	main_script      string
	cur_script_name  string
	flags_map        map[string]map[string]string // mapa usado para contener los offsets de cada flags
	vars_map         map[string]map[string]string // mapa usado para contener los offsets de cada variable
	scripts_offsets  map[string]string
	label_count      int
	strings_count    int
	movs_count       int
	res              string // variable separada para las expresiones con literales
	require_main_end bool
	for_snippets2 bool
}

pub fn new_gen(prefs &prefs.Preferences, table &ast.Table) ?Gen {
	flags := new_data_from_file(prefs.flags_file) ?
	mut vars := new_data_from_file(prefs.vars_file) ?
	res := vars.get() or {
		util.err('no se pudo obtener una variable separada para "res"')
		''
	}
	return Gen{
		prefs: prefs
		table: table
		flags: flags
		vars: vars
		file: 0
		res: res
	}
}

pub fn (mut g Gen) gen_from_files(files []ast.File) ? {
	g.header.writeln('; Generado automáticamente con ZubatScript v$about.complete_version')
	g.header.writeln('; Creado por: StunxFS | ADVERTENCIA: No modificar sin saber del tema')
	for i := 0; i < files.len; i++ {
		g.file = unsafe { &files[i] }
		g.gen()
	}
	g.header.writeln('\n#dynamic $g.dyn_offset\n')
	// el snippet principal que se llamará
	g.header.writeln('; este es el script principal que se debe llamar')
	g.header.writeln('#org @start')
	g.header.writeln('call @$g.main_script')
	g.header.writeln('end')

	os.write_file(g.prefs.output, g.create_content()) ?
}

pub fn (mut g Gen) gen() {
	for stmt in g.file.mod.stmts {
		g.top_stmt(stmt)
	}
}

fn (mut g Gen) write(s string) {
	if g.for_snippets2 {
		g.snippets2.write(s)
	} else {
		g.snippets.write(s)
	}
}

fn (mut g Gen) writeln(s string) {
	if g.for_snippets2 {
		g.snippets2.writeln(s)
	} else {
		g.snippets.writeln(s)
	}
}

fn (g &Gen) no_colons(n string) string {
	if n.contains('::') {
		return n.replace('::', '__')
	}
	return n
}

[inline]
fn (mut g Gen) get_new_flag() string {
	f := g.flags.get() or {
		util.err('gen: $err')
		return ''
	}
	return f
}

[inline]
fn (mut g Gen) get_new_var() string {
	v := g.vars.get() or {
		util.err('gen: $err')
		return ''
	}
	return v
}

[inline]
fn (g &Gen) get_flag(flag string) string {
	return g.flags_map[g.cur_script_name][flag]
}

[inline]
fn (g &Gen) get_var(var string) string {
	return g.vars_map[g.cur_script_name][var]
}

[inline]
fn (g &Gen) is_flag(flag string) bool {
	for _, f in g.flags_map[g.cur_script_name] {
		if f == flag {
			return true
		}
	}
	return false
}

[inline]
fn (g &Gen) is_var(var string) bool {
	for _, v in g.vars_map[g.cur_script_name] {
		if v == var {
			return true
		}
	}
	if var == g.res {
		return true
	}
	return false
}

[inline]
fn (mut g Gen) reg_flag(flag string, dir string) {
	g.flags_map[g.cur_script_name][flag] = dir
}

[inline]
fn (mut g Gen) reg_var(var string, dir string) {
	g.vars_map[g.cur_script_name][var] = dir
}

[inline]
fn (mut g Gen) clear_res() {
	g.writeln('setvar $g.res 0x0')
}

pub fn (mut g Gen) create_content() string {
	mut c := strings.new_builder(100)
	c.writeln('$g.header.str()\n')
	if g.includes.len > 0 {
		c.writeln(g.header.str().trim_space())
	}
	if g.defines.len > 0 {
		c.writeln(g.defines.str().trim_space())
	}
	if g.snippets.len > 0 {
		c.writeln('\n; snippets (scripts)')
		c.writeln(g.snippets.str().trim_space())
	}
	if g.snippets2.len > 0 {
		c.writeln('\n; snippets2 (labels, if, etc)')
		c.writeln(g.snippets2.str().trim_space())
	}
	if g.strings.len > 0 {
		c.writeln('\n; strings')
		c.writeln(g.strings.str().trim_space())
	}
	if g.strings_tmp.len > 0 {
		c.writeln('\n; strings temporales')
		c.writeln(g.strings_tmp.str().trim_space())
	}
	if g.moves.len > 0 {
		c.writeln('\n; movimientos')
		c.writeln(g.moves.str().trim_space())
	}
	if g.moves_tmp.len > 0 {
		c.writeln('\n; movimientos temporales')
		c.writeln(g.moves_tmp.str().trim_space())
	}
	return '$c.str()\n'
}

pub fn (mut g Gen) top_stmt(node ast.Stmt) {
	match mut node {
		/*ast.Const {
			match node.typ {
				.int {
					val := g.define_expr(node.expr)
					g.table.constantes[node.name] = val
					str := to_hex(val)
					gen_name := g.no_colons(node.name)
					g.defines.writeln('#define $gen_name $str')
				}
				.string {
					name := g.no_colons(node.name)
					g.strings.writeln('#org @$name')
					lit := (node.expr as ast.StringLiteral).lit
					g.strings.writeln('= $lit\n')
				}
				else {}
			}
		}*/
		ast.ScriptDecl {
			g.script_decl(mut node)
		}
		ast.DynamicStmt {
			g.dyn_offset = '0x' + node.dyn_offset
		}
		else {}
	}
}

// define_expr - generar valores constantes en base a expresiones simples
pub fn (mut g Gen) define_expr(node ast.Expr) int {
	mut res := 0
	match node {
		ast.Ident {
			res = g.table.constantes[node.name]
		}
		ast.IntegerLiteral {
			res = node.lit.int()
		}
		ast.ParExpr {
			res = g.define_expr(node.expr)
		}
		ast.InfixExpr {
			val1, val2 := g.define_expr(node.left), g.define_expr(node.right)
			match node.op {
				.plus { res = val1 + val2 }
				.minus { res = val1 - val2 }
				.mul { res = val1 * val2 }
				.div { res = val1 / val2 }
				else {}
			}
		}
		else {}
	}
	return res
}

fn (mut g Gen) make_label() string {
	label := '${g.cur_script_name}_label_$g.label_count'
	g.label_count++
	return label
}

fn (mut g Gen) make_string_tmp() string {
	label := 'string$g.strings_count'
	g.strings_count++
	return label
}

fn (mut g Gen) make_mov_tmp() string {
	label := 'movement$g.movs_count'
	g.movs_count++
	return label
}

fn (mut g Gen) script_decl(mut node ast.ScriptDecl) {
	if node.is_extern {
		g.scripts_offsets[node.name] = node.extern_offset
		return
	}
	gen_name := g.no_colons(node.name)
	if node.is_main {
		g.main_script = gen_name
	}
	g.cur_script_name = gen_name
	g.snippets.writeln('\n#org @$gen_name')
	for stmt in node.stmts {
		g.stmt(stmt)
	}
	if g.require_main_end {
		g.snippets.writeln('#org @${gen_name}_end')
	}
	g.snippets.writeln('end')
}

fn (mut g Gen) stmt(node ast.Stmt) {
	match node {
		ast.Block {
			for stmt in node.stmts {
				g.stmt(stmt)
			}
		}
		ast.IfStmt {
			g.if_stmt(node)
		}
		ast.RawStmt {
			mut raw := node.text
			for raw.contains('[') && raw.contains(']') {
				var := raw.find_between('[', ']')
				// Solo las variables se pueden usar aquí :)
				raw = raw.replace('[$var]', g.get_var(var))
			}
			g.writeln(raw)
		}
		ast.CallCmdStmt {
			mut args := ''
			for arg in node.args {
				var := g.expr(arg.expr)
				if var != '' {
					args += ' $var'
				}
			}
			g.write(node.name.all_before_last('::'))
			g.write('$args\n')
		}
		ast.CallStmt {
			g.writeln('call @${g.no_colons(node.script)}')
		}
		ast.AssignStmt {
			g.assign_stmt(node)
		}
		else {}
	}
}

fn (mut g Gen) assign_stmt(node ast.AssignStmt) {
	lft := node.left as ast.Ident
	if node.is_decl {
		var := g.get_new_var()
		g.reg_var(lft.name, var)
		val := g.expr(node.right)
		if g.is_var(val) {
			g.writeln('setvar $var 0x0')
			g.writeln('copyvar $var $val ; assign_var(true): $lft.name[$var]')
			if val == g.res {
				g.clear_res()
			}
		} else {
			g.writeln('setvar $var $val ; assign_var(true): $lft.name[$var]')
		}
	} else {
		var := g.get_var(lft.name)
		val := g.expr(node.right)
		match node.op {
			.plus_assign, .minus_assign {
				cmd := if node.op == .plus_assign { 'addvar' } else { 'subvar' }
				if g.is_var(val) {
					g.writeln('setvar $var $val ; plus_assign')
				} else {
					g.writeln('$cmd $var $val ; plus_assign')
				}
			}
			else {
				if g.is_var(val) {
					g.writeln('copyvar $var $val ; assign_stmt(false): $lft.name')
					if val == g.res {
						g.clear_res()
					}
				} else if node.op !in [.plus_assign, .minus_assign] {
					g.writeln('setvar $var $val ; assign_var(false): $lft.name')
				}
			}
		}
	}
}

fn (mut g Gen) if_stmt(node ast.IfStmt) {
	//g.require_main_end = true
	mut else_branches := []ast.Stmt{}
	else_end := 'else_end_' + g.make_label()
	for branch in node.branches {
		if branch.is_else {
			else_branches = branch.stmts.clone()
		} else {
			cond := g.expr(branch.cond)
			label := g.make_label()
			// compare: compara una variable con un número
			// comparevar: compara una variable con otra
			// La siguiente parte se compone por un: if <op> <goto|call> <label>
			g.snippets.writeln('$cond @$label')
			g.for_snippets2 = true
			g.writeln('#org @$label')
			for stmt in branch.stmts {
				g.stmt(stmt)
			}
			g.writeln('goto $else_end\n')
			g.for_snippets2 = false
		}
	}
	for stmt in else_branches {
		g.stmt(stmt)
	}
	g.writeln('#org @$else_end')
}

// Expresiones | De aquí a abajo le toca a todas las expresiones

// expr - retorna 2 strings, uno con pre-código y otro con el ident a usar
fn (mut g Gen) expr(node ast.Expr) string {
	match mut node {
		ast.ParExpr {
			return g.expr(node.expr)
		}
		ast.StringLiteral {
			name := g.make_string_tmp()
			g.strings_tmp.writeln('#org @$name')
			g.strings_tmp.writeln('= $node.lit\n')
			return '@$name'
		}
		ast.FmtStringLiteral {
			// name := g.make_string_tmp()
			// g.strings_tmp.writeln('#org @$name')
			// g.strings_tmp.writeln('= $node.lit\n')
			return ''
		}
		ast.IntegerLiteral {
			val := if node.is_hex { node.lit } else { to_hex(node.lit.int()) }
			return val
		}
		ast.InfixExpr {
			var := g.expr(node.left)
			var1 := g.expr(node.right)
			var_infix := if g.is_var(var) { var } else { g.res }
			match node.op {
				.plus, .minus {
					cmd := if node.op == .plus { 'addvar' } else { 'subvar' }
					if g.is_var(var) {
						if var != var_infix {
							g.writeln('copyvar $var_infix $var')
						}
					} else {
						g.writeln('$cmd $var_infix $var')
					}
					g.writeln('$cmd $var_infix $var1')
				}
				// Comparaciones
				.eq, .neq, .lt, .gt, .lte, .gte {
					/*
					#define B_< 0x0
					#define B_<< 0x0 TODO
					#define B_= 0x1 TODO (really?)
					#define B_== 0x1
					#define B_> 0x2
					#define B_>> 0x2 TODO
					#define B_<= 0x3
					#define B_>= 0x4
					#define B_!= 0x5
					#define B_<> 0x5 TODO
					*/
					op := match node.op {
						.eq {'0x1'}
						.neq { '0x5' }
						.lt { '0x0' }
						.gt { '0x2' }
						.lte { '0x3' }
						.gte { '0x4' }
						else { '' }
					}
					cmd := if g.is_var(var1) { 'comparevars' } else { 'compare' }
					g.writeln('$cmd $var $var1')
					return 'if $op goto'
				}
				else {}
			}
			return var_infix
		}
		ast.Ident {
			obj := node.obj
			match obj {
				ast.Var {
					mut name := g.no_colons(obj.name)
					match obj.typ {
						.movement { name = '@' + name }
						else {}
					}
					var := g.get_var(name)
					if var != '' {
						name = var
					}
					return name
				}
				ast.Const {
					mut name := g.no_colons(obj.name)
					match obj.typ {
						.movement, .string { name = '@' + name }
						else {}
					}
					return name
				}
			}
		}
		else {}
	}
	return ''
}
