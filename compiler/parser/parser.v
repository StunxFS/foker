// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import os
import compiler.token
import compiler.prefs
import compiler.util
import compiler.scanner
import compiler.ast

const (
	exepath       = os.dir(os.real_path(prefs.zsexe_path()))
	builtins_file = os.join_path(exepath, 'compiler', 'builtins.zs')
)

pub struct Parser {
	file_base     string // "hello.fkr"
	file_name     string // /home/user/hello.fkr
	file_name_dir string // home/user
	pref          &prefs.Preferences
mut:
	scanner         &scanner.Scanner
	tok             token.Token
	prev_tok        token.Token
	peek_tok        token.Token
	peek_tok2       token.Token
	peek_tok3       token.Token
	table           &ast.Table
	expr_mod        string
	scope           &ast.Scope
	have_dyn_custom bool
	cur_script_name string
	inside_if       bool
	inside_for      bool
	consts_names    []string
	movs_tmp        int
}

fn parse_text(text string, path string, table &ast.Table, pref &prefs.Preferences) ast.File {
	mut p := Parser{
		scanner: scanner.new_scanner(text, pref)
		file_name: path
		file_base: os.base(path)
		file_name_dir: os.dir(path)
		table: table
		pref: pref
		scope: &ast.Scope{
			start_pos: 0
			parent: 0
		}
	}
	return p.parse()
}

pub fn parse_file(path string, table &ast.Table, pref &prefs.Preferences) ast.File {
	mut p := Parser{
		scanner: scanner.new_scanner_file(path, pref)
		table: table
		file_name: path
		file_base: os.base(path)
		file_name_dir: os.dir(path)
		pref: pref
		scope: &ast.Scope{
			start_pos: 0
			parent: 0
		}
	}
	return p.parse()
}

[inline]
fn (mut p Parser) get_builtins_stmt() []ast.Stmt {
	builtins_code := util.read_file(builtins_file) or { panic(err) }
	mut b_file := if p.file_name != builtins_file { parse_text(builtins_code, builtins_file,
			p.table, p.pref) } else { ast.File{} }
	return b_file.prog.stmts
}

pub fn (mut p Parser) parse() ast.File {
	p.read_first_token()
	mut stmts := p.get_builtins_stmt()
	if p.pref.is_verbose {
		println("> Parseando archivo '$p.file_name'")
	}
	for p.tok.kind != .eof {
		if p.tok.kind == .key_dynamic {
			if p.pref.backend == .decomp {
				p.error("no se puede usar la declaración 'dynamic' en decomp")
			}
			if !p.have_dyn_custom {
				stmts << p.parse_dyn_custom()
				continue
			} else {
				p.error('no se puede redefinir el offset a usar dinámicamente')
			}
		}
		if p.tok.kind == .key_include {
			if p.pref.backend == .decomp {
				p.error("'include' no es soportado en el backend de decomp")
			}
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
				eprintln('se ha analizado $c declaraciones hasta ahora del script $p.cur_script_name ...')
			}
			if c > 1000000 {
				p.error_with_pos('se ha analizado $c declaraciones del script $p.cur_script_name, el analizador probablemente esté bloqueado',
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
	extern_bad_msg := "la palabra clave 'extern' solo se puede usar en conjunto a 'script': 'extern script xxx;'"
	for {
		match p.tok.kind {
			.key_include {
				if p.pref.backend == .binary {
					p.error("'include' se puede usar solo al principio del archivo")
				} else {
					p.error("'include' no es soportado en el backend de decomp")
				}
			}
			.key_script {
				return p.script_stmt()
			}
			.key_extern {
				match p.peek_tok.kind {
					.key_script { return p.script_stmt() }
					else { p.error(extern_bad_msg) }
				}
			}
			.key_cmd {
				return p.parse_cmd_stmt()
			}
			.key_alias {
				return p.parse_alias_stmt()
			}
			.key_const {
				return p.const_decl()
			}
			.key_text {
				return p.text_decl()
			}
			.key_var {
				return p.parse_var_stmt(true)
			}
			.key_movement {
				return ast.ExprStmt{
					expr: p.movement_expr(false)
				}
			}
			else {
				p.error('declaración de alto nivel "' + p.tok.lit + '" desconocido')
			}
		}
	}
	return ast.Stmt{}
}

fn (mut p Parser) parse_alias_stmt() ast.Stmt {
	p.check(.key_alias)
	alias_name_pos := p.tok.position()
	alias_name := p.check_name()
	ecmd1, alias1 := p.table.exists_cmd(alias_name)
	if alias1 {
		p.error_with_pos('ya existe un alias con este nombre, por favor use otro', alias_name_pos)
	}
	if ecmd1 {
		p.error_with_pos('ya existe un comando con este nombre, por favor use otro', alias_name_pos)
	}
	p.check(.assign)
	alias_target_pos := p.tok.position()
	alias_target := p.check_name()
	ecmd, alias := p.table.exists_cmd(alias_target)
	if alias {
		p.error_with_pos('no se puede declarar un alias para otro alias', alias_target_pos)
	}
	if !ecmd {
		p.error_with_pos('no existe un comando con este nombre', alias_target_pos)
	}
	p.check(.semicolon)
	// println('alias $alias_name = $alias_target;')
	if p.file_name == builtins_file {
		p.table.builtins_cmds << alias_name
	}
	p.table.alias[alias_name] = ast.Alias{alias_target, alias_name_pos}
	return ast.Stmt{}
}

fn (mut p Parser) parse_cmd_stmt() ast.Stmt {
	p.check(.key_cmd)
	name_pos := p.tok.position()
	name := p.check_name()
	p.check(.lparen)
	mut params := []ast.Param{}
	mut params_name := []string{}
	for p.tok.kind != .rparen {
		pos := p.tok.position()
		param_name := p.check_name()
		if param_name in params_name {
			p.error_with_pos('argumento `$param_name` duplicado', pos)
		}
		params_name << param_name
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
				has_def_val: true
			}
		} else {
			params << ast.Param{
				name: param_name
				typ: typ_param
				pos: pos
				has_def_val: false
			}
		}
		if p.tok.kind == .comma {
			p.next()
			continue
		}
	}
	p.check(.rparen)
	p.check(.semicolon)
	ecmd, is_alias := p.table.exists_cmd(name)
	if ecmd || is_alias {
		is_builtin := name in p.table.builtins_cmds
		if is_alias {
			msg := "un alias contiene el nombre del comando '$name'"
			if is_builtin {
				p.error_and_warn2(msg, name_pos, 'el alias se encuentra en los builtins',
					p.table.alias[name].pos, builtins_file)
			} else {
				p.error_and_warn(msg, name_pos, 'el alias se encuentra aquí', p.table.alias[name].pos)
			}
		} else {
			msg := "duplicación del comando '$name'"
			if is_builtin {
				p.error_and_warn2(msg, name_pos, 'previamente declarado en los builtins, aquí',
					p.table.cmds[name].pos, builtins_file)
			} else {
				p.error_and_warn(msg, name_pos, 'previamente declarado aquí', p.table.cmds[name].pos)
			}
		}
	}
	// chequear el correcto uso de la declaración de parámetros
	bad_msg := 'solo se pueden declarar argumentos con valores por defecto al final de la declaración'
	for i, param in params {
		next_n := i + 1
		if next_n < params.len {
			if param.has_def_val && !params[next_n].has_def_val {
				p.error_with_pos(bad_msg, param.pos)
			}
		}
	}
	if p.file_name == builtins_file {
		p.table.builtins_cmds << name
	}
	cmd := ast.CmdDecl{
		name: name
		params: params
		pos: name_pos
	}
	p.table.cmds[name] = cmd
	return cmd
}

fn (mut p Parser) parse_dyn_custom() ast.Stmt {
	if p.pref.backend == .binary {
		p.check(.key_dynamic)
		p.have_dyn_custom = true
		dyn_offset := p.tok.lit
		pos := p.tok.position()
		p.check(.number)
		pptpe := p.prev_tok.position().extend(pos)
		if dyn_offset.to_lower().starts_with('0x') {
			p.error_with_pos('por favor no inicie la dirección con `0x` o `0X`', pptpe)
		}
		if dyn_offset == '800000' {
			p.error_with_pos('esto es innecesario, la dirección que se usa por defecto es esta',
				pptpe)
		}
		p.check(.semicolon)
		return ast.DynamicStmt{
			pos: pos
			dyn_offset: dyn_offset
		}
	} else {
		p.error('esto no es soportado en el backend de decomp')
	}
	return ast.Stmt{}
}

fn (mut p Parser) script_stmt() ast.Stmt {
	is_extern := p.tok.kind == .key_extern
	if is_extern {
		p.next()
	}
	if p.file_name == builtins_file {
		p.error('no se pueden declarar scripts en el archivo de builtins')
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
			is_extern: is_extern
			extern_offset: extern_offset
			pos: script_pos.extend(p.prev_tok.position())
		}
	}
	mut stmts := p.parse_block()
	spenp := script_pos.extend(name_pos)
	if p.table.exists_script(script_name) {
		p.error_and_warn("duplicación del script '$script_name'", spenp, 'esto fue previamente declarado aquí',
			p.table.scripts[script_name].pos)
	}
	cmd := ast.ScriptDecl{
		name: script_name
		is_extern: is_extern
		stmts: stmts
		pos: spenp
	}
	p.table.scripts[script_name] = cmd
	return cmd
}

fn (mut p Parser) const_decl() ast.Const {
	// start_pos := p.tok.position()
	// end_pos := p.tok.position()
	// const_pos := p.tok.position()
	p.check(.key_const)
	pos := p.tok.position()
	name := p.check_name()
	mut type_const := ast.Type._auto
	if !util.is_pure_capital(name) {
		p.error_with_pos('los nombres de las constantes deben ser puras mayúsculas',
			pos)
	}
	if name in p.consts_names {
		p.error_with_pos("constante '$name' duplicada", pos)
	}
	p.consts_names << name
	if p.tok.kind == .colon {
		p.next()
		type_const = p.parse_type()
	}
	p.check(.assign)
	expr := p.expr(0)
	if type_const == .string {
		p.error_with_pos("en vez de usar 'const' para strings, use 'text'", pos)
	}
	field := ast.Const{
		name: name
		expr: expr
		pos: pos
		typ: type_const
	}
	p.scope.register(field)
	p.check(.semicolon)
	return field
}

fn (mut p Parser) text_decl() ast.Stmt {
	p.check(.key_text)
	pos := p.tok.position()
	name := p.check_name()
	if !util.is_pure_capital(name) {
		p.error_with_pos('los nombres de las constantes de cadenas deben ser puras mayúsculas',
			pos)
	}
	if name in p.consts_names {
		p.error_with_pos("constante de cadena '$name' duplicada", pos)
	}
	p.consts_names << name
	p.check(.assign)
	expr := p.expr(0)
	field := ast.Const{
		name: name
		expr: expr
		pos: pos
		typ: .string
	}
	p.scope.register(field)
	p.check(.semicolon)
	return field
}

// ===== Local Statements =========================================================================
fn (mut p Parser) local_stmt() ast.Stmt {
	for {
		match p.tok.kind {
			.name {
				// llamadas a comandos: msgbox("string", 23);
				return p.parse_call_stmt()
			}
			.key_var {
				return p.parse_var_stmt(false)
			}
			.key_free {
				return p.parse_free_stmt()
			}
			.key_if {
				return p.if_stmt()
			}
			.key_question {
				return p.question_stmt()
			}
			.key_checkgender {
				return p.checkgender_stmt()
			}
			.key_continue, .key_break {
				if p.inside_for {
					tok := p.tok
					line := p.tok.line_nr
					p.next()
					mut label := ''
					if p.tok.line_nr == line && p.tok.kind == .name {
						label = p.check_name()
					}
					p.check(.semicolon)
					return ast.BranchStmt{
						kind: tok.kind
						label: label
						pos: tok.position()
					}
				} else {
					k := if p.tok.kind == .key_continue { 'continue' } else { 'break' }
					p.error("no se puede usar '$k' fuera de un ciclo for")
					return ast.Stmt{}
				}
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

fn (mut p Parser) parse_call_stmt() ast.Stmt {
	//
	return ast.Stmt{}
}
