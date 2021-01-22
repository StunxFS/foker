// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

import compiler.errors
import compiler.token
import compiler.util

pub fn (mut c Checker) warn(s string, pos token.Position) {
	allow_warnings := !(c.pref.optlevel == .fast || c.pref.warns_are_errors)
	c.warn_or_error(s, pos, allow_warnings)
}

pub fn (mut c Checker) error(message string, pos token.Position) {
	if c.pref.is_verbose {
		print_backtrace()
	}
	c.warn_or_error(message, pos, false)
}

fn (mut c Checker) warn_or_error(message string, pos token.Position, warn bool) {
	mut details := ''
	if c.errors_details.len > 0 {
		details = c.errors_details.join('\n')
		c.errors_details = []
	}
	if warn && !c.pref.skip_warnings {
		c.nr_warnings++
		wrn := errors.Report{
			message: util.formatted_error('advertencia:', message, pos)
			file_path: pos.filepath
			pos: pos
			kind: .warning
		}
		c.file.reports << wrn
		// c.warnings << wrn
		return
	}
	if !warn {
		c.nr_errors++
		if pos.line_nr !in c.error_lines {
			err := errors.Report{
				message: util.formatted_error('error:', message, pos)
				pos: pos
				file_path: pos.filepath
				kind: .error
			}
			c.file.reports << err
			// c.errors << err
			c.error_lines << pos.line_nr
		}
	}
}
