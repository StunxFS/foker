// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module scanner

import os
import term
import compiler.token
import compiler.prefs
import compiler.util
import compiler.errors

const (
	single_quote = `\'`
	double_quote = `"`
	num_sep 	 = `_`
)

pub struct Scanner {
pub mut:
	file_path			string
	text				string
	pos					int
	line_nr				int
	last_nl_pos			int // para calcular columna
	is_started			bool
	line_comment		string
	quote				byte // esto es usado para denotar como está compuesto el string actual: con " o '
	line_ends			[]int  // las posiciciones de los finales de liena del archivo de codigo fuente (i.e. \n signs)
	nr_lines			int // numero total de las lineas en el archivo de codigo fuente que está siendo escaneado
	comments_mode		CommentsMode
	eofs				int
	pref				&prefs.Preferences
	errors				[]errors.Error
	warnings			[]errors.Warning
	last_err_line		int
}

pub enum CommentsMode {
	skip_comments
	parse_comments
}

pub fn new_scanner_file(file_path string, comments_mode CommentsMode, pref &prefs.Preferences) &Scanner {
	if !os.exists(file_path) {
		fserror("${file_path} no existe")
	}
	raw_text := util.read_file(file_path) or {
		fserror(err)
		return voidptr(0)
	}
	mut s := new_scanner(raw_text, comments_mode, pref)
	s.file_path = file_path
	return s
}

pub fn new_scanner(text string, comments_mode CommentsMode, pref &prefs.Preferences) &Scanner {
	mut s := &Scanner {
		pref: pref
		text: text
		comments_mode: comments_mode
	}
	s.file_path = 'internal_memory'
	return s
}

[inline] fn (mut s Scanner) new_token(tok_kind token.Kind, lit string, len int) token.Token {
	return token.Token{
		kind: tok_kind
		lit: lit
		line_nr: s.line_nr + 1
		pos: s.pos - len + 1
		len: len
	}
}

[inline] fn (mut s Scanner) ident_name() string {
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
		mut b := malloc(end - start + 1)
		mut i1 := 0
		for i := start; i < end; i++ {
			if txt[i] != num_sep {
				b[i1] = txt[i]
				i1++
			}
		}
		b[i1] = 0
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
		s.error('el separador `_` solo es valido entre digitos en un literal númerico')
	}
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == num_sep && s.text[s.pos + 1] == num_sep {
			s.error('no se puede usar `_` repetidamente')
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
		s.error('no se puede usar `_` en la parte final de un literal númerico')
	} else if start_pos + 2 == s.pos {
		s.pos--
		s.error('la parte numerica de este hexadecimal no se provee')
	} else if has_wrong_digit {
		s.pos = first_wrong_digit_pos
		s.error('este número hexadecimal tiene el digito no soportado `${first_wrong_digit.str()}`')
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
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == num_sep && s.text[s.pos + 1] == num_sep {
			s.error('no se puede usar `_` consecutivamente')
		}
		if !c.is_digit() && c != num_sep {
			if !c.is_digit() {
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
		s.error('no se puede usar `_` en el final de un literal númerico')
	}
	if has_wrong_digit {
		s.pos = first_wrong_digit_pos
		s.error('este número tiene el dígito no permitido `${first_wrong_digit.str()}`')
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

[inline] fn (mut s Scanner) skip_whitespace() {
	for s.pos < s.text.len && s.text[s.pos].is_space() {
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
		s.error('the end of file `$s.file_path` has been reached 50 times already, the fokerscript parser is probably stuck.\n' +
			'This should not happen. Please report the bug here, and include the last 2-3 lines of your source code:\n' +
			'https://github.com/vlang/v/issues/new?labels=Bug&template=bug_report.md')
	}
	if s.pos != s.text.len && s.eofs == 1 {
		s.inc_line_number()
	}
	s.pos = s.text.len
	return s.new_token(.eof, '', 1)
}

[inline] fn (s Scanner) look_ahead(n int) byte {
	if s.pos + n < s.text.len {
		return s.text[s.pos + n]
	} else {
		return `\0`
	}
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
				s.pos++
			}
			return s.new_token(.name, name, name.len)
		} else if c.is_digit() {
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
					return s.new_token(.mult_assign, '', 2)
				}
				return s.new_token(.mul, '', 1)
			}
			`%` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.mod_assign, '', 2)
				}
				return s.new_token(.mod, '', 1)
			}
			`?` {
				return s.new_token(.question, '', 1)
			}
			single_quote, double_quote {
				ident_string := s.ident_string()
				return s.new_token(.string, ident_string, ident_string.len + 2)
			}
			`(` {
				return s.new_token(.lpar, '', 1)
			}
			`)` {
				return s.new_token(.rpar, '', 1)
			}
			`{` {
				return s.new_token(.lcbr, '', 1)
			}
			`}` {
				return s.new_token(.rcbr, '', 1)
			}
			`$` {
				return s.new_token(.dollar, '', 1)
			}
			`,` {
				return s.new_token(.comma, '', 1)
			}
			`.` {
				if nextc == `.` {
					s.pos++
					if s.text[s.pos + 1] == `.` {
						s.pos++
						return s.new_token(.ellipsis, '', 3)
					}
					return s.new_token(.dotdot, '', 2)
				}
				return s.new_token(.dot, '', 1)
			}
			`>` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.ge, '', 2)
				}
				return s.new_token(.gt, '', 1)
			}
			`<` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.le, '', 2)
				}
				return s.new_token(.lt, '', 1)
			}
			`=` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.eq, '', 2)
				} else {
					return s.new_token(.assign, '', 2)
				}
			}
			`:` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.decl_assign, '', 2)
				} else if nextc == `:` {
					s.pos++
					return s.new_token(.doblecolon, '', 1)
				} else {
					return s.new_token(.colon, '', 1)
				}
			}
			`;` {
				return s.new_token(.semicolon, '', 1)
			}
			`!` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.ne, '', 2)
				} else {
					return s.new_token(.not, '', 1)
				}
			}
			`/` {
				if nextc == `=` {
					s.pos++
					return s.new_token(.div_assign, '', 2)
				}
				if nextc == `/` {
					start := s.pos + 1
					s.ignore_line()
					mut comment_line_end := s.pos
					if s.text[s.pos - 1] == `\r` {
						comment_line_end--
					} else {
						s.pos--
						s.line_nr--
					}
					if s.comments_mode == .parse_comments {
						s.line_comment = s.text[start+1..comment_line_end]
						mut comment := s.line_comment.trim_space()
						mut is_separate_line_comment := true
						for j := start - 2; j >= 0 && s.text[j] != `\n`; j-- {
							if s.text[j] !in [`\t`, ` `] {
								is_separate_line_comment = false
							}
						}
						if is_separate_line_comment {
							comment = '\x01' + comment
						}
						return s.new_token(.comment, comment, comment.len + 2)
					}
					continue
				}
				// MULTILINE COMMENTS
				if nextc == `*` {
					start := s.pos + 2
					mut nest_count := 1
					// skip comment
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
					if s.comments_mode == .parse_comments {
						comment := s.text[start.. (s.pos - 1)].trim_space()
						return s.new_token(.comment, comment, comment.len + 4)
					}
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
		s.error('carácter inválido `${c.str()}`')
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
	//q := s.text[s.pos]
	//is_quote := q == single_quote || q == double_quote
	mut n_cr_chars := 0
	mut start := s.pos
	slash := `\\`
	for {
		s.pos++
		if s.pos >= s.text.len {
			s.error("literal de cadena no terminado")
		}
		c := s.text[s.pos]
		prevc := s.text[s.pos - 1]
		if c == s.quote && (prevc != slash || (prevc == slash && s.text[s.pos - 2] == slash)) {
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
	mut end := s.pos
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
	println(lit)
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

[inline] fn (s &Scanner) expect(want string, start_pos int) bool {
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

/*fn (mut s Scanner) debug_tokens() {
	s.pos = 0
	s.is_started = false
	s.is_debug = true
	fname := s.file_path.all_after_last(os.path_separator)
	println('\n===DEBUG TOKENS $fname===')
	for {
		tok := s.scan()
		tok_kind := tok.kind
		lit := tok.lit
		print(tok_kind.str())
		if lit != '' {
			println(' `$lit`')
		} else {
			println('')
		}
		if tok_kind == .eof {
			println('============ END OF DEBUG TOKENS ==================')
			break
		}
	}
}*/

[inline] fn (mut s Scanner) ignore_line() {
	s.eat_to_end_of_line()
	s.inc_line_number()
}

[inline] fn (mut s Scanner) eat_to_end_of_line() {
	for s.pos < s.text.len && s.text[s.pos] != `\n` {
		s.pos++
	}
}

[inline] fn (mut s Scanner) inc_line_number() {
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
	s.warnings << errors.Warning{
		file_path: s.file_path
		pos: pos
		reporter: .scanner
		message: util.formatted_error('warn:', msg, s.file_path, pos)
	}
}

pub fn (mut s Scanner) note(msg string) {
	pos := token.Position{
		line_nr: s.line_nr
		pos: s.pos
	}
	s.warnings << errors.Warning{
		file_path: s.file_path
		pos: pos
		reporter: .scanner
		message: util.formatted_error('note:', msg, s.file_path, pos)
	}
}

pub fn (mut s Scanner) error(msg string) {
	pos := token.Position{
		line_nr: s.line_nr
		pos: s.pos
	}
	if pos.line_nr != s.last_err_line {
		s.errors << errors.Error{
			file_path: s.file_path
			pos: pos
			reporter: .scanner
			message: util.formatted_error('error:', msg, s.file_path, pos)
		}
		s.last_err_line = pos.line_nr
	}
}

pub fn fserror(s string) {
	util.fserror('scanner error', s)
}

pub fn (mut s Scanner) codegen(newtext string) {
	// codegen makes sense only during normal compilation feeding
	// code generated FokerScript code.
	if s.comments_mode == .skip_comments {
		s.text += newtext
		$if debug_codegen ? {
			eprintln('scanner.codegen:\n ${newtext}')
		}
	}
}
