// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module scanner

import os
import compiler.prefs
import compiler.token
import compiler.util

const (
	single_quote = `\'`
	double_quote = `"`
	num_sep      = `_`
)

pub struct Scanner {
pub mut:
	file_path                   string
	text                        string
	pos                         int
	line_nr                     int
	last_nl_pos                 int
	is_debug                    bool
	line_comment                bool
	prev_tok                    token.Kind
	is_started                  bool
	is_print_line_on_error      bool
	is_print_colored_error      bool
	is_print_rel_paths_on_error bool
	quote                       byte
	line_ends                   []int
	nr_lines                    int
	eofs                        int
	pref                        &prefs.Preferences
}

pub fn new_scanner(text string, pref &prefs.Preferences) &Scanner {
	mut s := &Scanner{
		pref: pref
		text: text
		is_print_line_on_error: true
		is_print_colored_error: true
		is_print_rel_paths_on_error: true
	}
	s.file_path = 'internal_memory'
	return s
}

pub fn new_scanner_file(file_path string, pref &prefs.Preferences) &Scanner {
	if !os.exists(file_path) {
		util.err('$file_path no existe')
	}
	raw_text := util.read_file(file_path) or {
		util.err(err)
		return voidptr(0)
	}
	mut s := new_scanner(raw_text, pref)
	s.file_path = file_path
	return s
}

[inline]
fn (mut s Scanner) new_token(tok_kind token.Kind, lit string, len int) token.Token {
	return token.Token{
		kind: tok_kind
		lit: lit
		line_nr: s.line_nr + 1
		pos: s.pos - len + 1
		len: len
	}
}

[inline]
fn (mut s Scanner) ident_name() string {
	start := s.pos
	s.pos++
	for s.pos < s.text.len && (util.is_name_char(s.text[s.pos]) || s.text[s.pos].is_digit()) {
		s.pos++
	}
	name := s.text[start..s.pos]
	s.pos--
	return name
}

fn filter_num_sep(txt byteptr, start int, end int) string {
	unsafe {
		mut b := malloc(end - start + 1) // add a byte for the endstring 0
		mut i1 := 0
		for i := start; i < end; i++ {
			if txt[i] != num_sep {
				b[i1] = txt[i]
				i1++
			}
		}
		b[i1] = 0 // C string compatibility
		return b.vstring_with_len(i1)
	}
}

fn (mut s Scanner) ident_hex_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	mut first_wrong_digit := `\0`
	start_pos := s.pos
	s.pos += 2 // skip '0x'
	if s.text[s.pos] == num_sep {
		s.error('separator `_` is only valid between digits in a numeric literal')
	}
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == num_sep && s.text[s.pos + 1] == num_sep {
			s.error('cannot use `_` consecutively')
		}
		if !c.is_hex_digit() && c != num_sep {
			if !c.is_letter() {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = s.pos
				first_wrong_digit = c
			}
		}
		s.pos++
	}
	if s.text[s.pos - 1] == num_sep {
		s.error('cannot use `_` at the end of a numeric literal')
	} else if start_pos + 2 == s.pos {
		s.pos-- // adjust error position
		s.error('number part of this hexadecimal is not provided')
	} else if has_wrong_digit {
		s.pos = first_wrong_digit_pos // adjust error position
		s.error('this hexadecimal number has unsuitable digit `$first_wrong_digit.str()`')
	}
	number := filter_num_sep(s.text.str, start_pos, s.pos)
	s.pos--
	return number
}

fn (mut s Scanner) ident_dec_number() string {
	mut has_wrong_digit := false
	mut first_wrong_digit_pos := 0
	mut first_wrong_digit := `\0`
	start_pos := s.pos
	// scan integer part
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == num_sep && s.text[s.pos + 1] == num_sep {
			s.error('cannot use `_` consecutively')
		}
		if !c.is_digit() && c != num_sep {
			if !c.is_letter() {
				break
			} else if !has_wrong_digit {
				has_wrong_digit = true
				first_wrong_digit_pos = s.pos
				first_wrong_digit = c
			}
		}
		s.pos++
	}
	if s.text[s.pos - 1] == num_sep {
		s.error('cannot use `_` at the end of a numeric literal')
	}
	if has_wrong_digit {
		// error check: wrong digit
		s.pos = first_wrong_digit_pos // adjust error position
		s.error('this number has unsuitable digit `$first_wrong_digit.str()`')
	}
	number := filter_num_sep(s.text.str, start_pos, s.pos)
	s.pos--
	return number
}

fn (mut s Scanner) ident_number() string {
	if s.expect('0x', s.pos) {
		return s.ident_hex_number()
	} else {
		return s.ident_dec_number()
	}
}

[inline]
fn (mut s Scanner) skip_whitespace() {
	// if s.is_vh { println('vh') return }
	for s.pos < s.text.len && s.text[s.pos].is_space() {
		// Count \r\n as one line
		if util.is_nl(s.text[s.pos]) && !s.expect('\r\n', s.pos - 1) {
			s.inc_line_number()
		}
		s.pos++
	}
}

fn (mut s Scanner) end_of_file() token.Token {
	s.eofs++
	if s.eofs > 50 {
		s.line_nr--
		panic('the end of file `$s.file_path` has been reached 50 times already, the FokerScript parser is probably stuck.\n' +
			'This should not happen. Please report the bug here, and include the last 2-3 lines of your source code:\n' +
			'https://github.com/StunxFSFS/foker/issues/new?labels=Bug')
	}
	if s.pos != s.text.len && s.eofs == 1 {
		s.inc_line_number()
	}
	s.pos = s.text.len
	return s.new_token(.eof, '', 1)
}

[inline]
fn (s Scanner) look_ahead(n int) byte {
	if s.pos + n < s.text.len {
		return s.text[s.pos + n]
	}
	return `\0`
}

pub fn (mut s Scanner) scan() token.Token {
	for {
		if s.is_started {
			s.pos++
		}
		s.is_started = true
		if s.pos >= s.text.len {
			return s.end_of_file()
		}
		s.skip_whitespace()
		//s.skip_whitespace()
		if s.pos >= s.text.len {
			return s.end_of_file()
		}
		c := s.text[s.pos]
		nextc := s.look_ahead(1)

		if util.is_name_char(c) {
			name := s.ident_name()
			next_char := s.look_ahead(1)
			kind := token.keywords[name]
			if kind != .unknown {
				return s.new_token(kind, name, name.len)
			}
			if s.pos == 0 && next_char == ` ` {
				// if a single letter name at the start of the file, increment
				// otherwise the scanner would be stuck at 's.pos = 0'
				s.pos++
			}
			return s.new_token(.name, name, name.len)
		} else if c.is_digit() {
			mut start_pos := s.pos
			for start_pos < s.text.len && s.text[start_pos] == `0` {
				start_pos++
			}
			mut prefix_zero_num := start_pos - s.pos
			if start_pos == s.text.len || (c == `0` && !s.text[start_pos].is_digit()) {
				prefix_zero_num--
			}
			s.pos += prefix_zero_num

			num := s.ident_number()
			return s.new_token(.number, num, num.len)
		}

		// all other tokens
		match c {
			`+` {
				if nextc == `+` {
					s.pos++
					return s.new_token(.inc, '', 2)
				} else if nextc == `=` {
					s.pos++
					return s.new_token(.plus_assign, '', 2)
				}
				return s.new_token(.plus, '', 1)
			}
			`-` {
				if nextc == `-` {
					s.pos++
					return s.new_token(.dec, '', 2)
				} else if nextc == `=` {
					s.pos++
					return s.new_token(.minus_assign, '', 2)
				}
				return s.new_token(.minus, '', 1)
			}
			`*` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.mul_assign, '', 2)
				}
				return s.new_token(.mul, '', 1)
			}
			single_quote, double_quote {
				ident_string := s.ident_string()
				return s.new_token(.string, ident_string, ident_string.len + 2) // + two quotes
			}
			`(` {
				return s.new_token(.lparen, '', 1)
			}
			`)` {
				return s.new_token(.rparen, '', 1)
			}
			`{` {
				return s.new_token(.lbrace, '', 1)
			}
			`}` {
				return s.new_token(.rbrace, '', 1)
			}
			`[` {
				return s.new_token(.lbracket, '', 1)
			}
			`]` {
				return s.new_token(.rbracket, '', 1)
			}
			`,` {
				return s.new_token(.comma, '', 1)
			}
			`.` {
				if nextc == `.` {
					s.pos++
					return s.new_token(.dotdot, '', 2)
				}
				return s.new_token(.dot, '', 1)
			}
			`>` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.gte, '', 2)
				}
				return s.new_token(.gt, '', 1)
			}
			`<` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.lte, '', 2)
				} else {
					return s.new_token(.lt, '', 1)
				}
			}
			`=` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.eq, '', 2)
				}
				return s.new_token(.assign, '', 1)
			}
			`:` {
				return s.new_token(.colon, '', 1)
			}
			`;` {
				return s.new_token(.semicolon, '', 1)
			}
			`!` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.neq, '', 2)
				}
				return s.new_token(.bang, '', 1)
			}
			`/` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.div_assign, '', 2)
				}
				if nextc == `/` {
					s.ignore_line()
					if !(s.text[s.pos - 1] == `\r`) {
						// fix line_nr, \n was read; the comment is marked on the next line
						s.pos--
						s.line_nr--
					}
					// Skip the comment (return the next token)
					continue
				}
				// multiline comments
				if nextc == `*` {
					mut nest_count := 1
					for nest_count > 0 {
						s.pos++
						if s.pos >= s.text.len {
							s.line_nr--
							s.error('comment not terminated')
						}
						if s.text[s.pos] == `\n` {
							s.inc_line_number()
							continue
						}
						if s.expect('/*', s.pos) {
							nest_count++
							continue
						}
						if s.expect('*/', s.pos) {
							nest_count--
						}
					}
					s.pos++
					continue
				}
				return s.new_token(.div, '', 1)
			}
			else {}
		}
		$if windows {
			if c == `\0` {
				return s.end_of_file()
			}
		}
		s.error("invalid character '${c.str()}'")
		break
	}
	return s.end_of_file()
}

fn (s &Scanner) current_column() int {
	return s.pos - s.last_nl_pos
}

fn (s &Scanner) count_symbol_before(p int, sym byte) int {
	mut count := 0
	for i := p; i >= 0; i-- {
		if s.text[i] != sym {
			break
		}
		count++
	}
	return count
}

fn (mut s Scanner) ident_string() string {
	q := s.text[s.pos]
	is_quote := q == single_quote || q == double_quote
	if is_quote {
		s.quote = q
	}
	mut n_cr_chars := 0
	mut start := s.pos
	slash := `\\`
	for {
		s.pos++
		if s.pos >= s.text.len {
			s.error('unfinished string literal')
		}
		c := s.text[s.pos]
		prevc := s.text[s.pos - 1]
		// end of string
		if c == s.quote && (prevc != slash || (prevc == slash && s.text[s.pos - 2] == slash)) {
			// handle '123\\'  slash at the end
			break
		}
		if c == `\r` {
			n_cr_chars++
		}
		if c == `\n` {
			s.inc_line_number()
		}
	}
	mut lit := ''
	if s.text[start] == s.quote {
		start++
	}
	end := s.pos
	if start <= s.pos {
		mut string_so_far := s.text[start..end]
		if n_cr_chars > 0 {
			string_so_far = string_so_far.replace('\r', '')
		}
		if string_so_far.contains('\\\n') {
			lit = trim_slash_line_break(string_so_far)
		} else {
			lit = string_so_far
		}
	}
	return lit
}

fn trim_slash_line_break(s string) string {
	mut start := 0
	mut ret_str := s
	for {
		idx := ret_str.index_after('\\\n', start)
		if idx != -1 {
			ret_str = ret_str[..idx] + ret_str[idx + 2..].trim_left(' \n\t\v\f\r')
			start = idx
		} else {
			break
		}
	}
	return ret_str
}

[inline]
fn (s &Scanner) expect(want string, start_pos int) bool {
	end_pos := start_pos + want.len
	if start_pos < 0 || start_pos >= s.text.len {
		return false
	}
	if end_pos < 0 || end_pos > s.text.len {
		return false
	}
	for pos in start_pos .. end_pos {
		if s.text[pos] != want[pos - start_pos] {
			return false
		}
	}
	return true
}

[inline]
fn (mut s Scanner) ignore_line() {
	s.eat_to_end_of_line()
	s.inc_line_number()
}

[inline]
fn (mut s Scanner) eat_to_end_of_line() {
	for s.pos < s.text.len && s.text[s.pos] != `\n` {
		s.pos++
	}
}

[inline]
fn (mut s Scanner) inc_line_number() {
	s.last_nl_pos = s.pos
	s.line_nr++
	s.line_ends << s.pos
	if s.line_nr > s.nr_lines {
		s.nr_lines = s.line_nr
	}
}

pub fn (mut s Scanner) warn(msg string) {
	pos := token.Position{
		line_nr: s.line_nr
		pos: s.pos
	}
	eprintln(util.formatted_error('advertencia:', msg, s.file_path, pos))
}

pub fn (mut s Scanner) error(msg string) {
	pos := token.Position{
		line_nr: s.line_nr
		pos: s.pos
	}
	eprintln(util.formatted_error('error:', msg, s.file_path, pos))
	exit(1)
}

pub fn (mut s Scanner) codegen(newtext string) {
	s.text += newtext
	$if debug_codegen ? {
		eprintln('scanner.codegen:\n $newtext')
	}
}

