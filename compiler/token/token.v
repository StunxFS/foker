// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module token

// Token represents a single token in the Wolk lexer.
pub struct Token {
pub mut:
	kind     Kind
	filepath string // archivo desde donde se obtiene este token
	lit      string
	len      int
	line_nr  int
	pos      int
}

pub fn (t Token) str() string {
	return 'token.Token{kind: $t.kind, lit: "$t.lit", pos: $t.position()}'
}

pub struct Position {
pub:
	filepath string // archivo desde donde se obtiene esta posición
	len      int
	line_nr  int
	pos      int
}

pub fn (pos Position) str() string {
	return 'token.Position{ filepath: "$pos.filepath", line_nr: $pos.line_nr, pos: $pos.pos, len: $pos.len }'
}

pub fn (pos Position) extend(end Position) Position {
	return {
		pos |
		len: end.pos - pos.pos + end.len
	}
}

[inline]
pub fn (tok &Token) position() Position {
	return Position{
		len: tok.len
		line_nr: tok.line_nr - 1
		pos: tok.pos
		filepath: tok.filepath
	}
}

// Kind distinguishes between different types of tokens in the Wolk lexer.
pub enum Kind {
	unknown
	eof
	// identifiers and literals
	name
	number
	string
	char
	// operators
	plus
	minus
	mul
	div
	inc // ++
	dec // --
	eq
	neq
	lt
	gt
	lte
	gte
	assign
	plus_assign // +=
	minus_assign // -=
	div_assign
	mul_assign
	// delimeters
	comma
	colon
	semicolon
	bang
	dot
	dotdot
	dollar
	lparen
	rparen
	lbrace
	rbrace
	lbracket
	rbracket
	raw_text
	// keywords
	keyword_begin
	key_import
	key_script
	key_cmd
	key_var
	key_const
	key_dynamic
	key_movement
	key_checkgender
	key_boy
	key_girl
	key_extern
	key_free
	key_text
	key_alias
	key_call // para: call my_script;
	key_raw
	key_match
	key_if
	key_elif
	key_else
	key_and
	key_or
	key_not
	key_question
	key_yes
	key_no
	key_as
	key_at
	key_true
	key_false
	key_continue
	key_break
	keyword_end
	_end_
}

pub fn (k Kind) is_keyword() bool {
	return (int(k) > int(Kind.keyword_begin))
}

pub fn (k Kind) str() string {
	return tokens_str[int(k)]
}

const (
	nr_tokens  = int(Kind._end_)
	tokens_str = build_tokenstr()
)

// build_keys - genera un mapa con keywords de tipo string:
// keywords['return'] == .key_return
// NB: Esto es pub debido a un bug raro en el compilador de V
pub fn build_keys() map[string]Kind {
	mut res := map[string]Kind{}
	for t in int(Kind.keyword_begin) + 1 .. int(Kind.keyword_end) {
		key := tokens_str[t]
		res[key] = Kind(t)
	}
	return res
}

pub const (
	keywords = build_keys()
)

fn build_tokenstr() []string {
	mut k := []string{len: nr_tokens}
	k[Kind.unknown] = 'unknown'
	k[Kind.eof] = 'eof'
	k[Kind.name] = 'name'
	k[Kind.number] = 'number'
	k[Kind.string] = 'string'
	k[Kind.char] = 'char'
	k[Kind.plus] = '+'
	k[Kind.minus] = '-'
	k[Kind.mul] = '*'
	k[Kind.div] = '/'
	k[Kind.inc] = '++'
	k[Kind.dec] = '--'
	k[Kind.eq] = '=='
	k[Kind.neq] = '!='
	k[Kind.lt] = '<'
	k[Kind.gt] = '>'
	k[Kind.lte] = '<='
	k[Kind.gte] = '>='
	k[Kind.assign] = '='
	k[Kind.plus_assign] = '+=' // +=
	k[Kind.minus_assign] = '-='
	k[Kind.div_assign] = '/='
	k[Kind.mul_assign] = '*='
	k[Kind.comma] = ','
	k[Kind.colon] = ':'
	k[Kind.semicolon] = ';'
	k[Kind.bang] = '!'
	k[Kind.dot] = '.'
	k[Kind.dotdot] = '..'
	k[Kind.dollar] = '$'
	k[Kind.lparen] = '('
	k[Kind.rparen] = ')'
	k[Kind.lbrace] = '{'
	k[Kind.rbrace] = '}'
	k[Kind.lbracket] = '['
	k[Kind.rbracket] = ']'
	k[Kind.raw_text] = 'raw text'
	k[Kind.key_import] = 'import'
	k[Kind.key_script] = 'script'
	k[Kind.key_cmd] = 'cmd'
	k[Kind.key_var] = 'var'
	k[Kind.key_const] = 'const'
	k[Kind.key_dynamic] = 'dynamic'
	k[Kind.key_movement] = 'movement'
	k[Kind.key_checkgender] = 'checkgender'
	k[Kind.key_boy] = 'boy'
	k[Kind.key_girl] = 'girl'
	k[Kind.key_extern] = 'extern'
	k[Kind.key_free] = 'free'
	k[Kind.key_text] = 'text'
	k[Kind.key_alias] = 'alias'
	k[Kind.key_call] = 'call'
	k[Kind.key_raw] = 'raw'
	k[Kind.key_match] = 'match'
	k[Kind.key_if] = 'if'
	k[Kind.key_elif] = 'elif'
	k[Kind.key_else] = 'else'
	k[Kind.key_and] = 'and'
	k[Kind.key_or] = 'or'
	k[Kind.key_not] = 'not'
	k[Kind.key_question] = 'question'
	k[Kind.key_yes] = 'yes'
	k[Kind.key_no] = 'no'
	k[Kind.key_as] = 'as'
	k[Kind.key_at] = 'at'
	k[Kind.key_true] = 'true'
	k[Kind.key_false] = 'false'
	k[Kind.key_continue] = 'continue'
	k[Kind.key_break] = 'break'
	return k
}

pub enum Precedence {
	lowest
	cond // 'or' o 'and'
	assign // =
	eq // == o !=
	sum // + -
	product // * /
	prefix // -X o !X
	postfix // ++ o --
	call // cmd(x)
}

pub fn build_precedences() []Precedence {
	mut p := []Precedence{len: int(Kind._end_)}
	p[Kind.dot] = .call
	// ++ | --
	p[Kind.inc] = .postfix
	p[Kind.dec] = .postfix
	// * /
	p[Kind.mul] = .product
	p[Kind.div] = .product
	// + -
	p[Kind.plus] = .sum
	p[Kind.minus] = .sum
	// == != < <= > >=
	p[Kind.eq] = .eq
	p[Kind.neq] = .eq
	p[Kind.lt] = .eq
	p[Kind.lte] = .eq
	p[Kind.gt] = .eq
	p[Kind.gte] = .eq
	// = | += | ...
	p[Kind.assign] = .assign
	p[Kind.plus_assign] = .assign
	p[Kind.minus_assign] = .assign
	p[Kind.div_assign] = .assign
	p[Kind.mul_assign] = .assign
	// OR or AND
	p[Kind.key_or] = .cond
	p[Kind.key_and] = .cond
	return p
}

const (
	precedences = build_precedences()
)

pub fn (tok Token) precedence() int {
	return int(precedences[tok.kind])
}

// is_scalar returns true if the token is a scalar
pub fn (tok Token) is_scalar() bool {
	return tok.kind in [.number, .string]
}

// is_unary returns true if the token can be in a unary expression
pub fn (tok Token) is_unary() bool {
	//`+` | `-` | `!` `*`
	return tok.kind in [
		.plus,
		.minus,
		.key_not,
		.mul,
	]
}

pub fn (kind Kind) is_relational() bool {
	//`<` | `<=` | `>` | `>=`
	return kind in [.lte, .lt, .gte, .gt, .eq, .neq]
}

pub fn (kind Kind) is_prefix() bool {
	return kind in [.minus, .mul, .key_not, .bang]
}

pub fn (kind Kind) is_infix() bool {
	return kind in
		[.plus, .minus, .mul, .div, .eq, .neq, .gt, .lt, .gte, .lte, .key_or, .key_and]
}

pub fn (kind Kind) is_assign() bool {
	return kind in [.assign, .plus_assign, .minus_assign, .div_assign, .mul_assign]
}
