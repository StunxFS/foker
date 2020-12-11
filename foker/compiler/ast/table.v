// Copyright (c) 2020 Pizcofy. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ast

pub struct Table {
pub mut:
	imports		[]string // list of all imports
	modules		[]string // topologically sorted list of all modules registered by the application
	enums		[]EnumDecl // enumerators created in script
	scripts		[]ScriptDecl
	cmds		[]CmdDecl
}

pub fn (t &Table) exists_enum(name string) bool {
	for e in t.enums {
		if e.name == name { return true }
	} return false
}

pub fn (t &Table) exists_script(name string) bool {
	for e in t.scripts {
		if e.name == name { return true }
	} return false
}

pub fn (t &Table) exists_cmd(name string) bool {
	for e in t.cmds {
		if e.name == name { return true }
	} return false
}

// solo tenemos disponibles los siguientes tipos
pub enum Type {
	string
	byte // 89
	int // word -> 89 A1
	long // dword -> 89 A1 89 A1
	any // any number between a byte to a long
}
