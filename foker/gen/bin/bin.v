// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module bin

import compiler.about

struct FScript {
pub:
	name			string
mut:
	dynamic			string = "800000"
	str_count		int
	strings			map[string]string
	blocks			[]FBlock
}

pub fn new_fscript(name string) FScript {
	return {
		name: name
	}
}

/*pub fn new_fscript_with_vffile(name string, vffile_name string) {
	fs := new_fscript(name)
	
}*/

pub fn (mut fs FScript) change_dynamic(new_dyn string) {
	fs.dynamic = new_dyn
}

pub fn (mut fs FScript) add_block(block FBlock) {
	fs.blocks << block
}

pub fn (mut fs FScript) add_tmp_string(str string) string {
	name := "str${fs.str_count}"
	fs.str_count++
	fs.strings[name] = str
	return name
}

pub fn (mut fs FScript) add_string(name string, str string) {
	fs.strings[name] = str
}

pub fn (fs FScript) generate_script() string {
	mut code := ["; Generate with Foker v${about.version}", "#dynamic ${fs.dynamic}", ""]
	for block in fs.blocks {
		for code_ in block.code {
			code << code_
		}
		code << ""
	}
	code << "; strings init"
	for k, v in fs.strings {
		code << ["#org @${k}", "= ${v}", ""]
	}
	return code.join("\n")
}

