// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module util

import term

const (
	zubat_script_cli_error = term.bold(term.red('ZubatScript CLI: error: '))
	zubat_script_cli_warning = term.bold(term.magenta('ZubatScript CLI: advertencia: '))
	zubat_script_cli_note = term.bold(term.cyan('ZubatScript CLI: nota:'))
)

pub fn err(msg string) {
	eprintln(zubat_script_cli_error + msg)
	exit(1)
}

pub fn warn(msg string) {
	eprintln(zubat_script_cli_warning + msg)
}

pub fn note(msg string) {
	eprintln(zubat_script_cli_note + msg)
}
