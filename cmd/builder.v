// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

// import compiler.gen.binary
import v.depgraph
import compiler.ast
import compiler.util
import compiler.prefs
import compiler.parser
import compiler.checker

struct Builder {
mut:
	pref         prefs.Preferences
	table        ast.Table
	parsed_files []ast.File
	imports      []string
	global_scope &ast.Scope = 0
}

fn new_builder() Builder {
	return Builder{
		pref: prefs.parse_args_and_get_prefs()
		table: ast.new_table()
		global_scope: &ast.Scope{
			parent: 0
		}
	}
}

fn (mut b Builder) compile() {
	// Vemos si el terminal soporta colores o no
	b.set_support_color()
	// Primero parseamos el archivo de bultins
	b.parsed_files << b.parse_file(parser.builtins_file)
	// Luego parseamos el módulo a compilar
	b.parsed_files << b.parse_file(b.pref.file)
	// Ahora vamos con los imports
	b.imports()
	// Si el usuario solo quiere checar la sintaxis de su script, pues nos detenemos
	// de lo contrario seguimos.
	if !b.pref.only_check_syntax {
		// Resolvemos el orden de las dependencias
		b.resolve_deps()
		// Corremos el checker
		b.checker()
		// Corremos el generador
		b.generator()
	}
	// Liberamos la memoria innecesaria
	b.go_free()
}

fn (mut b Builder) go_free() {
	unsafe {
		b.parsed_files.free()
		b.imports.free()
	}
}

fn (b &Builder) set_support_color() {
	match b.pref.use_color {
		.always { util.emanager.set_support_color(true) }
		.never { util.emanager.set_support_color(false) }
	}
}

[inline]
fn (mut b Builder) parse_file(file string) ast.File {
	return parser.parse_file(file, b.table, b.pref, b.global_scope)
}

fn (mut b Builder) imports() {
	for i := 0; i < b.parsed_files.len; i++ {
		ast_file := b.parsed_files[i]
		for f in ast_file.imports {
			if f.file in b.imports {
				continue
			}
			b.parsed_files << b.parse_file(f.file)
			b.imports << f.file
		}
	}
}

fn (mut b Builder) checker() {
	// Corremos el checker
	mut c := checker.new_checker(b.table, b.pref)
	c.check_files(b.parsed_files)
	b.check_errors()
}

fn (mut b Builder) generator() {
	match b.pref.backend {
		.binary {
			/*
			make_rbh_file := b.pref.rom == ''
				if make_rbh_file { // generar un archivo .rbh
					mut gen := binary.new_gen(b.pref, b.table)
					gen.gen_from_files(b.parsed_files)
				} else {
					// TODO: Inyección directa en la ROM
				}
			*/
		}
		.decomp {
			// TODO: decomp.generate(file)
		}
	}
}

fn (mut b Builder) check_errors() {
	mut err_count := 0
	for file in b.parsed_files {
		for report in file.reports {
			if report.kind == .error {
				err_count++
			}
			eprintln(report.message)
		}
	}
	if err_count > 0 {
		exit(1)
	}
}

fn (mut b Builder) resolve_deps() {
	// resolver dependencias de archivos
	graph := b.import_graph()
	deps_resolved := graph.resolve()
	cycles := deps_resolved.display_cycles()
	if b.pref.is_verbose {
		eprintln('------ dependencias de archivos resolvidas ------')
		eprintln(deps_resolved.display())
		eprintln('-------------------------------------------------')
	}
	if cycles.len > 1 {
		util.err('se ha detectado un importe circular entre los siguientes archivos: \n' + cycles)
	}
	mut mods := []string{}
	for node in deps_resolved.nodes {
		mods << node.name
	}
	if b.pref.is_verbose {
		eprintln('------ archivos importados ------')
		eprintln(mods.str())
		eprintln('---------------------------------')
	}
	mut reordered_parsed_files := []ast.File{}
	for m in mods {
		for pf in b.parsed_files {
			if m == pf.path {
				reordered_parsed_files << pf
			}
		}
	}
	b.parsed_files = reordered_parsed_files.clone()
}

// import_graph - graph of all imported files
fn (mut b Builder) import_graph() &depgraph.DepGraph {
	mut graph := depgraph.new_dep_graph()
	for p in b.parsed_files {
		mut deps := []string{}
		if b.pref.is_verbose {
			println('import_graph(): $p.path')
		}
		if !p.path.starts_with(parser.builtins_path) {
			deps << parser.builtins_file
		}
		for m in p.imports {
			if m.file == p.path {
				continue
			}
			deps << m.file
		}
		graph.add(p.path, deps)
	}
	return graph
}
