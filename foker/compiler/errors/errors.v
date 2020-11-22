// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module errors

import compiler.token

pub enum Reporter {
	scanner
	parser
	checker
	gen
}

pub struct Error {
pub:
	message   string
	file_path string
	pos       token.Position
	reporter  Reporter
}

pub struct Warning {
pub:
	message   string
	file_path string
	pos       token.Position
	reporter  Reporter
}
