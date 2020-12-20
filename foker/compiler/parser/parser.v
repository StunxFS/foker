// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

// import compiler.errors
import os
import term
import compiler.token
import compiler.prefs
import compiler.util
import compiler.scanner
import compiler.ast

pub struct Parser {
	file_base     string // "hello.v"
	file_name     string // /home/user/hello.v
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
	mod_name := p.file_name.all_before_last('.')
	p.mod = p.table.qualify_module(mod_name, p.file_name)
	if p.mod == 'builtin' {
		p.builtin_mod = true
	}
	println("---- Parsing module: ${p.mod}")

	mut stmts := []ast.Stmt{}
	for p.tok.kind != .eof {
		if p.tok.kind == .key_import {
			stmts << p.import_stmt()
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
	// if p.peek_tok.kind == .dot && name in p.imports {}
	p.check(.name)
	return name
}

fn (mut p Parser) import_stmt() ast.Import {
	p.check(.key_import)
	pos := p.tok.position()
	mut fields := []ast.ImportField{}
	p.check(.lparen)
	for p.tok.kind != .rparen {
		mut mod_pos := p.tok.position()
		mut mod_name := p.check_name()
		mut mod_alias := mod_name
		for p.tok.kind == .dot {
			p.next()
			if p.tok.kind != .name {
				p.error_with_pos("error en la sintáxis de uso de módulo, por favor usar 'x.y.z'",
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
		fields << ast.ImportField{
			pos: mod_pos
			mod: mod_name
			alias: mod_alias
		}
	}
	p.check(.rparen)
	return ast.Import{
		pos: pos
		fields: fields
	}
}

pub fn (mut p Parser) top_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.key_import {
				p.error_with_pos("'import ()' solo se puede usar al principio del archivo",
					p.tok.position())
			}
			.key_pub { 
				match p.peek_tok.kind {
					.key_const { return p.const_decl() }
					.key_extern, .key_script { return p.script_stmt() }
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
			else {
				p.error('declaración de alto nivel "' + p.tok.lit + '" desconocido')
			}
		}
	}
	return ast.Stmt{}
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
	if is_extern { // extern script name; | extern script name2 at 0x90034;
		mut extern_offset := ''
		if p.pref.backend == .binary && p.tok.kind == .key_at {
			p.next()
			if p.tok.kind != .number {
				p.error('se esperaba un offset/dirección')
			}
			extern_offset = p.tok.lit
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
	p.check(.lbrace)
	p.check(.rbrace)
	return ast.ScriptDecl{
		name: script_name
		mod: p.mod
		is_pub: is_pub
		is_extern: is_extern
		pos: script_pos.extend(name_pos)
	}
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
		if util.contains_capital(name) {
			p.error_with_pos('los nombres de las constantes deben ser puras minúsculas', pos)
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
fn (mut p Parser) expr(precedence int) ast.Expr {
	mut node := ast.Expr{}
	match p.tok.kind {
		.name {
			node = p.name_expr()
		}
		.string {
			node = p.string_expr()
		}
		.number {
			node = p.parse_number_literal()
		}
		.key_true, .key_false {
			node = ast.BoolLiteral{
				lit: (p.tok.kind == .key_true).str()
				pos: p.tok.position()
			}
			p.next()
		}
		.lparen {
			p.check(.lparen)
			node = p.expr(0)
			p.check(.rparen)
			node = ast.ParExpr{
				expr: node
				pos: p.tok.position()
			}
		}
		.minus, .bang {
			node = p.prefix_expr()
		}
		else {
			if p.tok.kind != .eof {
				p.error_with_pos('expresión invalida, no se esperaba el token `${p.tok.kind.str()}`',
					p.tok.position())
			}
		}
	}
	return p.expr_with_left(node, precedence)
}

pub fn (mut p Parser) expr_with_left(left ast.Expr, precedence int) ast.Expr {
	mut node := left
	for precedence < p.tok.precedence() {
		if p.tok.kind == .dot {
			node = p.dot_expr(node)
		} else if p.tok.kind.is_infix() {
			if p.tok.kind.is_prefix() && p.tok.line_nr != p.prev_tok.line_nr {
				// added 10/2020: LATER this will be parsed as PrefixExpr instead
				p.warn_with_pos('move infix `$p.tok.kind` operator before new line (if infix intended) or use brackets for a prefix expression',
					p.tok.position())
			}
			// continue on infix expr
			node = p.infix_expr(node)
		} else if p.tok.kind in [.inc, .dec] {
			node = ast.PostfixExpr{
				op: p.tok.kind
				expr: node
				pos: p.tok.position()
			}
			p.next()
		} else {
			return node
		}
	}
	return node
}

fn (mut p Parser) infix_expr(left ast.Expr) ast.Expr {
	op := p.tok.kind
	precedence := p.tok.precedence()
	pos := p.tok.position()
	p.next()
	right := p.expr(precedence)
	return ast.InfixExpr{
		left: left
		right: right
		op: op
		pos: pos
	}
}

fn (mut p Parser) prefix_expr() ast.PrefixExpr {
	pos := p.tok.position()
	op := p.tok.kind
	p.next()
	right := p.expr(token.Precedence.prefix)
	return ast.PrefixExpr{
		op: op
		pos: pos
		right: right
	}
}

fn (mut p Parser) name_expr() ast.Expr {
	//prev_tok_kind := p.prev_tok.kind
	mut node := ast.Expr{}
	if p.tok.lit == 'fmt' { // auto-format string
		p.next()
		p.check(.lparen)
		val := p.tok.lit
		pos := p.tok.position()
		p.next()
		p.check(.rparen)
		return ast.StringLiteral{
			lit: val
			pos: pos
			autofmt: true
		}
	} else {
		node = p.parse_ident()
	}
	return node
}

pub fn (mut p Parser) parse_ident() ast.Ident {
	if p.tok.kind == .name {
		pos := p.tok.position()
		mut name := p.check_name()
		if name == '_' {
			return ast.Ident{
				tok_kind: p.tok.kind
				name: '_'
				kind: .blank_ident
				pos: pos
				//scope: p.scope
			}
		}
		if p.expr_mod.len > 0 {
			name = '${p.expr_mod}.$name'
		}
		return ast.Ident{
			tok_kind: p.tok.kind
			kind: .unresolved
			name: name
			mod: p.mod
			pos: pos
			//scope: p.scope
		}
	}
	p.error('token `$p.tok.lit` inesperado')
	return ast.Ident{
		//scope: p.scope
	}
}

fn (mut p Parser) string_expr() ast.Expr {
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

pub fn (mut p Parser) error_with_pos_and_details(s string, pos token.Position, details string) {
	eprintln(util.formatted_error('error:', s, p.file_name, pos))
	eprintln('${term.bold("detalles:")} ${details}')
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
