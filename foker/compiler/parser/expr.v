// Copyright (c) 2020 Pizcofy. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module parser

import compiler.ast
import compiler.token

pub fn (mut p Parser) expr(precedence int) ast.Expr {
	mut node := ast.Expr{}
	// prefix
	match p.tok.kind {
		/*.name {
			node = p.name_expr()
		}*/
		.string {
			node = p.string_expr()
		}
		.dot {
			// .enum_val
			node = p.enum_val()
		}
		//.at {}
		.minus, .mul, .key_not {
			node = p.prefix_expr()
		}
		.key_true, .key_false {
			node = ast.BoolLiteral{
				lit: (p.tok.kind == .key_true).str()
				pos: p.tok.position()
			}
			p.next()
		}
		.number {
			node = p.parse_number_literal()
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
		else {
			if p.tok.kind != .eof {
				p.error_with_pos("expresión invalida, no se esperaba el token ${p.tok.kind.str()}", p.tok.position())
			}
		}
	}
	return p.expr_with_left(node, precedence)
}

pub fn (mut p Parser) expr_with_left(left ast.Expr, precedence int) ast.Expr {
	mut node := left
	// infix
	for precedence < p.tok.precedence() {
		if p.tok.kind == .dot {
			node = p.dot_expr(node)
		} else if p.tok.kind.is_infix() {
			node = p.infix_expr(node)
		} else if p.tok.kind in [.inc, .dec] {
			node = ast.PostfixExpr{
				op: p.tok.kind
				expr: node
				pos: p.tok.position()
			}
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
	mut right := ast.Expr{}
	right = p.expr(precedence)
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
	mut right := if op == .minus { p.expr(token.Precedence.call) } else { p.expr(token.Precedence.prefix) }
	return ast.PrefixExpr{
		op: op
		right: right
		pos: pos
	}
}
