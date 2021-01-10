// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import os
import compiler.token
import compiler.prefs
import compiler.util
import compiler.scanner
import compiler.ast

pub struct Parser {
	file_base         string // "hello.fkr"
	file_name         string // /home/user/hello.fkr
	file_name_dir     string // home/user
	pref              &prefs.Preferences
mut:
	scanner           &scanner.Scanner
	tok               token.Token
	prev_tok          token.Token
	peek_tok          token.Token
	peek_tok2         token.Token
	peek_tok3         token.Token
	table             &ast.Table
	mod               string // current module name
	expr_mod          string
	scope             &ast.Scope
	global_scope      &ast.Scope
	have_dyn_custom   bool
	cur_script_name   string
	inside_if         bool
	inside_ct_if_expr bool
}

fn parse_text(text string, path string, table &ast.Table, pref &prefs.Preferences, global_scope &ast.Scope) ast.File {
	mut p := Parser{
		scanner: scanner.new_scanner(text, pref)
		file_name: path
		file_base: os.base(path)
		file_name_dir: os.dir(path)
		table: table
		pref: pref
		scope: &ast.Scope{
			start_pos: 0
			parent: global_scope
		}
		global_scope: global_scope
	}
	return p.parse()
}

pub fn parse_file(path string, table &ast.Table, pref &prefs.Preferences, global_scope &ast.Scope) ast.File {
	mut p := Parser{
		scanner: scanner.new_scanner_file(path, pref)
		table: table
		file_name: path
		file_base: os.base(path)
		file_name_dir: os.dir(path)
		pref: pref
		scope: &ast.Scope{
			start_pos: 0
			parent: global_scope
		}
		global_scope: global_scope
	}
	return p.parse()
}

[inline]
fn (mut p Parser) get_builtins_stmt() []ast.Stmt {
	mut b_file := if p.file_name != builtins_file { parse_text(builtins_code, builtins_file,
			p.table, p.pref, p.global_scope) } else { ast.File{} }
	return b_file.prog.stmts
}

pub fn (mut p Parser) parse() ast.File {
	p.read_first_token()
	p.mod = p.file_name.all_after_last(os.path_separator).all_before_last('.')
	mut stmts := p.get_builtins_stmt()
	if p.pref.is_verbose {
		println("> Parsing module: '$p.mod' (archivo: '$p.file_name')")
	}
	for p.tok.kind != .eof {
		if p.tok.kind == .key_dynamic {
			if p.pref.backend == .decomp {
				p.error("no se puede usar la declaración 'dynamic' en binario")
			}
			if !p.have_dyn_custom {
				stmts << p.parse_dyn_custom()
				continue
			} else {
				p.error('no se puede redefinir el offset a usar dinámicamente')
			}
		}
		if p.tok.kind == .key_include {
			stmts << p.include_stmt()
			continue
		}
		break
	}
	for p.tok.kind != .eof {
		stmts << p.top_stmt()
	}
	p.scope.end_pos = p.tok.pos
	return ast.File{
		path: p.file_name
		prog: ast.Program{
			name: p.mod
			stmts: stmts
			scope: p.scope
		}
	}
}

pub fn (mut p Parser) read_first_token() {
	for _ in 0 .. 4 {
		p.next()
	}
}

pub fn (mut p Parser) open_scope() {
	p.scope = &ast.Scope{
		parent: p.scope
		start_pos: p.tok.pos
	}
}

pub fn (mut p Parser) close_scope() {
	p.scope.end_pos = p.prev_tok.pos
	p.scope.parent.children << p.scope
	p.scope = p.scope.parent
}

pub fn (mut p Parser) parse_block() []ast.Stmt {
	p.open_scope()
	// println('parse block')
	stmts := p.parse_block_no_scope(false)
	p.close_scope()
	// println('nr exprs in block = $exprs.len')
	return stmts
}

pub fn (mut p Parser) parse_block_no_scope(is_top_level bool) []ast.Stmt {
	p.check(.lbrace)
	mut stmts := []ast.Stmt{}
	if p.tok.kind != .rbrace {
		mut c := 0
		for p.tok.kind !in [.eof, .rbrace] {
			if !is_top_level {
				stmts << p.local_stmt()
			} else {
				stmts << p.top_stmt()
			}
			c++
			if c % 100000 == 0 {
				eprintln('parsed $c statements so far from fn $p.cur_script_name ...')
			}
			if c > 1000000 {
				p.error_with_pos('parsed over $c statements from fn $p.cur_script_name, the parser is probably stuck',
					p.tok.position())
				return []
			}
		}
	}
	p.check(.rbrace)
	return stmts
}

fn (mut p Parser) next() {
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.peek_tok2
	p.peek_tok2 = p.peek_tok3
	p.peek_tok3 = p.scanner.scan()
	if p.tok.kind == .name && p.tok.lit == 'endif' {
		p.next()
	}
}

fn (mut p Parser) check(expected token.Kind) {
	expected_str := match expected {
		.name { 'un identificador' }
		.number { 'un literal numérico' }
		.string { 'un literal de cadena' }
		else { "'" + expected.str() + "'" }
	}
	if p.tok.kind != expected {
		match p.tok.kind {
			.name { p.error("'$p.tok.lit' inesperado, se esperaba $expected_str") }
			.number { p.error('no se esperaba un literal numérico, se esperaba $expected_str') }
			.string { p.error('no se esperaba un literal de cadena, se esperaba $expected_str') }
			.eof { p.error('no se esperaba el final del archivo, se esperaba $expected_str') }
			else { p.error("'$p.tok.kind.str()' inesperado, se esperaba $expected_str") }
		}
	}
	p.next()
}

fn (mut p Parser) check_name() string {
	name := p.tok.lit
	p.check(.name)
	return name
}

fn (mut p Parser) include_stmt() ast.Include {
	p.check(.key_include)
	pos := p.tok.position()
	file := p.tok.lit
	p.check(.string)
	p.check(.semicolon)
	return ast.Include{
		pos: pos
		file: file
	}
}

pub fn (mut p Parser) top_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.key_include {
				p.error_with_pos("'include' se puede usar solo al principio del archivo",
					p.tok.position())
			}
			.key_script {
				return p.script_stmt()
			}
			.key_extern {
				match p.peek_tok.kind {
					.key_script { return p.script_stmt() }
					else { p.error("la palabra clave 'extern' solo se puede usar en conjunto a 'script': extern script xxx") }
				}
			}
			.key_cmd {
				return p.parse_cmd_stmt()
			}
			.key_const {
				return p.const_decl()
			}
			.key_var {
				return p.parse_var_stmt(true)
			}
			.key_movement {}
			else {
				p.error('declaración de alto nivel "' + p.tok.lit + '" desconocido')
			}
		}
	}
	return ast.Stmt{}
}

fn (mut p Parser) parse_cmd_stmt() ast.Stmt {
	p.check(.key_cmd)
	name_pos := p.tok.position()
	name := p.check_name()
	p.check(.lparen)
	mut params := []ast.Param{}
	for p.tok.kind != .rparen {
		pos := p.tok.position()
		param_name := p.check_name()
		p.check(.colon)
		typ_param := p.parse_type()
		if p.tok.kind == .assign {
			p.next()
			expr := p.expr(0)
			params << ast.Param{
				name: param_name
				typ: typ_param
				pos: pos
				def_value: expr
			}
		} else {
			params << ast.Param{
				name: param_name
				typ: typ_param
				pos: pos
			}
		}
		if p.tok.kind == .comma {
			p.next()
			continue
		}
	}
	p.check(.rparen)
	p.check(.semicolon)
	cmd := ast.CmdDecl{
		name: name
		params: params
		pos: name_pos
	}
	p.table.cmds << cmd
	return cmd
}

fn (mut p Parser) parse_dyn_custom() ast.Stmt {
	p.check(.key_dynamic)
	p.have_dyn_custom = true
	dyn_offset := p.tok.lit
	pos := p.tok.position()
	p.check(.number)
	if dyn_offset.to_lower().starts_with('0x') {
		p.error_with_pos('por favor no inicie la dirrección con `0x` o `0X`', p.prev_tok.position().extend(pos))
	}
	p.check(.semicolon)
	return ast.DynamicStmt{
		pos: pos
		dyn_offset: dyn_offset
	}
}

fn (mut p Parser) script_stmt() ast.Stmt {
	is_extern := p.tok.kind == .key_extern
	if is_extern {
		p.next()
	}
	script_pos := p.tok.position()
	p.check(.key_script)
	name_pos := p.tok.position()
	script_name := p.check_name()
	if util.contains_capital(script_name) && script_name[0].is_capital() {
		p.error_with_pos_and_details('no uses el estilo PascalCase para nombrar scripts, usa el estilo camelCase',
			p.prev_tok.position(), "en vez de usar, por ejemplo, 'MiNameScript', use 'miNameScript'")
	}
	p.cur_script_name = script_name
	if is_extern { // extern script name; | extern script name2 at 0x90034;
		mut extern_offset := ''
		if p.pref.backend == .binary && p.tok.kind == .key_at {
			p.next()
			extern_offset = p.tok.lit
			p.check(.number)
			if !extern_offset.starts_with('0x') || !extern_offset.starts_with('0X') {
				p.error('se esperaba un offset/dirección')
			}
			p.next()
		} else {
			p.error_with_pos('esta utilidad solo está disponible para el backend de binario',
				p.tok.position().extend(p.peek_tok.position()))
		}
		p.check(.semicolon)
		return ast.ScriptDecl{
			name: script_name
			mod: p.mod
			is_extern: is_extern
			extern_offset: extern_offset
			pos: script_pos.extend(p.prev_tok.position())
		}
	}
	mut stmts := p.parse_block()
	return ast.ScriptDecl{
		name: script_name
		mod: p.mod
		is_extern: is_extern
		stmts: stmts
		pos: script_pos.extend(name_pos)
	}
}

fn (mut p Parser) const_decl() ast.Const {
	// start_pos := p.tok.position()
	// end_pos := p.tok.position()
	// const_pos := p.tok.position()
	p.check(.key_const)
	pos := p.tok.position()
	name := p.check_name()
	mut type_const := ast.Type._auto
	if name == '_' {
		p.error_with_pos("no se puede usar '_' como nombre de una constante", pos)
	}
	if !util.contains_capital(name) {
		p.error_with_pos('los nombres de las constantes deben ser puras mayúsculas (use: "$name.to_upper()", en vez de "$name")',
			pos)
	}
	if p.tok.kind == .colon {
		p.next()
		type_const = p.parse_type()
	}
	// println(full_name.replace('.', '__')) // (works fine)
	p.check(.assign)
	mut expr := ast.Expr{}
	match p.tok.kind {
		.string {
			expr = ast.Expr(p.string_expr())
		}
		.number {
			expr = p.parse_number_literal()
		}
		.key_true, .key_false {
			expr = ast.Expr(ast.BoolLiteral{
				lit: (p.tok.kind == .key_true).str()
				pos: p.tok.position()
			})
			p.next()
		}
		else {
			p.error('las constantes no soportan expresiones avanzadas, solo soportan literales')
		}
	}
	if p.tok.kind != .semicolon {
		p.error('las constantes no soportan expresiones avanzadas, solo soportan literales')
	}
	field := ast.Const{
		name: name
		mod: p.mod
		expr: expr
		pos: pos
		typ: type_const
	}
	p.global_scope.register(field)
	p.check(.semicolon)
	return field
}

// ===== Local Statements =========================================================================
fn (mut p Parser) local_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.key_var {
				return p.parse_var_stmt(false)
			}
			.key_free {
				return p.parse_free_stmt()
			}
			.key_if {
				return ast.ExprStmt{
					expr: p.if_expr(false)
				}
			}
			.key_question {
				return p.question_stmt()
			}
			.key_checkgender {
				return p.checkgender_stmt()
			}
			.dollar {
				if p.peek_tok.kind == .key_if {
					return ast.ExprStmt{
						expr: p.if_expr(true)
					}
				}
			}
			/*
			.key_continue, .key_break {
				tok := p.tok
				line := p.tok.line_nr
				p.next()
				mut label := ''
				if p.tok.line_nr == line && p.tok.kind == .name {
					label = p.check_name()
				}
				return ast.BranchStmt{
					kind: tok.kind
					label: label
					pos: tok.position()
				}
			}
			*/
			else {
				p.error('declaración de nivel local "' + p.tok.lit + '" desconocido')
			}
		}
	}
	return ast.Stmt{}
}

fn (mut p Parser) parse_type() ast.Type {
	typ_name := p.check_name()
	if typ_name !in ast.type_names {
		p.error_with_pos('se esperaba uno de los siguientes tipos: ' + ast.type_names.join(', '),
			p.prev_tok.position())
	}
	return ast.get_type_from_string(typ_name)
}

fn (mut p Parser) check_undefined_variables(expr ast.Expr, val ast.Expr) {
	match val {
		ast.Ident {
			if expr is ast.Ident {
				if expr.name == val.name {
					p.error_with_pos('variable indefinida `$val.name`', val.pos)
				}
			}
		}
		ast.InfixExpr {
			p.check_undefined_variables(expr, val.left)
			p.check_undefined_variables(expr, val.right)
		}
		ast.ParExpr {
			p.check_undefined_variables(expr, val.expr)
		}
		ast.PostfixExpr {
			p.check_undefined_variables(expr, val.expr)
		}
		ast.PrefixExpr {
			p.check_undefined_variables(expr, val.right)
		}
		else {}
	}
}

fn (mut p Parser) parse_var_stmt(is_top_level bool) ast.Stmt {
	p.check(.key_var)
	mut name := p.parse_ident()
	if is_top_level && p.pref.backend == .decomp {
		p.error('no se pueden declarar variables en el ámbito global en decomp')
	}
	if is_top_level && name.name == '_' {
		p.error_with_pos("no se puede usar '_' como nombre de una variable global", p.prev_tok.position())
	}
	mut type_var := ast.Type._auto
	if p.tok.kind == .key_at {
		pos := p.tok.position()
		p.next()
		offset := p.tok.lit
		p.check(.number)
		if p.tok.kind == .semicolon {
			p.error_with_pos('se espera que se declare un tipo: `var XXX at 0x800D: int;`',
				p.prev_tok.position())
		}
		p.check(.colon)
		type_var = p.parse_type()
		p.check(.semicolon)
		if p.scope.known_var(name.name) {
			p.error_with_pos("redefinición de '$name.name'", name.pos)
		}
		obj := ast.ScopeObject(ast.Var{
			name: name.name
			offset: offset
			pos: name.pos
		})
		name.obj = obj
		if !is_top_level {
			p.scope.register(obj)
		} else {
			p.global_scope.register(obj)
		}
		return ast.AssignStmt{
			right: name
			offset: offset
			pos: pos
			right_type: type_var
		}
	}
	if is_top_level && p.tok.kind == .assign {
		p.error('no se pueden definir variables en el ámbito global')
	}
	p.next()
	pos := p.tok.position()
	expr := p.expr(0)
	p.check_undefined_variables(name, expr)
	if p.tok.kind == .colon {
		p.next()
		type_var = p.parse_type()
	}
	// println('var stmt: "${name}", expr: ${expr}')
	p.check(.semicolon)
	if p.scope.known_var(name.name) {
		p.error_with_pos("redefinición de '$name.name'", name.pos)
	}
	obj := ast.ScopeObject(ast.Var{
		name: name.name
		expr: expr
		pos: name.pos
	})
	name.obj = obj
	p.scope.register(obj)
	return ast.AssignStmt{
		right: name
		op: token.Kind.assign
		left: expr
		pos: pos
	}
}

fn (mut p Parser) parse_free_stmt() ast.Stmt {
	p.check(.key_free)
	pos := p.tok.position()
	var := p.check_name()
	p.check(.semicolon)
	return ast.FreeStmt{
		ident: var
		pos: pos
	}
}
