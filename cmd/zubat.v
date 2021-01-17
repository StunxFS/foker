// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os
import compiler.ast
import compiler.util
import compiler.about
import compiler.prefs
import compiler.parser

// import compiler.checker
// import compiler.emitter.binary
fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ['-h', '-a', 'help', 'ayuda']) {
		about.help()
		exit(1)
	}
	go_compile()
}

fn go_compile() {
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
		// mut c := checker.new_checker(table, pref)
		// c.check(file)
		match pref.backend {
			.binary {
				/*
				$if bingen_test ? {
					binary.bingen_to_file(file, table, pref) or {
						util.err(err)
						exit(1)
					}
				}
				*/
			}
			.decomp {
				// TODO: decomp.generate(file)
			}
		}
	}
}

fn show_reports(reports []util.Report) {
	mut err_count := 0
	for report in reports {
		if report.kind == .error {
			err_count++
		}
		eprintln(report.msg)
	}
	if err_count > 0 {
		exit(1)
	}
}
