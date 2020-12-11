// Copyright (c) 2020 Pizcofy. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module util

import term

const (
	foker_script_cli_error = term.bold(term.red('FokerScript CLI: error: '))
	foker_script_cli_warning = term.bold(term.magenta('FokerScript CLI: advertencia: '))
	foker_script_cli_note = term.bold(term.cyan('FokerScript CLI: nota:'))
)

pub fn err(msg string) {
	eprintln(foker_script_cli_error + msg)
	exit(1)
}

pub fn warn(msg string) {
	eprintln(foker_script_cli_warning + msg)
}

pub fn note(msg string) {
	eprintln(foker_script_cli_note + msg)
}
