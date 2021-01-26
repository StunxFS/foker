// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

// import compiler.gen.binary
import os
import v.depgraph
import compiler.ast
import compiler.util
import compiler.about
import compiler.prefs
import compiler.parser
import compiler.checker

fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ['-h', '-a', 'help', 'ayuda']) {
		about.help()
		exit(1)
	}
	mut b := new_builder()
	b.compile()
}
