// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module scanner

import compiler.util
import compiler.token

struct Conditional {
pub mut:
	matched      bool
	else_found   bool
	skip_section bool
}

pub fn (mut s Scanner) error_with_len(msg string, len int) {
	eprintln(util.formatted_error('error:', msg, s.file_path, token.Position{
		line_nr: s.line_nr
		pos: s.pos
		len: len
	}))
	exit(1)
}

fn (mut s Scanner) pp_whitespace() bool {
	mut found := false
	for s.pos < s.text.len && s.text[s.pos].is_space() && !util.is_nl(s.text[s.pos]) {
		found = true
		s.pos++
	}
	return found
}

fn (mut s Scanner) pp_comment() {
	is_comment := (s.pos < s.text.len && s.text[s.pos] == `/` && s.look_ahead(1) in [`/`, `*`])
	if is_comment {
		s.error_with_len('los comentarios no son soportados en esta área', 2)
	}
}

fn (mut s Scanner) pp_space() {
	s.pp_comment() // no permitir comentarios al lado de las directivas: #if Ol //comment
	for s.pp_whitespace() {}
}

fn (mut s Scanner) pp_directive() {
	// skip '#'
	s.pos++
	s.pp_space()
	start_pos := s.pos
	mut len := 0
	for s.pos < s.text.len && util.is_name_char(s.text[s.pos]) {
		s.pos++
		len++
	}
	match len {
		2 {
			if s.expect('if', start_pos) {
				s.parse_pp_if()
			}
		}
		4 {
			if s.expect('elif', start_pos) {
				s.parse_pp_elif()
			} else if s.expect('else', start_pos) {
				s.parse_pp_else()
			}
		}
		5 {
			if s.expect('endif', start_pos) {
				s.parse_pp_endif()
			}
		}
		6 {
			if s.expect('define', start_pos) {
				s.parse_pp_define()
			}
		}
		else {
			s.error_with_len('directiva de preprocesador inválida', len + 1)
		}
	}
	if s.conditional_stack.len > 0 && s.conditional_stack[s.conditional_stack.len - 1].skip_section {
		// skip lines until next preprocessing directive
		mut bol := true
		for s.pos < s.text.len {
			if bol && s.text[s.pos] == `#` {
				// go back to begin of line
				s.pos -= s.current_column() - 1
				return
			}
			if s.text[s.pos] == `\n` {
				s.inc_line_number()
				bol = true
			} else if !s.text[s.pos].is_space() {
				bol = false
			}
			s.pos++
		}
	}
	s.inc_line_number()
}

fn (mut s Scanner) pp_eol() {
	s.pp_space()
	if s.pos >= s.text.len || s.text[s.pos] != `\n` {
		s.error('se esperaba una nueva línea')
	}
}

fn (mut s Scanner) parse_pp_ident() string {
	mut len := 0
	start_pos := s.pos
	for s.pos < s.text.len && util.is_name_char(s.text[s.pos]) {
		s.pos++
		len++
	}
	if len == 0 {
		s.error('se esperaba un identificador')
	}
	return s.text[start_pos..s.pos]
}

fn (mut s Scanner) parse_pp_define() {
	s.pp_space()
	identifier := s.parse_pp_ident()
	s.pp_eol()
	if s.pref.is_verbose {
		println('> scanner/pp: definiendo: $identifier')
	}
	s.pref.defines << identifier
}

fn (mut s Scanner) parse_pp_if() {
	s.pp_space()
	condition := s.parse_pp_expression()
	s.pp_eol()
	s.conditional_stack << Conditional{}
	if condition &&
		(s.conditional_stack.len == 1 || !s.conditional_stack[s.conditional_stack.len - 2].skip_section) {
		// condition true => process code within if
		s.conditional_stack[s.conditional_stack.len - 1].matched = true
	} else {
		// skip lines until next preprocessing directive
		s.conditional_stack[s.conditional_stack.len - 1].skip_section = true
	}
}

fn (mut s Scanner) parse_pp_elif() {
	s.pp_space()
	condition := s.parse_pp_expression()
	s.pp_eol()
	if s.conditional_stack.len == 0 || s.conditional_stack[s.conditional_stack.len - 1].else_found {
		s.error('no se esperaba #elif')
		return
	}
	if condition && !s.conditional_stack[s.conditional_stack.len - 1].matched &&
		(s.conditional_stack.len == 1 || !s.conditional_stack[s.conditional_stack.len - 2].skip_section) {
		// condition true => process code within if
		s.conditional_stack[s.conditional_stack.len - 1].matched = true
		s.conditional_stack[s.conditional_stack.len - 1].skip_section = false
	} else {
		// skip lines until next preprocessing directive
		s.conditional_stack[s.conditional_stack.len - 1].skip_section = true
	}
}

fn (mut s Scanner) parse_pp_else() {
	s.pp_eol()
	if s.conditional_stack.len == 0 || s.conditional_stack[s.conditional_stack.len - 1].else_found {
		s.error_with_len('no se esperaba #else', 5)
	}
	if !s.conditional_stack[s.conditional_stack.len - 1].matched &&
		(s.conditional_stack.len == 1 || !s.conditional_stack[s.conditional_stack.len - 2].skip_section) {
		// condition true => process code within if
		s.conditional_stack[s.conditional_stack.len - 1].matched = true
		s.conditional_stack[s.conditional_stack.len - 1].skip_section = false
	} else {
		// skip lines until next preprocessing directive
		s.conditional_stack[s.conditional_stack.len - 1].skip_section = true
	}
}

fn (mut s Scanner) parse_pp_endif() {
	s.pp_eol()
	if s.conditional_stack.len == 0 {
		s.error_with_len('no se esperaba #endif', 6)
	}
	s.conditional_stack.pop()
}

fn (mut s Scanner) parse_pp_symbol() bool {
	identifier := s.parse_pp_ident()
	mut defined := false
	if identifier == 'true' {
		defined = true
	} else if identifier == 'false' {
		defined = false
	} else {
		defined = identifier in s.pref.defines
	}
	return defined
}

fn (mut s Scanner) parse_pp_primary_expression() bool {
	if s.pos >= s.text.len {
		s.error('se esperaba un identificador')
	} else if util.is_name_char(s.text[s.pos]) {
		return s.parse_pp_symbol()
	} else if s.text[s.pos] == `(` {
		s.pos++
		s.pp_space()
		result := s.parse_pp_expression()
		s.pp_space()
		if s.pos < s.text.len && s.text[s.pos] == `)` {
			s.pos++
		} else {
			s.error('se esperaba `)`')
		}
		return result
	} else {
		s.error('se esperaba un identificador')
	}
	return false
}

fn (mut s Scanner) parse_pp_unary_expression() bool {
	if s.pos < s.text.len && s.text[s.pos] == `!` {
		s.pos++
		s.pp_space()
		return !s.parse_pp_unary_expression()
	}
	return s.parse_pp_primary_expression()
}

fn (mut s Scanner) parse_pp_equality_expression() bool {
	mut left := s.parse_pp_unary_expression()
	s.pp_space()
	for true {
		if s.pos < s.text.len - 1 && s.text[s.pos] == `=` && s.text[s.pos + 1] == `=` {
			s.pos += 2
			s.pp_space()
			right := s.parse_pp_unary_expression()
			left = (left == right)
		} else if s.pos < s.text.len - 1 && s.text[s.pos] == `!` && s.text[s.pos + 1] == `=` {
			s.pos += 2
			s.pp_space()
			right := s.parse_pp_unary_expression()
			left = (left != right)
		} else {
			break
		}
	}
	return left
}

fn (mut s Scanner) parse_pp_and_expression() bool {
	mut left := s.parse_pp_equality_expression()
	s.pp_space()
	start_pos := s.pos
	for s.pos < s.text.len - 1 && s.expect('and ', start_pos) {
		s.pos += 3
		s.pp_space()
		right := s.parse_pp_equality_expression()
		left = left && right
	}
	return left
}

fn (mut s Scanner) parse_pp_or_expression() bool {
	mut left := s.parse_pp_and_expression()
	s.pp_space()
	start_pos := s.pos
	for s.pos < s.text.len - 1 && s.expect('or ', start_pos) {
		s.pos += 2
		s.pp_space()
		right := s.parse_pp_and_expression()
		left = left || right
	}
	return left
}

fn (mut s Scanner) parse_pp_expression() bool {
	return s.parse_pp_or_expression()
}
