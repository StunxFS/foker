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

// import compiler.gen.binary
fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ['-h', '-a', 'help', 'ayuda']) {
		about.help()
		exit(1)
	}
	compile()
}

fn compile() {
	pref := prefs.parse_args_and_get_prefs()
	if pref.use_color == .always {
		util.emanager.set_support_color(true)
	}
	if pref.use_color == .never {
		util.emanager.set_support_color(false)
	}
	mut table := ast.new_table()
	mut parsed_files := []ast.File{}
	mut imports := []string{}
	parsed_files << parser.parse_file(parser.builtins_file, table, pref)
	parsed_files << parser.parse_file(pref.file, table, pref)
	curdir := os.getwd()
	os.chdir(os.dir(pref.file))
	for i := 0; i < parsed_files.len; i++ {
		ast_file := parsed_files[i]
		for f in ast_file.imports {
			if f.file in imports {
				continue
			}
			parsed_files << parser.parse_file(f.file, table, pref)
			imports << f.file
		}
	}
	// resolver dependencias de archivos
	graph := import_graph(parsed_files)
	deps_resolved := graph.resolve()
	if pref.is_verbose {
		eprintln('------ resolved dependencies graph: ------')
		eprintln(deps_resolved.display())
		eprintln('------------------------------------------')
	}
	mut mods := []string{}
	for node in deps_resolved.nodes {
		mods << node.name
	}
	if pref.is_verbose {
		eprintln('------ archivos importados ------')
		eprintln(mods.str())
		eprintln('---------------------------------')
	}
	mut reordered_parsed_files := []ast.File{}
	for m in mods {
		for pf in parsed_files {
			if m == pf.path {
				reordered_parsed_files << pf
			}
		}
	}
	if !pref.only_check_syntax {
		mut c := checker.new_checker(table, pref)
		c.check_files(reordered_parsed_files)
		mut err_count := 0
		for file in reordered_parsed_files {
			err_count += show_reports(file.reports)
		}
		if err_count > 0 {
			exit(1)
		}
		os.chdir(curdir)
		match pref.backend {
			.binary {
				/*
				make_rbh_file := pref.rom == ''
				if make_rbh_file { // generar un archivo .rbh
					mut gen := binary.new_gen(file, pref, table)
					gen.gen()
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
}

// import_graph - graph of all imported modules
fn import_graph(parsed_files []ast.File) &depgraph.DepGraph {
	mut graph := depgraph.new_dep_graph()
	for p in parsed_files {
		mut deps := []string{}
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
