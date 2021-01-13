// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import term
import compiler.ast
import compiler.util
import compiler.token

pub fn (mut p Parser) error(s string) {
	p.error_with_pos(s, p.tok.position())
}

pub fn (mut p Parser) warn(s string) {
	p.warn_with_pos(s, p.tok.position())
}

pub fn (mut p Parser) error_and_warn(msg1 string, pos1 token.Position, msg2 string, pos2 token.Position) {
	eprintln(util.formatted_error('error:', msg1, p.file_name, pos1))
	eprintln(util.formatted_error('nota:', msg2, p.file_name, pos2))
	exit(1)
}

pub fn (mut p Parser) error_and_warn2(msg1 string, pos1 token.Position, msg2 string, pos2 token.Position, fpath string) {
	eprintln(util.formatted_error('error:', msg1, p.file_name, pos1))
	eprintln(util.formatted_error('nota:', msg2, fpath, pos2))
	exit(1)
}

pub fn (mut p Parser) error_with_pos(s string, pos token.Position) {
	eprintln(util.formatted_error('error:', s, p.file_name, pos))
	exit(1)
}

pub fn (mut p Parser) error_with_pos_and_details(s string, pos token.Position, details string) {
	eprintln(util.formatted_error('error:', s, p.file_name, pos))
	eprintln('${term.bold('detalles:')} $details')
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

pub fn (mut p Parser) mark_var_as_used(varname string) bool {
	if obj := p.scope.find(varname) {
		match mut obj {
			ast.Var {
				obj.is_used = true
				return true
			}
			else {}
		}
	}
	return false
}
