// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

// import compiler.errors
import os
import compiler.token
import compiler.prefs
import compiler.util
import compiler.scanner
import compiler.ast

pub struct Parser {
	file_base     string // "hello.fkr"
	file_name     string // /home/user/hello.fkr
	file_name_dir string // home/user
	pref          &prefs.Preferences
mut:
	scanner       &scanner.Scanner
	tok           token.Token
	prev_tok      token.Token
	peek_tok      token.Token
	peek_tok2     token.Token
	peek_tok3     token.Token
	table         &ast.Table
	builtin_mod   bool // estamos en el modulo 'builtin'?
	mod           string // current module name
	expr_mod      string
	scope         &ast.Scope
	global_scope  &ast.Scope
	imports       map[string]string // alias => mod_name
	ast_imports   []ast.Import // mod_names
	used_imports  []string // alias
	is_main_module bool
	have_dyn_custom bool
	cur_script_name string
}

/*
pub fn parse_stmt(text string, table &ast.Table, scope &ast.Scope) ast.Stmt {
	pref := &prefs.Preferences{}
	s := scanner.new_scanner(text, pref)
	mut p := Parser{
		scanner: s
		table: table
		pref: pref
		scope: scope
		global_scope: &ast.Scope{
			start_pos: 0
			parent: 0
		}
	}
	p.read_first_token()
	return p.stmt(false)
}
*/
pub fn parse_text(text string, path string, table &ast.Table, pref &prefs.Preferences, global_scope &ast.Scope) ast.File {
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

pub fn parse_files(paths []string, table &ast.Table, pref &prefs.Preferences, global_scope &ast.Scope) []ast.File {
	mut files := []ast.File{}
	for path in paths {
		files << parse_file(path, table, pref, global_scope)
	}
	return files
}

pub fn (mut p Parser) parse() ast.File {
	p.read_first_token()
	mod_name := p.file_name.all_before_last('.').all_after_last(os.path_separator)
	p.mod = p.table.qualify_module(mod_name, p.file_name)
	if p.mod == 'builtin' {
		p.builtin_mod = true
	}
	println("---- Parsing module: ${p.mod}")
	mut stmts := []ast.Stmt{}
	for p.tok.kind != .eof {
		if p.tok.kind == .key_dynamic {
			if !p.have_dyn_custom {
				stmts << p.parse_dyn_custom()
				continue
			} else {
				p.error('no se puede redefinir el offset a usar dinámicamente')
			}
		}
		if p.tok.kind == .key_import {
			stmts << p.import_stmt()
			continue
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
	p.check_unused_imports()
	p.scope.end_pos = p.tok.pos
	return ast.File{
		path: p.file_name
		mod: ast.Module{
			name: p.mod
			stmts: stmts
			scope: p.scope
			is_main: p.is_main_module
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
			stmts << p.local_stmt()
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
	if p.peek_tok.kind == .dot && name in p.imports {
		p.register_used_import(name)
	}
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

fn (mut p Parser) import_stmt() ast.Import {
	p.check(.key_import)
	mut mod_pos := p.tok.position()
	mut mod_name := p.check_name()
	mut mod_alias := mod_name
	for p.tok.kind == .dot {
		p.next()
		if p.tok.kind != .name {
			p.error_with_pos("error en la sintáxis de uso de módulo, por favor usa 'x.y.z'",
				p.tok.position())
		}
		submod_name := p.check_name()
		mod_name += '.' + submod_name
		mod_alias = submod_name
		mod_pos = mod_pos.extend(p.tok.position())
	}
	if p.tok.kind == .key_as {
		p.next()
		mod_alias = p.check_name()
		if mod_alias == mod_name.split('.').last() {
			p.error_with_pos('aquí hay un alias redundante', mod_pos.extend(p.prev_tok.position()))
		}
		mod_pos = mod_pos.extend(p.tok.position())
	}
	p.check(.semicolon)
	node := ast.Import{
		pos: mod_pos
		mod: mod_name
		alias: mod_alias
	}
	p.imports[mod_alias] = mod_name
	p.table.imports << mod_name
	p.ast_imports << node
	return node
}

pub fn (mut p Parser) top_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.key_import, .key_include {
				p.error_with_pos("tanto 'import', como 'include', se pueden usar solo al principio del archivo",
					p.tok.position())
			}
			.key_pub { 
				match p.peek_tok.kind {
					.key_const { return p.const_decl() }
					.key_extern, .key_script { return p.script_stmt() }
					.key_movement {}
					else { p.error("mal uso de la palabra clave 'pub'") }
				}
			}
			.key_script {
				return p.script_stmt()
			}
			.key_extern {
				if p.peek_tok.kind == .key_pub {
					p.error_with_pos("no se puede usar 'extern' seguido de un 'pub'", p.peek_tok.position())
				}
				match p.peek_tok.kind {
					.key_script { return p.script_stmt() }
					else { p.error("la palabra clave 'extern' solo se puede usar en conjunto a 'script': extern script xxx") }
				}
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
	is_pub := p.tok.kind == .key_pub
	if is_pub {
		p.next()
	}
	is_extern := p.tok.kind == .key_extern
	if is_extern {
		p.next()
	}
	script_pos := p.tok.position()
	p.check(.key_script)
	name_pos := p.tok.position()
	script_name := p.check_name()
	if util.contains_capital(script_name) && script_name[0].is_capital() {
		p.error_with_pos_and_details(
			'no uses el estilo PascalCase para nombrar scripts, usa el estilo camelCase',
			p.prev_tok.position(),
			"en vez de usar, por ejemplo, 'MiNameScript', use 'miNameScript'")
	}
	if script_name == 'main' {
		p.is_main_module = true
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
			is_pub: is_pub
			is_extern: is_extern
			extern_offset: extern_offset
			pos: script_pos.extend(p.prev_tok.position())
		}
	}
	mut stmts := p.parse_block()
	return ast.ScriptDecl{
		name: script_name
		mod: p.mod
		is_pub: is_pub
		is_extern: is_extern
		stmts: stmts
		pos: script_pos.extend(name_pos)
	}
}

fn (mut p Parser) const_decl() ast.Const {
	//start_pos := p.tok.position()
	is_pub := p.tok.kind == .key_pub
	if is_pub {
		p.next()
	}
	//end_pos := p.tok.position()
	//const_pos := p.tok.position()
	p.check(.key_const)
	pos := p.tok.position()
	name := p.check_name()
	mut type_const := ast.Type._auto
	if !util.contains_capital(name) {
		p.error_with_pos('los nombres de las constantes deben ser puras mayúsculas (use: "${name.to_upper()}", en vez de "${name}")',
			pos)
	}
	full_name := p.prepend_mod(name)
	if p.tok.kind == .colon {
		p.next()
		type_const = p.parse_type()
	}
	println(full_name)
	p.check(.assign)
	expr := p.expr(0)
	field := ast.Const{
		name: full_name
		mod: p.mod
		expr: expr
		pos: pos
		is_pub: is_pub
		typ: type_const
	}
	p.global_scope.register(field)
	p.check(.semicolon)
	return field
}

// Local Statements =========================================================================
fn (mut p Parser) local_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.key_var {
				return p.parse_var_stmt(false)
			}
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
	mut type_var := ast.Type._auto
	if p.tok.kind == .key_at {
		pos := p.tok.position()
		p.next()
		offset := p.tok.lit
		p.check(.number)
		if p.tok.kind == .colon {
			p.next()
			type_var = p.parse_type()
		}
		p.check(.semicolon)
		if p.scope.known_var(name.name) {
			p.error_with_pos("redefinición de '${name.name}'", name.pos)
		}
		obj := ast.ScopeObject(ast.Var{
			name: name.name
			offset: offset
			pos: name.pos
		})
		name.obj = obj
		p.scope.register(obj)
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
	//println('var stmt: "${name}", expr: ${expr}')
	p.check(.semicolon)
	if p.scope.known_var(name.name) {
		p.error_with_pos("redefinición de '${name.name}'", name.pos)
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
