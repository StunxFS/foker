// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import term
import compiler.token
import compiler.util

// Utilities ================================================================================
pub fn (mut p Parser) error(s string) {
	p.error_with_pos(s, p.tok.position())
}

pub fn (mut p Parser) warn(s string) {
	p.warn_with_pos(s, p.tok.position())
}

pub fn (mut p Parser) error_with_pos(s string, pos token.Position) {
	eprintln(util.formatted_error('error:', s, p.file_name, pos))
	exit(1)
}

pub fn (mut p Parser) error_with_pos_and_details(s string, pos token.Position, details string) {
	eprintln(util.formatted_error('error:', s, p.file_name, pos))
	eprintln('${term.bold("detalles:")} ${details}')
	exit(1)
}

pub fn (mut p Parser) warn_with_pos(s string, pos token.Position) {
	if p.pref.warns_are_errors {
		p.error_with_pos(s, pos)
	}
	if p.pref.skip_warnings {
		return
	}
	eprintln(util.formatted_error('advertencia:', s, p.file_name, pos))
}

