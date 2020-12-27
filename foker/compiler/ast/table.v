// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

import os

pub struct Table {
pub mut:
	imports []string // list of all imports
	modules []string // topologically sorted list of all modules registered by the application
	scripts []ScriptDecl
	cmds    []CmdDecl
}

pub fn new_table() &Table {
	return &Table{}
}

// TODO: Once we have a module format we can read from module file instead
// this is not optimal. it depends on the full import being in table.imports
// already, we can instead lookup the module path and then work it out
pub fn (table &Table) qualify_module(mod string, file_path string) string {
	for m in table.imports {
		if m.contains('.') && m.contains(mod) {
			m_parts := m.split('.')
			m_path := m_parts.join(os.path_separator)
			if mod == m_parts[m_parts.len - 1] && file_path.contains(m_path) {
				return m
			}
		}
	}
	return mod
}

pub fn (t &Table) exists_script(name string) bool {
	for e in t.scripts {
		if e.name == name {
			return true
		}
	}
	return false
}

pub fn (t &Table) exists_cmd(name string) bool {
	for e in t.cmds {
		if e.name == name {
			return true
		}
	}
	return false
}

pub const (
	type_names = ['string', 'movement', 'byte', 'int', 'long', 'any']
)

// solo tenemos disponibles los siguientes tipos
pub enum Type {
	_auto // tenemos que definir el tipo con el checker
	_unknown // desconocido
	string
	movement
	byte // 89
	int // word -> 89 A1
	long // dword -> 89 A1 89 A1
	any // any number between a byte to a long
}

pub fn get_type_from_string(name string) Type {
	return match name {
		'string' { Type.string }
		'movement' { Type.movement }
		'byte' { Type.byte }
		'int' { Type.int }
		'long' { Type.long }
		'any' { Type.any }
		else { Type._unknown }
	}
}
