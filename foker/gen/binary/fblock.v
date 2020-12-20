// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

struct FBlock {
mut:
	code	[]string
}

pub fn new_fblock(name string) FBlock {
	return {
		code: ["#org @${name}"]
	}
}

pub fn (mut block FBlock) add_code(line string) {
	block.code << line
}

pub fn (mut block FBlock) add_cmd(cmd string, params []string) {
	block.add_code(if params.len > 0 { "${cmd} "+params.join(", ") } else { cmd })
}

pub fn (mut block FBlock) end() {
	block.add_code("end")
}

