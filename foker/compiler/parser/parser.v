// Copyright (c) 2020 Pizcofy. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module parser

import os
import compiler.token
import compiler.prefs
import compiler.util
//import compiler.errors
import compiler.scanner
import compiler.ast

pub struct Parser {
	file_base		string // "hello.v"
	file_name		string // /home/user/hello.v
	file_name_dir	string // home/user
	pref			&prefs.Preferences
mut:
	scanner			&scanner.Scanner
	tok				token.Token
	prev_tok		token.Token
	peek_tok		token.Token
	peek_tok2		token.Token
	peek_tok3		token.Token
	table			&ast.Table
	builtin_mod		bool // estamos en el modulo 'builtin'?
	mod				string // current module name
	expr_mod		string
	scope			&ast.Scope
	global_scope	&ast.Scope
	imports			map[string]string // alias => mod_name
	ast_imports		[]ast.Import // mod_names
	used_imports	[]string // alias
}

/*pub fn parse_stmt(text string, table &ast.Table, scope &ast.Scope) ast.Stmt {
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
}*/

pub fn parse_text(text string, path string, table &ast.Table, pref &prefs.Preferences, global_scope &ast.Scope) ast.File {
	s := scanner.new_scanner(text, pref)
	mut p := Parser{
		scanner: s
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
	if p.file_name.starts_with('builtin') {
		p.builtin_mod = true
	}
	mut stmts := []ast.Stmt{}
	for {
		if p.tok.kind == .key_import {
			stmts << p.import_stmts()
			continue
		}
		break
	}
	for {
		stmts << p.top_stmt()
	}
	
	p.scope.end_pos = p.tok.pos
	return ast.File{
		path: p.file_name
		mod: ast.Module{
			name: p.file_name.all_before_last('.')
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

fn (mut p Parser) next() {
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.peek_tok2
	p.peek_tok2 = p.peek_tok3
	p.peek_tok3 = p.scanner.scan()
}

fn (mut p Parser) check(expected token.Kind) {
	if p.tok.kind != expected {
		match p.tok.kind {
			.name {
				p.error("'${p.tok.lit}' inesperado, se esperaba '${expected.str()}'")
			}
			.number {
				p.error("no se esperaba un literal númerico, se esperaba '${expected.str()}'")
			}
			.string {
				p.error("no se esperaba un literal de cadena, se esperaba '${expected.str()}'")
			}
			else {
				p.error("'${p.tok.kind.str()}' inesperado, se esperaba '${expected.str()}'")
			}
		}
	}
	p.next()
}

fn (mut p Parser) check_name() string {
	name := p.tok.lit
	//if p.peek_tok.kind == .dot && name in p.imports {}
	p.check(.name)
	return name
}

fn (mut p Parser) import_stmts() []ast.Import {
	p.check(.key_import)
	pos := p.tok.position()
	p.check(.lparen)
	mut imports := []ast.Import{}
	for p.tok.kind != .rparen {
		mut mod_name := p.check_name()
		mut mod_alias := mod_name
		for p.tok.kind == .dot {
			p.next()
			if p.tok.kind != .name {
				p.error_with_pos("error en la sintáxis de uso de módulo, por favor usar 'x.y.z'", pos)
			}
			submod_name := p.check_name()
			mod_name += '.' + submod_name
			mod_alias = submod_name
		}
		if p.tok.kind == .key_as {
			p.next()
			mod_alias = p.check_name()
			if mod_alias == mod_name.split('.').last() {
				p.error_with_pos("import alias '${mod_name} as ${mod_alias}' is redundant", p.prev_tok.position())
			}
		}
		imports << ast.Import{
			pos: pos
			mod: mod_name
			alias: mod_alias
		}
	}
	p.check(.rparen)
	return imports
}

pub fn (mut p Parser) top_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.key_import {
				p.error_with_pos("'import ()' solo se puede usar al principio del archivo", p.tok.position())
			}
			.key_pub {
				match p.peek_tok.kind {
					.key_const {
						return p.const_decl()
					}
					else {
						p.error('mal uso de la palabra clave `pub`')
					}
				}
			}
			.key_extern {
				match p.peek_tok.kind {
					.key_script {}
					else {
						p.error("la palabra clave 'extern' solo se puede usar en conjunto a 'script'")
					}
				}
			}
			.key_const {
				return p.const_decl()
			}
			else {
				p.error('declaración de alto nivel "' + p.tok.lit + '" desconocido')
			}
		}
	}
	return ast.Stmt{}
}

fn (mut p Parser) const_decl() ast.ConstDecl {
	start_pos := p.tok.position()
	is_pub := p.tok.kind == .key_pub
	if is_pub {
		p.next()
	}
	end_pos := p.tok.position()
	const_pos := p.tok.position()
	p.check(.key_const)
	if p.tok.kind != .lparen {
		p.error_with_pos("en una declaración 'const' se espera '( ... )'", const_pos)
	}
	p.next()
	mut fields := []ast.ConstField{}
	for {
		if p.tok.kind == .eof {
			p.error_with_pos("se espera un ')' para cerrar la declaración", const_pos)
		}
		if p.tok.kind == .rparen {
			break
		}
		pos := p.tok.position()
		name := p.check_name()
		if !util.contains_capital(name) {
			p.warn_with_pos('los nombres de las constantes deben incluir puras mayúsculas', pos)
		}
		full_name := p.prepend_mod(name)
		p.check(.assign)
		expr := p.expr(0)
		field := ast.ConstField{
			name: full_name
			mod: p.mod
			expr: expr
			pos: pos
		}
		fields << field
		p.global_scope.register(field)
	}
	p.check(.rparen)
	return ast.ConstDecl{
		pos: start_pos.extend(end_pos)
		fields: fields
		is_pub: is_pub
	}
}

// Exprs ====================================================================================
fn (mut p Parser) string_expr() ast.Expr {
	mut node := ast.Expr{}
	val := p.tok.lit
	pos := p.tok.position()
	p.next()
	return ast.StringLiteral{
		lit: val
		pos: pos
	}
}

fn (mut p Parser) parse_number_literal() ast.Expr {
	lit := p.tok.lit
	pos := p.tok.position()
	p.next()
	return ast.IntegerLiteral{
		lit: lit
		pos: pos
	}
}

fn (mut p Parser) dot_expr(left ast.Expr) ast.Expr {
	p.next()
	name_pos := p.tok.position()
	field_name := p.check_name()
	return ast.SelectorExpr{
		expr: left
		field_name: field_name
		pos: name_pos
	}
}

fn (mut p Parser) enum_val() ast.EnumVal {
	p.check(.dot)
	val := p.check_name()
	return ast.EnumVal{
		val: val
		pos: p.tok.position()
	}
}

// Utilities ================================================================================
pub fn (mut p Parser) error(s string) {
	p.error_with_pos(s, p.tok.position())
}

pub fn (mut p Parser) warn(s string) {
	p.warn_with_pos(s, p.tok.position())
}

pub fn (mut p Parser) error_with_pos(s string, pos token.Position) {
	eprintln(util.formatted_error('error:', s, p.file_name, pos))
	exit(1)
}

pub fn (mut p Parser) warn_with_pos(s string, pos token.Position) {
	if p.pref.warns_are_errors {
		p.error_with_pos(s, pos)
	}
	if p.pref.skip_warnings {
		return
	}
	eprintln(util.formatted_error('advertencia:', s, p.file_name, pos))
}
