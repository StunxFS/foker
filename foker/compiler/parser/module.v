// Copyright (c) 2020 Pizcofy. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module parser

fn (p &Parser) prepend_mod(name string) string {
	if p.expr_mod != '' {
		return p.expr_mod + '.' + name
	}
	if p.builtin_mod {
		return name
	}
	return '${p.mod}.$name'
}
