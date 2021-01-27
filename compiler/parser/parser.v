// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import os
import compiler.token
import compiler.prefs
import compiler.scanner
import compiler.ast

pub const (
	exepath       = os.dir(os.real_path(prefs.zsexe_path()))
	stdlib_path   = os.join_path(exepath, 'stdlib')
	builtins_path = os.join_path(stdlib_path, 'builtins')
	builtins_file = os.join_path(builtins_path, 'builtins.zs')
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
	scope           &ast.Scope
	global_scope    &ast.Scope
	have_dyn_custom bool
	cur_script_name string
	inside_if       bool
	inside_for      bool
	movs_tmp        int
	is_main         bool
	is_builtin      bool
	mod_name        string
	ast_imports     []ast.Import      // mod_names
	used_imports    []string          // alias
	imports         map[string]string // alias => mod_name
	expr_mod        string
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

fn (mut p Parser) set_mod_name() {
	if p.file_name.starts_with(parser.stdlib_path) {
		if p.is_builtin {
			p.mod_name = 'std::builtins::builtins'
		} else {
			p.mod_name = p.file_name.replace(parser.stdlib_path, 'std').all_before_last('.zs').replace(os.path_separator,
				'::')
		}
	} else {
		p.mod_name = p.file_name.all_after_last(p.file_name_dir + os.path_separator).all_before_last('.zs').replace(os.path_separator,
			'::')
	}
	if p.pref.is_verbose {
		println('Parser.set_mod_name(): $p.mod_name')
	}
}

pub fn (mut p Parser) parse() ast.File {
	p.read_first_token()
	p.is_main = p.file_name == p.pref.file
	p.is_builtin = p.file_name.starts_with(parser.builtins_path)
	p.set_mod_name()
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
	p.check_unused_imports()
	p.scope.end_pos = p.tok.pos
	return ast.File{
		path: p.file_name
		imports: imports
		mod: ast.Module{
			name: p.mod_name
			stmts: stmts
			scope: p.scope
			global_scope: p.global_scope
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
}

fn (mut p Parser) check(expected token.Kind) {
	if p.tok.kind == expected {
		p.next()
	} else {
		expected_str := match expected {
			.name { 'un nombre' }
			.number { 'un literal numérico' }
			.string { 'un literal de cadena' }
			else { "'" + expected.str() + "'" }
		}
		label := if p.tok.kind.is_keyword() { 'palabra clave ' } else { '' }
		label2 := if p.tok.kind.is_keyword() { 'inesperada' } else { 'inesperado' }
		match p.tok.kind {
			.name { p.error("'$p.tok.lit' inesperado, se esperaba $expected_str") }
			.number { p.error('no se esperaba un literal numérico, se esperaba $expected_str') }
			.string { p.error('no se esperaba un literal de cadena, se esperaba $expected_str') }
			.eof { p.error('no se esperaba el final del archivo, se esperaba $expected_str') }
			else { p.error("$label'$p.tok.kind.str()' $label2, se esperaba $expected_str") }
		}
	}
}

fn (mut p Parser) check_name() string {
	name := p.tok.lit
	if p.peek_tok.kind == .doblecolon && name in p.imports {
		p.register_used_import(name)
	}
	p.check(.name)
	return name
}

fn (mut p Parser) check_module_name() string {
	mod := p.check_name()
	if !p.known_import(mod) {
		p.error_with_pos("el módulo '$mod' no está importado", p.prev_tok.position())
	}
	return mod
}

fn (mut p Parser) import_stmt() ast.Import {
	import_pos := p.tok.position()
	p.check(.key_import)
	mut pos := p.tok.position()
	mut path := p.check_name()
	mut mod_alias := path
	mut complete_mod := mod_alias
	mut import_node := ast.Import{
		pos: import_pos.extend(pos)
	}
	path = match path {
		'std' { parser.stdlib_path }
		else { os.join_path(p.pref.file_dir, path) }
	}
	import_node = ast.Import{
		pos: import_node.pos
		mod_pos: import_node.mod_pos
		alias_pos: import_node.alias_pos
		mod: mod_alias
		alias: mod_alias
	}
	for p.tok.kind == .doblecolon {
		p.next()
		s_pos := p.tok.position()
		if p.tok.kind != .name {
			p.error_with_pos("error en la sintáxis de módulo, por favor use la forma 'x::y::z'",
				s_pos)
		}
		if import_pos.line_nr != s_pos.line_nr {
			p.error_with_pos("'import' y el submódulo deben estar en la misma línea",
				s_pos)
		}
		mod_alias = p.check_name()
		path = os.join_path(path, mod_alias)
		pos = pos.extend(s_pos)
		import_node = ast.Import{
			pos: import_pos.extend(pos)
			mod_pos: pos
			alias_pos: s_pos
			mod: mod_alias
			alias: mod_alias
		}
		complete_mod += '::$mod_alias'
	}
	mod_name := import_node.mod
	if p.tok.kind == .key_as {
		p.next()
		alias_pos := p.tok.position()
		mod_alias = p.check_name()
		if mod_alias == mod_name {
			p.error_with_pos("el alias para el importe '$complete_mod as $mod_alias' es redundante",
				p.prev_tok.position())
		}
		import_node = ast.Import{
			pos: import_node.pos.extend(alias_pos)
			mod_pos: import_node.mod_pos
			alias_pos: alias_pos
			mod: import_node.mod
			alias: mod_alias
		}
	}
	if os.is_dir(path) {
		p.error_with_pos('no se pueden importar directorios', import_node.pos)
	}
	path_zs := '${path}.zs'
	if !os.exists(path_zs) {
		p.error_with_pos('no se puede importar este módulo, ya que no existe', import_node.mod_pos)
	}
	if p.is_builtin {
		p.register_used_import(mod_alias)
	}
	import_node = ast.Import{
		...import_node
		file: path_zs
	}
	p.check(.semicolon)
	//
	if mod_alias in p.imports {
		p.error_with_pos('ya hay un módulo importado con este nombre, puede usar un alias para resolver esto',
			import_node.pos)
	}
	p.imports[mod_alias] = complete_mod
	p.table.imports << mod_name
	p.ast_imports << import_node
	//
	return import_node
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
			.key_pub {
				match p.peek_tok.kind {
					.key_var { return p.parse_var_stmt(true) }
					.key_const { return p.const_decl() }
					.key_text { return p.text_decl() }
					.key_script { return p.script_stmt() }
					.key_movement { return ast.ExprStmt{
							expr: p.movement_expr(false)
						} }
					.key_cmd { return p.parse_cmd_stmt() }
					else { p.error("mal uso de la palabra clave 'pub'") }
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

fn (mut p Parser) dont_use_name_imports(name string, pos token.Position) {
	if name in p.imports {
		p.error_with_pos('este nombre ya está siendo usado por un módulo importado',
			pos)
	}
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
	p.check(.assign)
	from_mod := p.peek_tok.kind == .doblecolon
	mut alias_target_pos := p.tok.position()
	mut alias_target := if from_mod { p.check_module_name() } else { p.check_name() }
	if from_mod {
		p.next()
		alias_target_pos = alias_target_pos.extend(p.tok.position())
		alias_target += '::$p.check_name()'
	}
	p.check(.semicolon)
	if p.file_name == parser.builtins_file {
		p.table.builtins_cmds << alias_name
	}
	return ast.Alias{
		target: alias_target
		target_pos: alias_target_pos
		name: alias_name
		pos: alias_name_pos
		mod: p.mod_name
	}
}

fn (mut p Parser) parse_cmd_stmt() ast.Stmt {
	is_pub := p.tok.kind == .key_pub
	if is_pub {
		p.next()
	}
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
	cmd := ast.CmdDecl{
		name: p.prepend_mod(name)
		params: params
		pos: name_pos
		mod: p.mod_name
		is_pub: is_pub || p.is_builtin
	}
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
		p.error('esto no es soportado por el backend de decomp')
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
	if p.is_builtin {
		p.error('no se pueden declarar scripts en los archivos de builtins')
	}
	script_pos := p.tok.position()
	p.check(.key_script)
	name_pos := p.tok.position()
	mut script_name := p.check_name()
	p.dont_use_name_imports(script_name, name_pos)
	p.cur_script_name = script_name
	if !is_extern && p.pref.build_mode != .direct && !p.is_main {
		p.error_with_pos('no se pueden declarar scripts en archivos importados, ' +
			'esto solo está permitido para scripts externos y en el modo de inyección directa en la ROM',
			name_pos)
	}
	if is_extern { // extern script name; | extern script name2 at 0x90034;
		mut extern_offset := ''
		if p.pref.backend == .binary && p.tok.kind == .key_at {
			p.next()
			extern_offset = p.tok.lit
			eoff_pos := p.tok.position()
			p.check(.number)
			if !extern_offset.to_lower().starts_with('0x') {
				p.error_with_pos('se esperaba un offset/dirección (0xXXXXX)', eoff_pos)
			}
		} else {
			p.error_with_pos(
				'solo en el backend de decomp se puede usar esta forma de declaración, ' +
				'en el backend de binario debe proporcionar un offset', name_pos)
		}
		p.check(.semicolon)
		return ast.ScriptDecl{
			name: script_name
			is_extern: is_extern
			extern_offset: extern_offset
			is_pub: is_pub
			pos: script_pos.extend(p.prev_tok.position())
		}
	}
	mut stmts := p.parse_block()
	spenp := script_pos.extend(name_pos)
	nsn := p.prepend_mod(script_name)
	script := ast.ScriptDecl{
		name: nsn
		is_extern: is_extern
		stmts: stmts
		pos: spenp
		is_pub: is_pub
		mod: p.mod_name
	}
	return script
}

fn (mut p Parser) const_decl() ast.Const {
	// start_pos := p.tok.position()
	// end_pos := p.tok.position()
	// const_pos := p.tok.position()
	is_pub := p.tok.kind == .key_pub
	if is_pub {
		p.next()
	}
	const_mov_err := "no se pueden declarar constantes del tipo 'movement', use una declaración 'movement' para esto"
	p.check(.key_const)
	pos := p.tok.position()
	name := p.check_name()
	p.dont_use_name_imports(name, pos)
	mut type_const := ast.Type.unknown
	// p.check_const_name(name, pos)
	if p.tok.kind == .colon {
		p.next()
		type_const = p.parse_type()
		if type_const == .movement {
			p.error_with_pos(const_mov_err, pos)
		}
	}
	p.check(.assign)
	if p.tok.kind == .key_movement {
		p.error_with_pos(const_mov_err, pos)
	}
	expr := p.expr(0)
	if type_const == .string {
		p.error_with_pos("en vez de usar 'const' para strings, use 'text'", pos)
	}
	field := ast.Const{
		name: p.prepend_mod(name)
		mod: p.mod_name
		expr: expr
		pos: pos
		typ: type_const
		is_builtin: p.is_builtin
		is_pub: is_pub
	}
	p.global_scope.register(field)
	p.check(.semicolon)
	if expr is ast.IntegerLiteral && name !in p.table.constantes {
		p.table.constantes[name] = (expr as ast.IntegerLiteral).lit.int()
	}
	return field
}

fn (mut p Parser) text_decl() ast.Stmt {
	is_pub := p.tok.kind == .key_pub
	if is_pub {
		p.next()
	}
	p.check(.key_text)
	pos := p.tok.position()
	name := p.check_name()
	p.dont_use_name_imports(name, pos)
	// p.check_const_name(name, pos)
	p.check(.assign)
	expr := p.expr(0)
	field := ast.Const{
		name: p.prepend_mod(name)
		mod: p.mod_name
		expr: expr
		pos: pos
		typ: .string
		is_builtin: p.is_builtin
		is_pub: is_pub
	}
	p.global_scope.register(field)
	p.check(.semicolon)
	return field
}

// ===== Local Statements =========================================================================
fn (mut p Parser) local_stmt() ast.Stmt {
	for {
		is_ident := p.peek_tok.kind == .doblecolon && p.peek_tok2.kind == .name
		match p.tok.kind {
			.name {
				if p.peek_tok.kind == .lparen || (is_ident && p.peek_tok3.kind == .lparen) {
					// llamadas a comandos: msgbox("string", 23), mymod::mycmd();
					return p.parse_call_stmt()
				} else if (p.peek_tok.kind == .bang && p.peek_tok2.kind == .lparen)
					|| (is_ident && p.peek_tok3.kind == .bang) {
					// intento de usar una macro: macro!(), mymod::macro!() - TODO
					p.error('el soporte de macros aún no está implementado')
				} else {
					// myvar = newvalue;
					return p.parse_assign_stmt()
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
			.lbrace {
				pos := p.tok.position()
				return ast.Block{
					stmts: p.parse_block()
					pos: pos
				}
			}
			else {
				p.error('declaración de nivel local "' + p.tok.lit + '" desconocida')
			}
		}
	}
	return ast.Stmt{}
}

fn (mut p Parser) parser_call_script_stmt() ast.Stmt {
	p.check(.key_call)
	mut script_pos := p.tok.position()
	mut script := p.check_name()
	if p.tok.kind == .doblecolon {
		if p.pref.backend == .decomp || (p.pref.backend == .binary && p.pref.build_mode == .direct) {
			p.next()
			script += '::' + p.tok.lit
			script_pos = script_pos.extend(p.tok.position())
			p.check(.name)
		} else {
			p.next()
			p.error(
				'solo se pueden llamar scripts de otros módulos por el backend de decomp y el backend de binario en ' +
				'modo de escritura directa')
		}
	}
	p.check(.semicolon)
	return ast.CallStmt{
		pos: script_pos
		script: script
		mod: p.mod_name
	}
}

fn (mut p Parser) parse_type() ast.Type {
	mut typ_name := ''
	if p.tok.kind == .key_movement {
		p.next()
		return .movement
	} else {
		typ_name = p.check_name()
	}
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
					p.error_with_pos("variable '$val.name' indefinida", val.pos)
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

fn (mut p Parser) parse_assign_stmt() ast.Stmt {
	left := p.name_expr()
	op := p.tok.kind
	if p.tok.kind.is_assign() {
		p.check(p.tok.kind)
	} else {
		p.error('se espera un operador de asignación')
	}
	expr := p.expr(0)
	p.check(.semicolon)
	return ast.AssignStmt{
		right: expr
		left: left
		op: op
	}
}

fn (mut p Parser) parse_var_stmt(is_top_level bool) ast.Stmt {
	is_pub := p.tok.kind == .key_pub
	if is_pub && is_top_level {
		p.next()
	}
	p.check(.key_var)
	mut pos := p.tok.position()
	mut name := p.parse_ident()
	p.dont_use_name_imports(name.name, name.pos)
	if is_top_level && p.pref.backend == .decomp {
		p.error('no se pueden declarar variables en el ámbito global en decomp')
	}
	if is_top_level && name.name == '_' {
		p.error_with_pos("no se puede usar '_' como nombre de una variable global", p.prev_tok.position())
	}
	mut type_var := ast.Type.unknown
	if p.tok.kind == .key_at {
		pos = p.tok.position()
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
		obj := ast.ScopeObject(ast.Var{
			name: p.prepend_mod(name.name)
			mod: p.mod_name
			offset: offset
			pos: name.pos
			is_used: p.is_builtin
			is_global: true
			is_builtin: p.is_builtin
			is_pub: is_pub
			typ: type_var
		})
		name.obj = obj
		p.global_scope.register(obj)
		return ast.AssignStmt{
			left: name
			offset: offset
			pos: pos
			left_type: type_var
			is_decl: true
			is_global: true
			is_native: true
		}
	}
	if p.tok.kind == .colon {
		p.check(.colon)
		type_var = p.parse_type()
	}
	if is_top_level && p.tok.kind == .assign {
		p.error('no se pueden definir variables en el ámbito global')
	}
	if p.tok.kind != .assign && !is_top_level {
		p.error_with_pos('no puede usar esta sintaxis en variables locales, debe asignar un valor',
			name.pos)
	}
	p.check(.assign)
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
		typ: type_var
	})
	name.obj = obj
	p.scope.register(obj)
	return ast.AssignStmt{
		left: name
		left_type: type_var
		op: token.Kind.assign
		right: expr
		pos: pos
		is_decl: true
	}
}

fn (mut p Parser) parse_free_stmt() ast.Stmt {
	p.check(.key_free)
	pos := p.tok.position()
	var := p.name_expr()
	p.check(.semicolon)
	return ast.FreeStmt{
		ident: (var as ast.Ident)
		pos: pos
	}
}

fn (mut p Parser) parse_call_stmt() ast.Stmt {
	mut cmd_pos := p.tok.position()
	from_mod := p.peek_tok.kind == .doblecolon
	mut cmd_name := if from_mod { p.check_module_name() } else { p.check_name() }
	if from_mod {
		p.next()
		cmd_name += '::' + p.tok.lit
		cmd_pos = cmd_pos.extend(p.tok.position())
		p.check(.name)
	}
	p.check(.lparen)
	args := p.parse_call_args()
	last_pos := p.tok.position()
	p.check(.rparen)
	p.check(.semicolon)
	return ast.CallCmdStmt{
		pos: cmd_pos.extend(last_pos)
		name: cmd_name
		args: args
		mod: p.mod_name
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
