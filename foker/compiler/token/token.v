// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module token

// Token represents a single token in the Wolk lexer.
pub struct Token {
pub mut:
	kind	Kind
	lit		string
	len		int
	line_nr	int
	pos		int
}

pub fn (t Token) str() string {
	return 'token.Token{kind: ${t.kind}, lit: "${t.lit}", pos: ${t.position()}}'
}

pub struct Position {
pub:
	len		int
	line_nr int
	pos		int
}

pub fn (pos Position) str() string {
	return 'token.Position{ line_nr: ${pos.line_nr}, pos: ${pos.pos}, len: ${pos.len} }'
}

pub fn (pos Position) extend(end Position) Position {
	return { pos | len: end.pos - pos.pos + end.len }
}

[inline] pub fn (tok &Token) position() Position {
	return Position{len: tok.len line_nr: tok.line_nr - 1, pos: tok.pos}
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

	lparen
	rparen
	lbrace
	rbrace
	lbracket
	rbracket

	// keywords
	keyword_begin
	key_import
	key_include
	key_script
	key_cmd
	key_var
	key_const
	key_dynamic
	key_movement
	
	key_pub
	key_extern
	
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
	keyword_end
	_end_
}

pub fn (k Kind) is_keyword() bool {
	return (int(k) > int(Kind.keyword_begin))
}

pub fn (k Kind) str() string {
	return tokens_str[int(k)]
}

pub const (
	keywords = {
		"import": Kind.key_import,
		"include": Kind.key_include,
		"script": Kind.key_script,
		"cmd": Kind.key_cmd,
		"var": Kind.key_var,
		"const": Kind.key_const,
		"dynamic": Kind.key_dynamic,
		"movement": Kind.key_movement,
		
		"pub": Kind.key_pub,
		"extern": Kind.key_extern,
		
		"match": Kind.key_match,
		"if": Kind.key_if,
		"elif": Kind.key_elif,
		"else": Kind.key_else,
		"and": Kind.key_and,
		"or": Kind.key_or,
		"not": Kind.key_not,
		"question": Kind.key_question,
		"yes": Kind.key_yes,
		"no": Kind.key_no,
		"as": Kind.key_as,
		"at": Kind.key_at,

		"true": Kind.key_true,
		"false": Kind.key_false
	}
)

const (
	nr_tokens = int(Kind._end_)
	tokens_str = build_tokenstr()
)

fn build_tokenstr() []string {
	mut k := []string{len: nr_tokens}
	k[Kind.unknown] = "unknown"
	k[Kind.eof] = "eof"
	k[Kind.name] = "name"
	k[Kind.number] = "number"
	k[Kind.string] = "string"
	k[Kind.char] = "char"
	
	k[Kind.plus] = "+"
	k[Kind.minus] = "-"
	k[Kind.mul] = "*"
	k[Kind.div] = "/"
	k[Kind.inc] = "++"
	k[Kind.dec] = "--"
	
	k[Kind.eq] = "=="
	k[Kind.neq] = "!="
	k[Kind.lt] = "<"
	k[Kind.gt] = ">"
	k[Kind.lte] = "<="
	k[Kind.gte] = ">="
	
	k[Kind.assign] = "="
	k[Kind.plus_assign] = "+=" // +=
	k[Kind.minus_assign] = "-="
	k[Kind.div_assign] = "/="
	k[Kind.mul_assign] = "*="
	
	k[Kind.comma] = ","
	k[Kind.colon] = ":"
	k[Kind.semicolon] = ";"
	k[Kind.bang] = "!"
	k[Kind.dot] = "."
	k[Kind.dotdot] = ".."

	k[Kind.lparen] = "("
	k[Kind.rparen] = ")"
	k[Kind.lbrace] = "{"
	k[Kind.rbrace] = "}"
	k[Kind.lbracket] = "["
	k[Kind.rbracket] = "]"

	k[Kind.key_import] = "import"
	k[Kind.key_include] = "include"
	k[Kind.key_script] = "script"
	k[Kind.key_cmd] = "cmd"
	k[Kind.key_var] = "var"
	k[Kind.key_const] = "const"
	k[Kind.key_dynamic] = "dynamic"
	k[Kind.key_movement] = "movement"
	
	k[Kind.key_pub] = "pub"
	k[Kind.key_extern] = "extern"
	
	k[Kind.key_match] = "match"
	k[Kind.key_if] = "if"
	k[Kind.key_elif] = "elif"
	k[Kind.key_else] = "else"
	k[Kind.key_and] = "and"
	k[Kind.key_or] = "or"
	k[Kind.key_not] = "not"
	k[Kind.key_question] = "question"
	k[Kind.key_yes] = "yes"
	k[Kind.key_no] = "no"
	k[Kind.key_as] = "as"
	k[Kind.key_at] = "at"

	k[Kind.key_true] = "true"
	k[Kind.key_false] = "false"
	return k
}

pub enum Precedence {
	lowest
	cond // 'or' or 'and'
	assign // =
	eq // == or !=
	sum // + -
	product // * /
	prefix // -X or !X
	postfix // ++ or --
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
	return tok.kind in
		[ /* `+` | `-` | `!` | `~` | `*` | `&` */
		.plus, .minus, .key_not, .mul]
}

pub fn (tok Kind) is_relational() bool {
	return tok in [
		/* `<` | `<=` | `>` | `>=` */
		.lte, .lt, .gte, .gt, .eq, .neq]
}

pub fn (kind Kind) is_prefix() bool {
	return kind in [.minus, .mul, .key_not]
}

pub fn (kind Kind) is_infix() bool {
	return kind in
		[.plus, .minus, .mul, .div, .eq, .neq, .gt, .lt,
		/*  */.gt, .lt, .key_or,
		/*  */.key_and]
}
