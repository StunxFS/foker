// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module parser

import compiler.ast

// return true if file being parsed imports `mod`
pub fn (p &Parser) known_import(mod string) bool {
	return mod in p.imports
}

fn (p &Parser) prepend_mod(name string) string {
	if p.expr_mod != '' {
		return p.expr_mod + '.' + name
	}
	return '${p.mod}.$name'
}

fn (mut p Parser) register_used_import(alias string) {
	if !p.is_used_import(alias) {
		p.used_imports << alias
	}
}

fn (p &Parser) is_used_import(alias string) bool {
	return alias in p.used_imports
}

fn (mut p Parser) register_auto_import(alias string) {
	if alias !in p.imports {
		p.imports[alias] = alias
		p.table.imports << alias
		node := ast.Import{
			pos: p.tok.position()
			mod: alias
			alias: alias
		}
		p.ast_imports << node
	}
	p.register_used_import(alias)
}

fn (mut p Parser) check_unused_imports() {
	for import_m in p.ast_imports {
		alias := import_m.alias
		mod := import_m.mod
		if !p.is_used_import(alias) {
			mod_alias := if alias == mod { alias } else { '$alias ($mod)' }
			p.warn_with_pos("el modulo '$mod_alias' es importado, pero nunca es usado", import_m.pos)
		}
	}
}
