// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import os
import compiler.token
import compiler.prefs
import compiler.scanner
import compiler.ast

pub const (
	exepath           = os.dir(os.real_path(prefs.zsexe_path()))
	stdlib_path       = os.join_path(exepath, 'compiler', 'stdlib')
	builtins_file     = os.join_path(exepath, 'compiler', 'stdlib', 'builtins.zs')
	builtins_bin_file = os.join_path(exepath, 'compiler', 'stdlib', 'builtins_bin.zs')
)

pub struct Parser {
	file_base     string // "hello.zs"
	file_name     string // /home/user/hello.zs
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
	imports         []string // importes locales, para evitar duplicación
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

pub fn (mut p Parser) parse() ast.File {
	p.read_first_token()
	mut stmts := []ast.Stmt{}
	mut imports := []ast.Import{}
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
		if p.tok.kind == .key_import {
			imports << p.import_stmt()
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
		imports: imports
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
	stmts := p.parse_block_no_scope(false)
	p.close_scope()
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

fn (mut p Parser) import_stmt() ast.Import {
	p.check(.key_import)
	mut is_std := false
	if p.tok.kind == .name {
		if p.tok.lit != 'std' {
			p.error("se espera 'std:'")
		}
		p.check(.name)
		p.check(.colon)
		is_std = true
	}
	pos := p.tok.position()
	to_import := p.tok.lit.replace('/', os.path_separator)
	file := if is_std { os.join_path(stdlib_path, to_import) } else { to_import }
	if file in p.imports {
		p.error('el archivo a importar ya está importado')
	}
	p.imports << file
	p.check(.string)
	p.check(.semicolon)
	return ast.Import{
		pos: pos
		file: file
	}
}

pub fn (mut p Parser) top_stmt() ast.Stmt {
	extern_bad_msg := "la palabra clave 'extern' solo se puede usar en conjunto a 'script': 'extern script xxx;'"
	for {
		match p.tok.kind {
			.key_raw {
				return p.parse_raw_stmt()
			}
			.key_import {
				p.error("'import' solo puede ir al comienzo del archivo")
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

fn (mut p Parser) parse_raw_stmt() ast.Stmt {
	p.check(.key_raw)
	mut pos := p.tok.position()
	mut raw_text := p.tok.lit
	p.check(.raw_text)
	for p.tok.kind == .raw_text {
		raw_text += p.tok.lit
		pos = pos.extend(p.tok.position())
		p.next()
	}
	p.check(.semicolon)
	return ast.RawStmt{
		text: raw_text
		pos: pos
	}
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
			p.error_with_pos("el nombre del parámetro '$param_name' es un duplicado",
				pos)
		}
		params_name << param_name
		p.check(.colon)
		typ_param := p.parse_type()
		params << ast.Param{
			name: param_name
			typ: typ_param
			pos: pos
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
					p.table.alias[name].pos)
			} else {
				p.error_and_warn(msg, name_pos, 'el alias se encuentra aquí', p.table.alias[name].pos)
			}
		} else {
			msg := "duplicación del comando '$name'"
			if is_builtin {
				p.error_and_warn2(msg, name_pos, 'previamente declarado en los builtins, aquí',
					p.table.cmds[name].pos)
			} else {
				p.error_and_warn(msg, name_pos, 'previamente declarado aquí', p.table.cmds[name].pos)
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
	p.cur_script_name = script_name
	if is_extern { // extern script name; | extern script name2 at 0x90034;
		mut extern_offset := ''
		if p.pref.backend == .binary && p.tok.kind == .key_at {
			p.next()
			extern_offset = p.tok.lit
			p.check(.number)
			if !extern_offset.to_lower().starts_with('0x') {
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

/*
fn (mut p Parser) check_const_name(name string, pos token.Position) {
	mut is_pure_capital := false
	for ch in name {
		is_pure_capital = ch.is_capital()
	}
	if !is_pure_capital {
		p.error_with_pos('los nombres de las constantes deben ser puras mayúsculas',
			pos)
	}
}
*/
fn (mut p Parser) const_decl() ast.Const {
	// start_pos := p.tok.position()
	// end_pos := p.tok.position()
	// const_pos := p.tok.position()
	p.check(.key_const)
	pos := p.tok.position()
	name := p.check_name()
	mut type_const := ast.Type.unknown
	// p.check_const_name(name, pos)
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
	if expr is ast.IntegerLiteral && name !in p.table.constantes {
		p.table.constantes[name] = (expr as ast.IntegerLiteral).lit.int()
	}
	return field
}

fn (mut p Parser) text_decl() ast.Stmt {
	p.check(.key_text)
	pos := p.tok.position()
	name := p.check_name()
	// p.check_const_name(name, pos)
	if name in p.consts_names {
		p.error_with_pos("constante '$name' de texto duplicada", pos)
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
				if p.peek_tok.kind == .lparen {
					// llamadas a comandos: msgbox("string", 23);
					return p.parse_call_stmt()
				} else {
					// myvar = newvalue;
					// TODO
				}
			}
			.key_var {
				return p.parse_var_stmt(false)
			}
			.key_free {
				return p.parse_free_stmt()
			}
			.key_call {
				return p.parser_call_script_stmt()
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
			.key_raw {
				return p.parse_raw_stmt()
			}
			else {
				p.error('declaración de nivel local "' + p.tok.lit + '" desconocido')
			}
		}
	}
	return ast.Stmt{}
}

fn (mut p Parser) parser_call_script_stmt() ast.Stmt {
	p.check(.key_call)
	script_pos := p.tok.position()
	script := p.check_name()
	p.check(.semicolon)
	return ast.CallStmt{
		pos: script_pos
		script: script
	}
}

fn (mut p Parser) parse_type() ast.Type {
	typ_name := p.check_name()
	if typ_name !in ast.type_names {
		p.error_with_pos('se esperaba uno de los siguientes tipos: ' + ast.type_names.join(', '),
			p.prev_tok.position())
	}
	t := ast.get_type_from_string(typ_name)
	return if t != .unknown {
		t
	} else {
		ast.Type.unknown
	}
}

fn (mut p Parser) check_undefined_variables(expr ast.Expr, val ast.Expr) {
	match val {
		ast.Ident {
			if expr is ast.Ident {
				if expr.name == val.name {
					p.error_with_pos("variable indefinida '$val.name'", val.pos)
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
	mut type_var := ast.Type.unknown
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
			is_used: p.file_name == builtins_file || p.file_name == builtins_bin_file
		})
		name.obj = obj
		p.scope.register(obj)
		return ast.AssignStmt{
			left: name
			offset: offset
			pos: pos
			left_type: type_var
			is_decl: true
		}
	}
	if p.tok.kind == .colon {
		p.check(.colon)
		type_var = p.parse_type()
	}
	if is_top_level && p.tok.kind == .assign {
		p.error('no se pueden definir variables en el ámbito global')
	}
	p.next()
	pos := p.tok.position()
	expr := p.expr(0)
	p.check_undefined_variables(name, expr)
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
		left: name
		op: token.Kind.assign
		right: expr
		pos: pos
		is_decl: true
		left_type: type_var
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
	cmd_pos := p.tok.position()
	cmd_name := p.check_name()
	p.check(.lparen)
	args := p.parse_call_args()
	last_pos := p.tok.position()
	p.check(.rparen)
	p.check(.semicolon)
	return ast.CallCmdStmt{
		pos: cmd_pos.extend(last_pos)
		name: cmd_name
		args: args
	}
}

fn (mut p Parser) parse_call_args() []ast.CallArg {
	mut args := []ast.CallArg{}
	start_pos := p.tok.position()
	for p.tok.kind != .rparen {
		if p.tok.kind == .eof {
			p.error_with_pos('final del archivo inesperado alcanzado, mientras se analiza el argumento de llamada',
				start_pos)
		}
		arg_start_pos := p.tok.position()
		e := p.expr(0)
		pos := arg_start_pos.extend(p.prev_tok.position())
		args << ast.CallArg{
			expr: e
			pos: pos
		}
		if p.tok.kind != .rparen {
			p.check(.comma)
		}
	}
	return args
}
