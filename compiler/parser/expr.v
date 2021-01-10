// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import compiler.token
import compiler.ast

// Exprs ====================================================================================
fn (mut p Parser) expr(precedence int) ast.Expr {
	mut node := ast.Expr{}
	match p.tok.kind {
		.name {
			node = p.name_expr()
		}
		.string {
			node = p.string_expr()
		}
		.number {
			node = p.parse_number_literal()
		}
		.key_true, .key_false {
			node = ast.BoolLiteral{
				lit: (p.tok.kind == .key_true).str()
				pos: p.tok.position()
			}
			p.next()
		}
		.lparen {
			p.check(.lparen)
			node = p.expr(0)
			p.check(.rparen)
			node = ast.ParExpr{
				expr: node
				pos: p.tok.position()
			}
		}
		.minus, .bang {
			node = p.prefix_expr()
		}
		else {
			if p.tok.kind != .eof {
				p.error_with_pos('expresión invalida, no se esperaba el token `$p.tok.kind.str()`',
					p.tok.position())
			}
		}
	}
	return p.expr_with_left(node, precedence)
}

pub fn (mut p Parser) expr_with_left(left ast.Expr, precedence int) ast.Expr {
	mut node := left
	for precedence < p.tok.precedence() {
		if p.tok.kind.is_infix() {
			if p.tok.kind.is_prefix() && p.tok.line_nr != p.prev_tok.line_nr {
				// added 10/2020: LATER this will be parsed as PrefixExpr instead
				p.warn_with_pos('mueva el operador infijo `$p.tok.kind` antes de la nueva línea (si se pretende infijo) o use corchetes para una expresión de prefijo',
					p.tok.position())
			}
			// continue on infix expr
			node = p.infix_expr(node)
		} else if p.tok.kind in [.inc, .dec] {
			node = ast.PostfixExpr{
				op: p.tok.kind
				expr: node
				pos: p.tok.position()
			}
			p.next()
		} else {
			return node
		}
	}
	return node
}

fn (mut p Parser) infix_expr(left ast.Expr) ast.Expr {
	op := p.tok.kind
	precedence := p.tok.precedence()
	pos := p.tok.position()
	p.next()
	right := p.expr(precedence)
	return ast.InfixExpr{
		left: left
		right: right
		op: op
		pos: pos
	}
}

fn (mut p Parser) prefix_expr() ast.PrefixExpr {
	pos := p.tok.position()
	op := p.tok.kind
	p.next()
	right := p.expr(int(token.Precedence.prefix))
	return ast.PrefixExpr{
		op: op
		pos: pos
		right: right
	}
}

fn (mut p Parser) name_expr() ast.Expr {
	// prev_tok_kind := p.prev_tok.kind
	mut node := ast.Expr{}
	if p.tok.lit == 'fmt' { // auto-format string
		p.next()
		p.check(.lparen)
		pos := p.tok.position()
		expr := p.expr(0)
		mut width := 0
		if p.tok.kind == .comma { // fmt("msg", 10);
			p.next()
			width = p.tok.lit.int()
			p.check(.number)
		}
		p.check(.rparen)
		return ast.FmtStringLiteral{
			expr: expr
			pos: pos
			width: width
		}
	} else {
		node = p.parse_ident()
	}
	return node
}

pub fn (mut p Parser) parse_ident() ast.Ident {
	if p.tok.kind == .name {
		pos := p.tok.position()
		mut name := p.check_name()
		if name == '_' {
			return ast.Ident{
				tok_kind: p.tok.kind
				name: '_'
				kind: .blank_ident
				pos: pos
				// scope: p.scope
			}
		}
		if p.expr_mod.len > 0 {
			name = '${p.expr_mod}.$name'
		}
		return ast.Ident{
			tok_kind: p.tok.kind
			kind: .unresolved
			name: name
			pos: pos
			// scope: p.scope
		}
	}
	p.error('token `$p.tok.lit` inesperado')
	return ast.Ident{
		// scope: p.scope
	}
}

fn (mut p Parser) string_expr() ast.StringLiteral {
	mut val := p.tok.lit
	mut pos := p.tok.position()
	p.next()
	if p.tok.kind == .string {
		val += p.tok.lit
		pos = pos.extend(p.tok.position())
		p.next()
	}
	return ast.StringLiteral{
		lit: val
		pos: pos
	}
}

fn (mut p Parser) parse_number_literal() ast.Expr {
	lit := p.tok.lit
	pos := p.tok.position()
	p.next()
	return ast.IntegerLiteral{
		lit: lit
		pos: pos
	}
}
