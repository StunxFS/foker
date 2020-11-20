// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import compiler.about
//import compiler.token
//import compiler.prefs
import generation
import os

enum HexOutput {
	byte  = 255
	word  = 510
	dword = 1020
}

fn to_hex(val int, output HexOutput) string {
	/*
	byte_max  := int(HexOutput.byte)
	word_max  := int(HexOutput.word)
	dword_max := int(HexOutput.dword)
	*/
	return "0x${val.hex().str().to_upper()}"
}

fn main() {
	println("FokerScript v${about.version}")
	//println(token.Token{.name, 'foker_name', 2, 122, 10})
	
	mut script := generation.new_fscript("main")
	script.add_string("stunx", "Me llamo stunx")
	
	mut block := generation.new_fblock("main")
		block.add_cmd("msgbox", ["@stunx", "0x2"])
		block.add_cmd("msgbox", ["@"+script.add_tmp_string("String temporal"), "0x2"])
		block.end()
	script.add_block(block)
	
	block = generation.new_fblock("main_2")
		block.add_cmd("msgbox", ["@stunx", "0x2"])
		block.add_cmd("msgbox", ["@"+script.add_tmp_string("String temporal"), "0x2"])
		block.end()
	script.add_block(block)
	
	os.write_file("${script.name}.rbh", script.generate_script())?
}

