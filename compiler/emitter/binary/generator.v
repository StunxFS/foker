// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

import os
import compiler.ast
import compiler.prefs

// import compiler.token
const (
	operators = {
		'==': '1'
		'!=': '5'
		'<':  '0'
		'>':  '2'
		'<=': '3'
		'>=': '4'
	}
)

pub struct Binary {
mut:
	file  ast.File
	fs    FScript
	table &ast.Table
	pref  &prefs.Preferences
}

pub fn bingen_to_file(file ast.File, table &ast.Table, pref &prefs.Preferences) ? {
	os.write_file(pref.output, bingen(file, table, pref)) ?
}

pub fn bingen(file ast.File, table &ast.Table, pref &prefs.Preferences) string {
	mut bin := Binary{file, new_fscript_with_vffile(file.prog.name, pref.flags_vars_file), table, pref}
	bin.run()
	return bin.fs.generate_script() + '\n'
}

fn (mut bin Binary) run() {
	for stmt in bin.file.prog.stmts {
		match stmt {
			ast.DynamicStmt {
				bin.fs.change_dynamic(if !stmt.dyn_offset.starts_with('0x') {
					to_hex(stmt.dyn_offset.int())
				} else {
					stmt.dyn_offset
				})
			}
			ast.Include {
				bin.fs.add_include(stmt.file)
			}
			ast.Const {
				not_is_str, lit := bin.expr_lit_str(stmt.name, stmt.expr)
				if not_is_str {
					bin.fs.add_const(stmt.name, lit)
				} else {
					bin.fs.add_string(stmt.name, lit)
				}
			}
			ast.ScriptDecl {
				bin.script_stmt(stmt)
			}
			else {}
		}
	}
}

fn (mut bin Binary) expr_lit_str(name string, expr ast.Expr) (bool, string) {
	match expr {
		ast.IntegerLiteral {
			if !expr.is_hex {
				return true, to_hex(expr.lit.int())
			} else {
				return true, expr.lit
			}
		}
		ast.BoolLiteral {
			return true, if expr.lit.bool() {
				'0'
			} else {
				'1'
			}
		}
		ast.StringLiteral {
			return false, expr.lit
		}
		/*
		ast.FmtStringLiteral { TODO
			bin.fs.add_string(name, expr.lit)
		}
		*/
		else {}
	}
	return true, ''
}

fn (mut bin Binary) script_stmt(script ast.ScriptDecl) {
	if !script.is_extern {
		mut block := new_fblock(script.name)
		bin.stmts(mut block, script.stmts)
		block.add_end()
		bin.fs.add_block(block)
	}
}

fn (mut bin Binary) stmts(mut block FBlock, stmts []ast.Stmt) {
	for stmt in stmts {
		match stmt {
			ast.QuestionStmt {
				block.add_cmd('msgbox', ['@' + bin.fs.add_tmp_string(stmt.question.lit), '5'])
				block.add_cmd('compare', ['LASTRESULT', '1'])
				yes_label := bin.fs.new_question_label()
				no_label := bin.fs.new_question_label()
				yes_end_label := bin.fs.new_question_label()
				block.add_cmd('if 1 goto', [':' + yes_label])
				block.add_cmd('goto', [':' + no_label])
				block.add_label(yes_label)
				bin.stmts(mut block, stmt.yes.stmts)
				block.add_goto(yes_end_label + ' ; pasaje de salida para $yes_label')
				block.add_label(no_label)
				bin.stmts(mut block, stmt.no.stmts)
				block.add_label(yes_end_label)
			}
			ast.CheckgenderStmt {
				block.add_cmd('checkgender', [])
				block.add_cmd('compare', ['LASTRESULT', '1'])
				boy_label := bin.fs.new_label()
				girl_label := bin.fs.new_label()
				end_boy_label := bin.fs.new_label()
				block.add_cmd('if 1 goto', [':' + boy_label + ' ; boy'])
				block.add_goto(girl_label + ' ; girl')
				block.add_label(boy_label)
				bin.stmts(mut block, stmt.boy_stmts)
				block.add_goto(end_boy_label)
				block.add_label(girl_label)
				bin.stmts(mut block, stmt.girl_stmts)
				block.add_label(end_boy_label)
			}
			else {}
		}
	}
}
