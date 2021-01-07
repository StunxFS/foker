// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

import compiler.about
import compiler.emitter as gen

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
	includes		[]string
	constantes		[]string
	str_count		int
	label_count		int
	movs_count		int
	question_count  int
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
		panic("compiler.emitter.binary.FScript.new_fscript_with_vffile: " + err)
	}
	return fs
}

pub fn (mut fs FScript) new_label() string {
	label :=  "fs_snippet${fs.label_count}"
	fs.label_count++
	return label
}

pub fn (mut fs FScript) new_question_label() string {
	label := "fs_question_${fs.question_count}"
	fs.question_count++
	return label
}

pub fn (mut fs FScript) change_dynamic(new_dyn string) {
	fs.dynamic = new_dyn
}

pub fn (mut fs FScript) add_include(file string) {
	if file !in fs.includes {
		fs.includes << '#include "${file}"'
	}
}

pub fn (mut fs FScript) add_const(name string, expr string) {
	fs.constantes << '#define '+(name + ' ' + expr)
}

pub fn (mut fs FScript) add_block(block FBlock) {
	fs.blocks << block
}

pub fn (mut fs FScript) add_tmp_string(str string) string {
	name := "string${fs.str_count}"
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
	fs.movements["move${fs.movs_count}"] = block
	fs.movs_count++
}

pub fn (fs FScript) generate_script() string {
	fsdyn := if fs.dynamic.starts_with('0x') { fs.dynamic } else { "0x"+fs.dynamic }
	mut code := [
		"; Generado con ZubatScript v${about.version}, hecho por StunxFS :).",
		"; NO MODIFICAR, SI NO SABES LO QUE HACES.",
		"#dynamic ${fsdyn}", "", fs.includes.join('\n'),"", fs.constantes.join("\n"), ""
	]

	for block in fs.blocks {
		for code_ in block.code {
			code << code_
		}
		code << ""
	}

	// strings temporales
	if fs.strings_temp.len > 0 {
		code << "; strings (temporales)"
		for k, v in fs.strings_temp {
			code << ["#org @${k}", "= ${v}", ""]
		}
	}
	
	// strings desde constantes
	if fs.strings.len > 0 {
		code << "; strings (constantes)"
		for k, v in fs.strings {
			code << ["#org @${k}", "= ${v}", ""]
		}
	}

	// movimientos temporales (movement{})
	if fs.movements_temp.len > 0 {
		code << "; movimientos (temporales)"
		for _, v in fs.movements_temp {
			for code_ in v.code {
				code << code_
			}
			code << ""
		}
		code << ""
	}

	// movimientos desde constantes
	if fs.movements.len > 0 {
		code << "; movimientos (constantes)"
		for _, v in fs.movements {
			for code_ in v.code {
				code << code_
			}
			code << ""
		}
	}
	return code.join("\n")
}
