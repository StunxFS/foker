// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

pub const (
	type_names = ['string', 'movement', 'bool', 'byte', 'int', 'long', 'offset']
)

// solo tenemos disponibles los siguientes tipos
pub enum Type {
	unknown // desconocido
	string
	movement
	bool // flag / bool
	byte // 89
	int // word -> 89 A1
	long // dword -> 89 A1 89 A1
	// any // any number between a byte to a long
	offset
}

pub fn (t &Type) is_numeric() bool {
	return t in [.int, .long]
}

pub fn type_to_str(t Type) string {
	return match t {
		.unknown { '<rare-type>' }
		else { t.str() }
	}
}

pub fn get_type_from_string(name string) Type {
	return match name {
		'string' { Type.string }
		'movement' { Type.movement }
		'byte' { Type.byte }
		'int' { Type.int }
		'long' { Type.long }
		//'any' { Type.any }
		'offset' { Type.offset }
		'bool' { Type.bool }
		else { Type.unknown }
	}
}
