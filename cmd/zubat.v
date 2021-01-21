// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os
import compiler.ast
import compiler.util
import compiler.about
import compiler.prefs
import compiler.parser
import compiler.checker
import compiler.errors
import compiler.emitter.binary

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
	file := parser.parse_file(pref.file, table, pref)
	$if print_obj_file ? {
		println(file)
	}
	if !pref.only_check_syntax {
		mut c := checker.new_checker(table, pref)
		c.check(file)
		show_reports(file.reports)
		match pref.backend {
			.binary {
				make_rbh_file := pref.rom == ''
				if make_rbh_file { // generar un archivo .rbh
					mut gen := binary.new_gen(file, pref, table)
					gen.gen()
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

fn show_reports(reports []errors.Report) {
	mut err_count := 0
	for report in reports {
		if report.kind == .error {
			err_count++
		}
		eprintln(report.message)
	}
	if err_count > 0 {
		exit(1)
	}
}
