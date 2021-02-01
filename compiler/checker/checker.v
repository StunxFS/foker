// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

// import os
// import strings
import compiler.util
import compiler.token
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
	error_lines    []int // para evitar imprimir multiples errores para la misma linea :)
	expected_type  ast.Type
	cur_script     &ast.ScriptDecl
	const_names    map[string]token.Position
	in_for_count   int    // si checker está actualmente en un bucle for
	mod            string // nombre del modulo actual
	is_builtin_mod bool   // estamos en un modulo builtin
mut:
	expr_level     int // para evitar una recursion infinita que implique bugs en el compilador
	errors_details []string
	loop_label     string // obtiene valor cuando se está dentro de un bucle for etiquetado
	has_main       bool
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
	for stmt in ast_file.mod.stmts {
		c.expr_level = 0
		c.stmt(stmt)
	}
	c.check_scope_vars(c.file.mod.scope)
}

pub fn (mut c Checker) check_files(ast_files []ast.File) {
	for i in 0 .. ast_files.len {
		file := unsafe { &ast_files[i] }
		c.mod = file.mod.name
		c.check(file)
	}
	if !c.pref.is_library && !c.has_main {
		util.err('el módulo "$c.mod" (archivo "$c.file.path") no tiene un script de entrada principal (script main {})')
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

fn (mut c Checker) stmt(node ast.Stmt) {
	match mut node {
		ast.AssignStmt {
			if node.is_global {
				obj := (node.left as ast.Ident)
				if obj.name in c.const_names {
					c.error("variable global '$obj.name' duplicada", obj.pos)
					c.warn('previamente declarada aquí', c.const_names[obj.name])
				}
				c.const_names[obj.name] = obj.pos
			}
			c.assign_stmt(mut node)
		}
		ast.Alias {
			c.alias_stmt(mut node)
		}
		ast.CmdDecl {
			c.cmd_decl(node)
		}
		ast.ScriptDecl {
			if node.name == '$c.mod::main' && !c.has_main {
				c.has_main = true
			}
			if c.table.exists_script(node.name) {
				c.error("duplicación del script '${c.stripped_name(node.name)}'", node.pos)
				c.warn('esto fue previamente declarado aquí', c.table.scripts[node.name].pos)
			} else {
				c.table.scripts[node.name] = node
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
			c.call_stmt(mut node)
		}
		ast.CallCmdStmt { // msgbox("Stunx", 6);
			c.call_cmd_stmt(mut node)
		}
		ast.FreeStmt {
			c.ident(mut node.ident)
		}
		ast.Const {
			c.const_decl(mut node)
		}
		ast.QuestionStmt {
			if node.question.lit.len == 0 {
				c.error('se requiere un contenido aquí, esto no puede quedar vacío',
					node.question.pos)
			}
			for stmt in node.yes.stmts {
				c.stmt(stmt)
			}
			for stmt in node.no.stmts {
				c.stmt(stmt)
			}
		}
		ast.CheckgenderStmt {
			for stmt in node.boy_stmts {
				c.stmt(stmt)
			}
			for stmt in node.girl_stmts {
				c.stmt(stmt)
			}
		}
		ast.IfStmt {
			for branch in node.branches {
				if !branch.is_else && c.expr(branch.cond) != .bool {
					c.error('se espera una expresión condicional', branch.cond.position())
				}
				for stmt in branch.stmts {
					c.stmt(stmt)
				}
			}
		}
		else {} // TODO: implementar el resto de las declaraciones
	}
}

fn (mut c Checker) const_decl(mut node ast.Const) {
	if node.name in c.const_names {
		c.error("constante '${c.stripped_name(node.name)}' duplicada", node.pos)
		c.warn('previamente declarada aquí', c.const_names[node.name])
	}
	ct := c.expr(node.expr)
	if node.typ != .unknown {
		c.check_expected(ct, node.typ) or {
			c.error("no se le puede asignar un valor a la constante '${c.stripped_name(node.name)}': $err",
				node.pos)
		}
	}
	node.typ = ct
	c.const_names[node.name] = node.pos
}

fn (c &Checker) stripped_name(name string) string {
	c_mod := '$c.mod::'
	if name.starts_with(c_mod) {
		return name.all_after_last(c_mod)
	}
	return name
}

pub fn (mut c Checker) cmd_decl(node ast.CmdDecl) {
	ecmd, is_alias := c.table.exists_cmd(node.name)
	if ecmd || is_alias {
		is_builtin := node.name in c.table.builtins_cmds
		if is_alias {
			msg := "un alias contiene el nombre del comando '${c.stripped_name(node.name)}'"
			if is_builtin {
				c.error(msg, node.pos)
				c.warn('el alias se encuentra en los builtins', c.table.alias[node.name].pos)
			} else {
				c.error(msg, node.pos)
				c.warn('el alias se encuentra aquí', c.table.alias[node.name].pos)
			}
		} else {
			msg := "duplicación del comando '${c.stripped_name(node.name)}'"
			if is_builtin {
				c.error(msg, node.pos)
				c.warn('previamente declarado en los builtins, aquí', c.table.cmds[node.name].pos)
			} else {
				c.error(msg, node.pos)
				c.warn('previamente declarado aquí', c.table.cmds[node.name].pos)
			}
		}
	}
	c.table.cmds[node.name] = node
	if c.is_builtin_mod {
		c.table.builtins_cmds << node.name
	}
}

pub fn (mut c Checker) alias_stmt(mut node ast.Alias) {
	// chequear el nombre del alias
	ecmd1, alias1 := c.table.exists_cmd(node.name)
	mut all_ok := true
	if alias1 {
		c.error('este alias está duplicado', node.pos)
		c.warn('previamente declarado aquí', c.table.alias[node.name].pos)
		all_ok = false
	}
	if ecmd1 {
		c.error('ya existe un comando con este nombre, por favor use otro', node.pos)
		all_ok = false
	}
	// chequear el objetivo del alias
	node.target = if !node.target.contains('::') && node.mod != builtins_mod {
		'$c.mod::$node.target'
	} else {
		node.target
	}
	ecmd, alias := c.table.exists_cmd(node.target)
	if alias {
		c.error('no se puede crear un alias para otro alias', node.target_pos)
		all_ok = false
	}
	if !ecmd {
		c.error('no existe un comando con este nombre', node.target_pos)
		all_ok = false
	}
	if ecmd && (node.target in c.table.cmds) {
		target := c.table.cmds[node.target]
		if !target.is_pub && target.mod != c.mod {
			c.error('no se puede crear un alias para este comando porque es privado',
				node.target_pos)
			all_ok = false
		}
	}
	if all_ok {
		c.table.alias[node.name] = node
	}
}

pub fn (mut c Checker) call_cmd_stmt(mut call_cmd ast.CallCmdStmt) {
	cmd_name := call_cmd.name
	mut cmd_alias := cmd_name
	mut cmd := ast.CmdDecl{}
	mut found := false
	if !cmd_name.contains('::') && call_cmd.mod != builtins_mod {
		name_prefixed := '$call_cmd.mod::$cmd_name'
		exists_cmd, is_alias := c.table.exists_cmd(name_prefixed)
		if exists_cmd {
			if !is_alias {
				call_cmd.name = name_prefixed
				found = true
				cmd = c.table.cmds[name_prefixed]
			} else {
				found = true
				target := c.table.alias[name_prefixed].target
				cmd = c.table.cmds[target]
				cmd_alias = '$cmd_name (${c.stripped_name(target)})'
			}
		}
	}
	if !found {
		exists_cmd, is_alias := c.table.exists_cmd(cmd_name)
		if exists_cmd {
			if !is_alias {
				found = true
				cmd = c.table.cmds[cmd_name]
			} else {
				found = true
				target := c.table.alias[cmd_name].target
				cmd = c.table.cmds[target]
				cmd_alias = '$cmd_name (${c.stripped_name(target)})'
			}
		}
	}
	if !found {
		c.error("el comando '$cmd_alias' no existe", call_cmd.pos)
	}
	if !cmd.is_pub && cmd.mod != c.mod {
		c.error("el comando '$cmd_alias' es privado", call_cmd.pos)
	}
	min_required_args := cmd.params.len
	if call_cmd.args.len < min_required_args {
		c.error('se esperaba $min_required_args argumentos, pero se recibió $call_cmd.args.len',
			call_cmd.pos)
		return
	} else if call_cmd.args.len > 0 && cmd.params.len == 0 {
		c.error("no se esperaba ningún argumento para el comando '$cmd_alias'", call_cmd.pos)
		return
	} else if call_cmd.args.len > cmd.params.len {
		unexpected_arguments := call_cmd.args[min_required_args..]
		unexpected_arguments_pos := unexpected_arguments[0].pos.extend(unexpected_arguments.last().pos)
		c.error('se espera $min_required_args argumentos, pero se recibió $call_cmd.args.len',
			unexpected_arguments_pos)
		return
	}
	if call_cmd.expected_arg_types.len == 0 {
		for param in cmd.params {
			call_cmd.expected_arg_types << param.typ
		}
	}
	for i, call_arg in call_cmd.args {
		arg := cmd.params[i]
		c.expected_type = arg.typ
		typ := c.expr(call_arg.expr)
		if call_arg.expr is ast.Ident {
			i1 := call_arg.expr
			if i1.obj is ast.Var {
				if i1.obj.typ in [ast.Type.int, .long, .byte] {
					c.error('no se pueden usar variables numéricas en llamadas a comandos',
						i1.pos)
				}
			}
		} else if call_arg.expr is ast.InfixExpr || call_arg.expr is ast.ParExpr {
			c.error('no se pueden usar expresiones avanzadas en llamadas a comandos',
				call_arg.expr.position())
		}
		call_cmd.args[i].typ = typ
		c.check_expected(typ, arg.typ) or {
			c.error("$err, en el argumento ${i + 1} del comando '$cmd_alias'", call_cmd.pos)
		}
	}
}

pub fn (mut c Checker) call_stmt(mut call_stmt ast.CallStmt) {
	script_name := call_stmt.script
	if script_name == 'main' {
		c.error('no se puede hacer una llamada al script principal', call_stmt.pos)
	}
	mut s := ast.ScriptDecl{}
	mut found := false
	if !script_name.contains('::') && call_stmt.mod != builtins_mod {
		name_prefixed := '$call_stmt.mod::$script_name'
		if c.table.exists_script(name_prefixed) {
			call_stmt.script = name_prefixed
			found = true
			s = c.table.scripts[name_prefixed]
		}
	}
	if !found {
		if c.table.exists_script(script_name) {
			found = true
			s = c.table.scripts[script_name]
		}
	}
	if !found {
		c.error("el script '$script_name' no se ha encontrado", call_stmt.pos)
	}
	if !s.is_pub && s.mod != c.mod {
		c.error("el script '$script_name' es privado", call_stmt.pos)
	}
}

pub fn (mut c Checker) assign_stmt(mut assign_stmt ast.AssignStmt) {
	defer {
		c.expected_type = .unknown
	}
	// izquierda
	is_decl := assign_stmt.is_decl
	left := assign_stmt.left
	is_blank_ident := left.is_blank_ident()
	mut left_type := ast.Type.unknown
	if !is_decl && !is_blank_ident {
		left_type = c.expr(left)
		c.expected_type = left_type
	} else if assign_stmt.left_type != .unknown {
		left_type = assign_stmt.left_type
		c.expected_type = left_type
	}
	if left_type == .offset && is_decl {
		c.error("no se pueden declarar variables del tipo 'offset'", left.position())
	}
	// derecha
	right := assign_stmt.right
	mut right_type := c.expr(right)
	// le damos el tipo de la expresión a la variable
	// si esta no la tiene definida
	if left_type == .unknown {
		left_type = right_type
	}
	//
	// println('left_type -> $left_type')
	// println('right_type -> $right_type')
	//
	if right_type == .movement && !is_decl {
		c.error("no se puede usar valores de tipo 'movement' para variables ya declaradas",
			right.position())
	}
	if right_type == .string && !is_decl {
		c.error("no se pueden usar valores de tipo string en variables, use un 'text' a nivel de módulo para esto",
			right.position())
	}
	if (left_type == .string || right_type == .string) && is_decl {
		c.error("no se puede declarar variables de tipo string, use un 'text' a nivel de módulo para esto",
			right.position())
	}
	c.expected_type = left_type
	if is_decl {
		if left_type == ast.Type.int {
			if right is ast.IntegerLiteral {
				mut is_large := right.lit.len > 13
				if !is_large && right.lit.len > 8 {
					val := right.lit.i64()
					is_large = val > checker.int_max || val < checker.int_min
				}
				if is_large {
					c.error("desbordamiento en tipo implícito 'int', use el tipo 'long' en su lugar",
						right.pos)
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
				l := if left.kind == .movement { 'al movimiento' } else { 'a la constante' }
				c.error("no se puede asignar un valor $l '${c.stripped_name(left.name)}'",
					left.pos)
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
				if is_decl {
					full_name := '$left.mod::$left.name'
					if obj := c.file.mod.global_scope.find(full_name) {
						if obj is ast.Const {
							c.error("nombre de constante duplicada '$left.name'", left.pos)
						}
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
	if assign_stmt.is_native || is_blank_ident {
		return
	}
	$if debug ? {
		println('$c.file.path: $left_type = $right_type')
	}
	if !is_decl && left_type == .movement {
		c.error("no se le puede cambiar el valor a una variable del tipo 'movement'",
			left.position())
		return
	}
	// Dual sides check (compatibility check)
	c.check_expected(right_type, left_type) or {
		name := c.stripped_name((left as ast.Ident).name)
		c.error("no se le puede asignar este valor a '$name': $err", right.position())
	}
}
