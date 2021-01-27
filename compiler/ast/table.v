// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

import compiler.token

pub struct Table {
pub mut:
	imports       []string // lista de los módulos importados
	modules       []string // lista de todos los módulos
	scripts       map[string]ScriptDecl
	cmds          map[string]CmdDecl
	alias         map[string]Alias
	builtins_cmds []string
	constantes    map[string]int
}

pub fn new_table() &Table {
	return &Table{}
}

[inline]
pub fn (t &Table) exists_script(name string) bool {
	return name in t.scripts
}

// retorna -> (existe, es alias)
[inline]
pub fn (t &Table) exists_cmd(name string) (bool, bool) {
	is_alias := t.exists_alias(name)
	if is_alias {
		return t.alias[name].target in t.cmds, is_alias
	}
	return name in t.cmds, is_alias
}

[inline]
pub fn (t &Table) exists_alias(name string) bool {
	return name in t.alias
}

pub struct Alias {
pub:
	target_pos token.Position
	pos        token.Position
pub mut:
	target string
	name   string
	mod    string
}
