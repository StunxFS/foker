// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module token

pub struct Token {
pub:
	kind	Kind // el tipo del token; para comparaciones rápidas
	lit		string // representación literal del token
	line_nr	int // el número de linea en el código donde está el token
	pos		int // la posición del token en el text scaneado
	len		int // el largo del literal
}

pub enum Kind {
	unknown // (reservado) desconocido
	eof
	name // draky_gusta_tubos
	number // 123
	string // "makako"
	chartoken // 'A'
	plus // +
	minus // -
	mul // *
	div // '/'
	mod // %
	inc // ++
	dec // --
	not // '!'
	question // ?
	comma // ,
	semicolon // ;
	colon // :
	doblecolon // ::
	arrow // ->
	amp // &
	hash // #
	dollar // $
	at // @
	
	assign // =
	decl_assign // :=
	plus_assign // +=
	minus_assign // -=
	div_assign // /=
	mult_assign // *=
	mod_assign // %=

	// {} () []
	lcbr
	rcbr
	lpar
	rpar
	lsbr
	rsbr

	// == != <= < >= >
	eq
	ne
	gt
	lt
	ge
	le

	dot // .
	dotdot // ..
	ellipsis // ...

	comment

	// keywords (palabras reservadas)
	keyword_beg
	key_and
	key_asm
	key_break
	key_const
	key_continue
	key_defer
	key_else
	key_enum
	key_extern
	key_false
	key_for
	key_fn
	key_goto
	key_if
	key_import
	key_match
	key_return
	key_true
	key_or
	key_pub
	key_var
	// key_static TODO: WTF?
	keyword_end
	_end_
}

const (
	assign_tokens = [Kind.assign, .plus_assign, .minus_assign, .mult_assign,
					.div_assign, .mod_assign]
	nr_tokens = int(Kind._end_)
)

// build_keys genera un mapa con los valores de cadena de cada keyword
// Keywords['return'] == .key_return
fn build_keys() map[string]Kind {
	mut res := map[string]Kind
	for t in int(Kind.keyword_beg) + 1 .. int(Kind.keyword_end) {
		key := token_str[t]
		res[key] = t
	}
	return res
}

fn build_token_str() []string {
	mut s := []string{len: (nr_tokens)}
	s[Kind.unknown] = 'unknown'
	s[Kind.eof] = 'eof'
	s[Kind.name] = 'name'
	s[Kind.number] = 'number'
	s[Kind.string] = 'string'
	s[Kind.chartoken] = 'char'
	s[Kind.plus] = '+'
	s[Kind.minus] = '-'
	s[Kind.mul] = '*'
	s[Kind.div] = '/'
	s[Kind.mod] = '%'
	s[Kind.amp] = '&'
	s[Kind.inc] = '++'
	s[Kind.dec] = '--'
	s[Kind.dot] = '.'
	s[Kind.dotdot] = '..'
	s[Kind.ellipsis] = '...'
	s[Kind.comma] = ','
	s[Kind.semicolon] = ';'
	s[Kind.colon] = ':'
	s[Kind.doblecolon] = '::'
	s[Kind.arrow] = '->'
	s[Kind.assign] = '='
	s[Kind.decl_assign] = ':='
	s[Kind.plus_assign] = '+='
	s[Kind.minus_assign] = '-='
	s[Kind.div_assign] = '/='
	s[Kind.mod_assign] = '%='
	s[Kind.lcbr] = '{'
	s[Kind.rcbr] = '}'
	s[Kind.lpar] = '('
	s[Kind.rpar] = ')'
	s[Kind.lsbr] = '['
	s[Kind.rsbr] = ']'
	s[Kind.eq] = '=='
	s[Kind.ne] = '!='
	s[Kind.gt] = '>'
	s[Kind.lt] = '<'
	s[Kind.ge] = '>='
	s[Kind.le] = '<='
	s[Kind.question] = '?'
	s[Kind.dollar] = '$'
	s[Kind.at] = '@'
	s[Kind.key_and] = 'and'
	s[Kind.key_asm] = 'asm'
	s[Kind.key_break] = 'break'
	s[Kind.key_const] = 'const'
	s[Kind.key_continue] = 'continue'
	s[Kind.key_defer] = 'defer'
	s[Kind.key_else] = 'else'
	s[Kind.key_enum] = 'enum'
	s[Kind.key_extern] = 'extern'
	s[Kind.key_false] = 'false'
	s[Kind.key_fn] = 'fn'
	s[Kind.key_for] = 'for'
	s[Kind.key_goto] = 'goto'
	s[Kind.key_if] = 'if'
	s[Kind.key_import] = 'import'
	s[Kind.key_match] = 'match'
	s[Kind.key_or] = 'or'
	s[Kind.key_pub] = 'pub'
	s[Kind.key_var] = 'var'
	s[Kind.key_return] = 'return'
	//s[Kind.key_static] = 'static' TODO
	s[Kind.key_true] = 'true'
	return s
}

const (
	token_str = build_token_str()
	keywords = build_keys()
)

pub fn key_to_token(key string) Kind {
	a := Kind(keywords[key])
	return a
}

pub fn is_key(key string) bool {
	return int(key_to_token(key)) > 0
}

pub fn is_decl(t Kind) bool {
	return t in [.key_enum, .key_fn, .key_pub, .key_const, .key_var, .eof]
}

pub fn (t Kind) is_assign() bool {
	return t in assign_tokens
}

fn (t []Kind) contains(val Kind) bool {
	for tt in t {
		if tt == val {
			return true
		}
	}
	return false
}

pub fn (t Kind) str() string {
	return token_str[int(t)]
}

pub fn (t Token) str() string {
	return '${t.kind.str()} "${t.lit}"'
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
	call // func(x) or foo::method(X)
}

pub fn build_precedences() []Precedence {
	mut p := []Precedence{len: int(Kind._end_), cap: int(Kind._end_)}

	p[Kind.doblecolon] = .call

	// ++ | -- | ?
	p[Kind.inc] = .postfix
	p[Kind.dec] = .postfix
	p[Kind.question] = .postfix

	// * | / | %
	p[Kind.mul] = .product
	p[Kind.div] = .product
	p[Kind.mod] = .product
	
	// + | -
	p[Kind.plus] = .sum
	p[Kind.minus] = .sum
	
	// == | != | < | <= | > | >=
	p[Kind.eq] = .eq
	p[Kind.ne] = .eq
	p[Kind.lt] = .eq
	p[Kind.le] = .eq
	p[Kind.gt] = .eq
	p[Kind.gt] = .eq
	p[Kind.ge] = .eq

	// = | += | ...
	p[Kind.assign] = .assign
	p[Kind.plus_assign] = .assign
	p[Kind.minus_assign] = .assign
	p[Kind.div_assign] = .assign
	p[Kind.mod_assign] = .assign
	p[Kind.mult_assign] = .assign

	p[Kind.key_or] = .cond
	p[Kind.key_and] = .cond

	return p
}

const (
	precedences = build_precedences()
)

pub fn (tok Token) precedences() int {
	return int(precedences[tok.kind])
}

pub fn (tok Token) is_scalar() bool {
	return tok.kind in [.number, .string]
}

pub fn (tok Token) is_unary() bool {
	return tok.kind in [.plus, .minus, .not, .mul]
}

pub fn (tok Kind) is_relational() bool {
	return tok in [.lt, .le, .gt, .ge, .eq, .ne]
}

/*pub fn (k Kind) is_start_of_type() bool { TODO
	return k in [.name, .l]
}*/

pub fn (kind Kind) is_prefix() bool {
	return kind in [.plus, .minus, .mod, .mul, .div, .eq, .ne, .gt, .lt, .ge, .le, .key_or, .key_and,
					.doblecolon]
}
