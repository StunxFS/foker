// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module util

[inline]
pub fn is_name_char(c byte) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`
}

/*
[inline]
pub fn is_func_char(c byte) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_` || c.is_digit()
}
*/
[inline]
pub fn is_nl(c byte) bool {
	return c == `\r` || c == `\n`
}

pub fn contains_capital(s string) bool {
	for c in s {
		if c.is_capital() {
			return true
		}
	}
	return false
}

pub fn is_pure_capital(s string) bool {
	mut res := false
	for c in s {
		res = c.is_capital() || c.is_digit()
	}
	return res
}

pub fn cescaped_path(s string) string {
	return s.replace('\\', '\\\\')
}
