// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module parser

// import compiler.ast
// return true if file being parsed imports `mod`
pub fn (p &Parser) known_import(mod string) bool {
	return mod in p.imports
}

fn (p &Parser) prepend_mod(name string) string {
	// println('prepend_mod() name=$name p.mod=$p.mod_name expr_mod=$p.expr_mod')
	if p.expr_mod != '' {
		return p.expr_mod + '::' + name
	}
	if p.is_builtin {
		return name
	}
	return '$p.mod_name::$name'
}

fn (p &Parser) is_used_import(alias string) bool {
	return alias in p.used_imports
}

fn (mut p Parser) register_used_import(alias string) {
	if !p.is_used_import(alias) {
		p.used_imports << alias
	}
}

fn (mut p Parser) check_unused_imports() {
	for import_m in p.ast_imports {
		alias := import_m.alias
		mod := import_m.mod
		if !p.is_used_import(alias) {
			mod_alias := if alias == mod { alias } else { '$alias ($mod)' }
			p.warn_with_pos("el módulo '$mod_alias' está importado pero nunca es usado",
				import_m.pos)
		}
	}
}
