// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import compiler.ast

// import compiler.token
fn (mut p Parser) if_expr(is_comptime bool) ast.IfExpr {
	pos := p.tok.position()
	mut branches := []ast.IfBranch{}
	for p.tok.kind in [.key_if, .key_elif, .key_else] {
		p.inside_if = true
		start_pos := if is_comptime {
			p.prev_tok.position().extend(p.tok.position())
		} else {
			p.tok.position()
		}
		// 'if' o 'elif'
		if p.tok.kind in [.key_if, .key_elif] {
			p.check(p.tok.kind)
		}
		if p.tok.kind == .key_match {
			p.error('cannot use `match` with `if` statements')
			return ast.IfExpr{}
		}
		cond := p.expr(0)
		end_pos := p.prev_tok.position()
		body_pos := p.tok.position()
		p.inside_if = false
		p.open_scope()
		stmts := p.parse_block_no_scope(false)
		branches << ast.IfBranch{
			cond: cond
			stmts: stmts
			pos: start_pos.extend(end_pos)
			body_pos: body_pos.extend(p.prev_tok.position())
			scope: p.scope
		}
		p.close_scope()
		if p.tok.kind == .key_else {
			p.check(.key_else)
			if p.tok.kind == .key_match {
				p.error('cannot use `match` with `if` statements')
				return ast.IfExpr{}
			}
			if p.tok.kind == .lbrace {
				p.inside_if = false
				end_pos2 := p.prev_tok.position()
				body_pos2 := p.tok.position()
				p.open_scope()
				branches << ast.IfBranch{
					stmts: p.parse_block_no_scope(false)
					pos: start_pos.extend(end_pos2)
					body_pos: body_pos2.extend(p.tok.position())
					scope: p.scope
				}
				p.close_scope()
				break
			}
		}
		if p.tok.kind == .key_if {
			p.error("use 'elif' en vez de 'else if'")
		}
		if p.tok.kind !in [.key_else, .key_elif] {
			break
		}
	}
	return ast.IfExpr{
		is_comptime: is_comptime // TODO: remover esta wea de aqui
		branches: branches
		pos: pos
	}
}

// question stmt
fn (mut p Parser) question_stmt() ast.Stmt {
	p.check(.key_question)
	pos := p.tok.position()
	question := p.string_expr()
	p.check(.lbrace)
	yes_pos := p.tok.position()
	p.check(.key_yes)
	yes_stmts := p.parse_block()
	no_pos := p.tok.position()
	p.check(.key_no)
	no_stmts := p.parse_block()
	p.check(.rbrace)
	return ast.QuestionStmt{
		pos: pos
		question: question
		yes: ast.QuestionAnswer{
			pos: yes_pos
			stmts: yes_stmts
			is_yes: true
		}
		no: ast.QuestionAnswer{
			pos: no_pos
			stmts: no_stmts
			is_yes: false
		}
	}
}

fn (mut p Parser) checkgender_stmt() ast.CheckgenderStmt {
	pos := p.tok.position()
	p.check(.key_checkgender)
	p.check(.lbrace) // {
	boy_pos := p.tok.position()
	p.check(.key_boy)
	boy_stmts := p.parse_block()
	girl_pos := p.tok.position()
	p.check(.key_girl)
	girl_stmts := p.parse_block()
	p.check(.rbrace) // }
	return ast.CheckgenderStmt{
		pos: pos
		boy_pos: boy_pos
		girl_pos: girl_pos
		boy_stmts: boy_stmts
		girl_stmts: girl_stmts
	}
}
