// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

// import compiler.token
import compiler.ast

fn (mut p Parser) if_stmt() ast.IfStmt {
	pos := p.tok.position()
	mut branches := []ast.IfBranch{}
	for p.tok.kind in [.key_if, .key_elif, .key_else] {
		p.inside_if = true
		start_pos := p.tok.position()
		// 'if' o 'elif'
		if p.tok.kind in [.key_if, .key_elif] {
			p.check(p.tok.kind)
		}
		if p.tok.kind == .key_match {
			p.error('no se puede usar `match` con declaraciones `if`')
			return ast.IfStmt{}
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
				p.error('no se puede usar `match` con declaraciones `if`')
				return ast.IfStmt{}
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
					is_else: true
				}
				p.close_scope()
				break
			}
		}
		if p.prev_tok.kind == .key_else && p.tok.kind == .key_if {
			p.error("use 'elif' en vez de 'else if'")
		}
		if p.tok.kind !in [.key_else, .key_elif] {
			break
		}
	}
	return ast.IfStmt{
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
		}
		no: ast.QuestionAnswer{
			pos: no_pos
			stmts: no_stmts
		}
	}
}

// checkgender stmt
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

fn (mut p Parser) movement_expr(is_anon bool) ast.MovementExpr {
	is_pub := p.tok.kind == .key_pub
	if is_pub && !is_anon {
		p.next()
	}
	mov_pos := p.tok.position()
	p.check(.key_movement)
	pos := p.tok.position()
	mut name := ''
	if !is_anon {
		name = p.check_name()
		p.dont_use_name_imports(name, pos)
	}
	p.check(.lbrace)
	mut movs := []ast.MovItem{}
	for p.tok.kind != .rbrace {
		pos1 := p.tok.position()
		move := p.check_name()
		match p.pref.game {
			.firered_leafgreen {
				if move !in ast.movements_of_frlf {
					p.error_with_pos('este movimiento no es válido', pos1)
				}
			}
			.ruby_sapphire, .emerald {
				if move !in ast.movements_of_rse {
					p.error_with_pos('este movimiento no es válido', pos1)
				}
			}
		}
		mut count := 1
		if p.tok.kind == .mul {
			p.next()
			count = p.tok.lit.int()
			if count == 1 {
				p.error_with_pos('esto es innecesario, ya que este es el valor por defecto',
					p.prev_tok.position().extend(p.tok.position()))
			}
			p.check(.number)
		}
		movs << ast.MovItem{
			pos: pos1
			count: count
			name: move
			val: '0x' + (match p.pref.game {
				.firered_leafgreen { int(ast.movements_of_frlf[move]) }
				.ruby_sapphire, .emerald { int(ast.movements_of_rse[move]) }
			}).hex().str()
		}
	}
	if movs.len == 0 {
		p.error_with_pos("este 'movement' no tiene movimientos", mov_pos)
	}
	p.check(.rbrace)
	mov := ast.MovementExpr{
		name: name
		pos: mov_pos.extend(pos)
		is_anon: is_anon
		movs: movs
	}
	obj := ast.Const{
		name: p.prepend_mod(name)
		mod: p.mod_name
		expr: mov
		pos: pos
		typ: .movement
		is_pub: is_pub && !is_anon
	}
	if !is_anon {
		p.global_scope.register(obj)
	} else {
		p.scope.register(obj)
	}
	return mov
}
