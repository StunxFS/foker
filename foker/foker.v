// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os
import about
import compiler.ast
import compiler.prefs
import compiler.util
import compiler.parser

fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ['-h', '-a', 'help', 'ayuda']) {
		about.help()
		exit(1)
	}
	pref := prefs.parse_args_and_get_prefs()
    if pref.use_color == .always {
		util.emanager.set_support_color(true)
	}
	if pref.use_color == .never {
		util.emanager.set_support_color(false)
	}
    mut table := ast.new_table()
    mut global_scope := &ast.Scope{parent: 0}
    _ /*file*/ := parser.parse_file(pref.file, table, pref, global_scope)
    // TODO: checker.check_file(file)
    match pref.backend {
        .binary {
            /* TODO
            if pref.rom != "" { // Insertar directo en la ROM
                gen.binary.generate_and_insert_in_rom(file, pref.rom)
            } else {
                gen.binary.generate_script_file(file)
            }
            */
        }
        .decomp {
            // TODO: gen.decomp.generate(file)
        }
    }
}
