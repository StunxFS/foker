// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os
import v.depgraph
import compiler.ast
import compiler.util
import compiler.about
import compiler.prefs
import compiler.parser
import compiler.errors
import compiler.checker
import compiler.gen.binary

fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ['-h', '-a', 'help', 'ayuda']) {
		about.help()
		exit(1)
	}
	mut b := new_builder()
	b.compile()
}

struct Builder {
mut:
	pref         prefs.Preferences
	table        ast.Table
	parsed_files []ast.File
}

fn new_builder() Builder {
	return Builder{
		pref: prefs.parse_args_and_get_prefs()
		table: ast.new_table()
	}
}

fn (mut b Builder) compile() {
	if b.pref.use_color == .always {
		util.emanager.set_support_color(true)
	}
	if b.pref.use_color == .never {
		util.emanager.set_support_color(false)
	}
	mut imports := []string{}
	b.parsed_files << parser.parse_file(parser.builtins_file, b.table, b.pref)
	b.parsed_files << parser.parse_file(b.pref.file, b.table, b.pref)
	curdir := os.getwd()
	os.chdir(os.dir(b.pref.file))
	for i := 0; i < b.parsed_files.len; i++ {
		ast_file := b.parsed_files[i]
		for f in ast_file.imports {
			if f.file in imports {
				continue
			}
			b.parsed_files << parser.parse_file(f.file, b.table, b.pref)
			imports << f.file
		}
	}
	b.deps_graph()
	if !b.pref.only_check_syntax {
		mut c := checker.new_checker(b.table, b.pref)
		c.check_files(b.parsed_files)
		mut err_count := 0
		for file in b.parsed_files {
			err_count += show_reports(file.reports)
		}
		if err_count > 0 {
			exit(1)
		}
		os.chdir(curdir)
		match b.pref.backend {
			.binary {
				make_rbh_file := b.pref.rom == ''
				if make_rbh_file { // generar un archivo .rbh
					mut gen := binary.new_gen(b.pref, b.table)
					gen.gen_from_files(b.parsed_files)
				} else {
					// TODO: Inyección directa en la ROM
				}
			}
			.decomp {
				// TODO: decomp.generate(file)
			}
		}
	}
}

fn (mut b Builder) deps_graph() {
	// resolver dependencias de archivos
	graph := b.import_graph()
	deps_resolved := graph.resolve()
	if b.pref.is_verbose {
		eprintln('------ resolved dependencies graph: ------')
		eprintln(deps_resolved.display())
		eprintln('------------------------------------------')
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

// import_graph - graph of all imported modules
fn (mut b Builder) import_graph() &depgraph.DepGraph {
	mut graph := depgraph.new_dep_graph()
	for p in b.parsed_files {
		mut deps := []string{}
		if p.path !in parser.builtins {
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

fn show_reports(reports []errors.Report) int {
	mut err_count := 0
	for report in reports {
		if report.kind == .error {
			err_count++
		}
		eprintln(report.message)
	}
	return err_count
}
