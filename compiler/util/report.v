// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module util

pub struct Report {
pub:
	msg  string // mensaje del reporte
	kind ReportKind
}

pub enum ReportKind {
	error
	note
	warning
}
