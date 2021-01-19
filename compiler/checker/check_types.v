// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

import compiler.ast

pub fn (mut c Checker) check_basic(got ast.Type, expected ast.Type) bool {
	if got == expected {
		return true
	}
	return false
}

pub fn (mut c Checker) check_expected(got ast.Type, expected ast.Type) ? {
	if c.check_basic(got, expected) {
		return
	}
	return error(c.expected_msg(got, expected))
}

[inline]
fn (c &Checker) expected_msg(got ast.Type, expected ast.Type) string {
	exps := ast.type_to_str(expected)
	gots := ast.type_to_str(got)
	return "se esperaba '$exps', no '$gots'"
}
