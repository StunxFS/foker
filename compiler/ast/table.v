// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

pub struct Table {
pub mut:
	scripts map[string]ScriptDecl
	cmds    map[string]CmdDecl
	alias   map[string]string
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
	// soporte para alias
	if name in t.alias {
		return true, true
	}
	return name in t.cmds, false
}

[inline]
pub fn (t &Table) exists_alias(name string) bool {
	return name in t.alias
}
