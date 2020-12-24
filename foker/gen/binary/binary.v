// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

import about
import gen

pub fn to_hex(val int) string {
	/* TODO
	byte_max  := int(HexOutput.byte)
	word_max  := int(HexOutput.word)
	dword_max := int(HexOutput.dword)
	*/
	return '0x${val.hex().str().to_upper()}'
}

pub enum HexOutput {
	byte  = 255
	word  = 510
	dword = 1020
}

struct FScript {
pub:
	name			string
mut:
	dynamic			string = "800000"
	fvf				gen.FVF
	str_count		int
	label_count		int
	movs_count		int
	strings			map[string]string
	strings_temp	map[string]string
	movements		map[string]FBlock
	movements_temp  map[string]FBlock
	blocks			[]FBlock
}

pub fn new_fscript(name string) FScript {
	return {
		name: name
	}
}

pub fn new_fscript_with_vffile(name string, vffile_name string) FScript {
	mut fs := new_fscript(name)
	fs.fvf = gen.new_fvf(vffile_name) or {
		panic("gen.binary.FScript.new_fscript_with_vffile: " + err)
	}
	return fs
}

pub fn (mut fs FScript) new_label() string {
	label :=  "fs_label_${fs.label_count}"
	fs.label_count++
	return label
}

pub fn (mut fs FScript) change_dynamic(new_dyn string) {
	fs.dynamic = new_dyn
}

pub fn (mut fs FScript) add_block(block FBlock) {
	fs.blocks << block
}

pub fn (mut fs FScript) add_tmp_string(str string) string {
	name := "str${fs.str_count}"
	fs.str_count++
	fs.strings_temp[name] = str
	return name
}

pub fn (mut fs FScript) add_string(name string, str string) {
	fs.strings[name] = str
}

pub fn (mut fs FScript) add_movement(name string, block FBlock) {
	fs.movements[name] = block
}

pub fn (mut fs FScript) add_movement_temp(block FBlock) {
	fs.movements["mov${fs.movs_count}"] = block
	fs.movs_count++
}

pub fn (fs FScript) generate_script() string {
	fsdyn := if fs.dynamic.starts_with('0x') {fs.dynamic} else {"0x"+fs.dynamic}
	mut code := [
		"; Generado con FokerScript v${about.version}, by StunxFS :)",
		"; NO MODIFICAR, si NO SABES LO QUE HACES",
		"#dynamic ${fsdyn}", ""
	]
	for block in fs.blocks {
		for code_ in block.code {
			code << code_
		}
		code << ""
	}

	// strings temporales
	code << "; strings temporales"
	for k, v in fs.strings_temp {
		code << ["#org @${k}", "= ${v}", ""]
	}
	
	// strings desde constantes
	code << "; literales de cadenas (constantes)"
	for k, v in fs.strings {
		code << ["#org @${k}", "= ${v}", ""]
	}

	// movimientos temporales (movement{})
	code << "; movimientos (temporales)"
	for _, v in fs.movements_temp {
		for code_ in v.code {
			code << code_
		}
		code << ""
	}
	code << ""

	// movimientos desde constantes
	code << "; movimientos (constantes)"
	for _, v in fs.movements {
		for code_ in v.code {
			code << code_
		}
		code << ""
	}
	code << ""
	return code.join("\n")
}
