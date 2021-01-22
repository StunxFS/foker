// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

import strings
import compiler.ast
import compiler.about
import compiler.prefs

pub struct Gen {
	prefs &prefs.Preferences
mut:
	table       &ast.Table
	file        &ast.File
	header      strings.Builder
	includes    strings.Builder
	defines     strings.Builder
	snippets    strings.Builder
	strings     strings.Builder
	strings_tmp strings.Builder
	moves       strings.Builder
	moves_tmp   strings.Builder
	flags       FVF
	vars        FVF
}

pub fn new_gen(prefs &prefs.Preferences, table &ast.Table) Gen {
	return Gen{
		prefs: prefs
		table: table
		flags: new_fvf(prefs.flags_file)
		vars: new_fvf(prefs.vars_file)
		file: 0
	}
}

pub fn (mut g Gen) gen_from_files(files []ast.File) {
	g.header.writeln('; Generado automáticamente con ZubatScript v$about.version $about.status')
	g.header.writeln('; Creado por: StunxFS | ADVERTENCIA: No modificar sin saber del tema')
	for mut file in files {
		g.file = file
		g.gen()
	}
	println(g.create_content())
}

pub fn (mut g Gen) gen() {
	for stmt in g.file.prog.stmts {
		g.top_stmt(stmt)
	}
}

pub fn (mut g Gen) create_content() string {
	mut c := g.header.str()
	if g.includes.len > 0 {
		c += g.header.str() + '\n'
	}
	if g.defines.len > 0 {
		c += g.defines.str() + '\n'
	}
	if g.snippets.len > 0 {
		c += g.snippets.str() + '\n'
	}
	if g.strings.len > 0 {
		c += g.strings.str() + '\n'
	}
	if g.strings_tmp.len > 0 {
		c += g.strings_tmp.str() + '\n'
	}
	if g.moves.len > 0 {
		c += g.moves.str() + '\n'
	}
	if g.moves_tmp.len > 0 {
		c += g.moves_tmp.str() + '\n'
	}
	return c.trim_space()
}

pub fn (mut g Gen) top_stmt(node ast.Stmt) {
	match mut node {
		ast.Const {
			if node.typ == .int {
				val := g.define_expr(node.expr)
				g.table.constantes[node.name] = val
				str := val.str()
				g.defines.writeln('#define $node.name $str')
			}
		}
		ast.ScriptDecl {
			g.snippets.writeln('#org @$node.name\n')
		}
		else {}
	}
}

// define_expr - generar valores constantes en base a expresiones simples
pub fn (mut g Gen) define_expr(node ast.Expr) int {
	mut res := 0
	match node {
		ast.Ident {
			res = g.table.constantes[node.name]
		}
		ast.IntegerLiteral {
			res = node.lit.int()
		}
		ast.ParExpr {
			res = g.define_expr(node.expr)
		}
		ast.InfixExpr {
			val1, val2 := g.define_expr(node.left), g.define_expr(node.right)
			match node.op {
				.plus { res = val1 + val2 }
				.minus { res = val1 - val2 }
				.mul { res = val1 * val2 }
				.div { res = val1 / val2 }
				else {}
			}
		}
		else {}
	}
	return res
}
