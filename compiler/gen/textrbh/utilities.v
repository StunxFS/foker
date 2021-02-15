// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module textrbh

// TODO: Organizar este archivo en un lugar adecuado
pub fn to_hex(val int) string {
	/*
	TODO
	byte_max  := int(HexOutput.byte)
	word_max  := int(HexOutput.word)
	dword_max := int(HexOutput.dword)
	*/
	return '0x$val.hex().str().to_upper()'
}

pub enum HexOutput {
	byte = 255
	word = 510
	dword = 1020
}
