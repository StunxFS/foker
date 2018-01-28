// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module util

import term

const (
	zubat_script_cli_error   = term.bold(term.red('ZubatScript: error: '))
	zubat_script_cli_warning = term.bold(term.magenta('ZubatScript: advertencia: '))
	zubat_script_cli_note    = term.bold(term.cyan('ZubatScript: nota:'))
)

pub fn err(msg string) {
	eprintln(util.zubat_script_cli_error + msg)
	exit(1)
}

pub fn warn(msg string) {
	eprintln(util.zubat_script_cli_warning + msg)
}

pub fn note(msg string) {
	eprintln(util.zubat_script_cli_note + msg)
}
