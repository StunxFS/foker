// Copyright (c) 2020 Pizcofy. All rights reserved.
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

pub enum ReportKind {
	error
	warning
	note
}

pub struct Report {
pub:
	message   string
	file_path string
	pos       token.Position
	reporter  Reporter
	kind	  ReportKind
}

pub fn (r []Report) report_to_user() bool {
	mut hubo_errores := false
	for report in r {
		println(report.message)
		hubo_errores = true
	}
	return hubo_errores
}
