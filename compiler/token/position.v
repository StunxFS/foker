// Copyright (c) 2020 Stunx (Jose Mendoza). All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module token

pub struct Position {
pub:
	len 	int // tamaño del literal en la fuente
	line_nr int // el número de linea en el codigo fuente donde se ubica el token
	pos 	int // la posicion de el token el texto scaneado
}

pub fn (pos Position) extend(end Position) Position {
	return {
		pos | len: end.pos - pos.pos + end.len
	}
}

[inline] pub fn (tok &Token) position() Position {
	return Position {
		len: tok.len
		line_nr: tok.line_nr - 1
		pos: tok.pos
	}
}
