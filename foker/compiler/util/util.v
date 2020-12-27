// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module util

import os
import about

// full_fokerscript_version() retorna la version completa del compilador de FokerScript
pub fn full_fokerscript_version() string {
	return 'FokerScript ${about.version}'
}

pub fn set_fsroot_folder(fsroot_path string) {
	fsname := if os.user_os() == 'windows' { 'fokerscript.exe' } else { 'fokerscript' }
	os.setenv('FSEXE', os.real_path(os.join_path(fsroot_path, fsname)), true)
}

pub fn quote_path(s string) string {
	mut qs := s
	if qs.contains('&') {
		qs = qs.replace('&', '\\&')
	}
	if qs.contains(' ') {
		return '"${qs}"'
	}
	return qs
}

pub fn args_quote_paths(args []string) string {
	mut res := []string{}
	for a in args {
		res << quote_path(a)
	}
	return res.join(' ')
}

pub fn path_of_executable(path string) string {
	$if windows {
		return path + '.exe'
	}
	return path
}

pub fn read_file(file_path string) ?string {
	raw_text := os.read_file(file_path) or {
		return error('failed to open ${file_path}')
	}
	return skip_bom(raw_text)
}

pub fn skip_bom(file_content string) string {
	mut raw_text := file_content
	if raw_text.len >= 3 {
		unsafe {
			c_text := raw_text.str
			if c_text[0] == 0xEF && c_text[1] == 0xBB && c_text[2] == 0xBF {
				offset_from_begin := 3
				raw_text = tos(c_text[offset_from_begin], vstrlen(c_text) - offset_from_begin)
			}
		}
	}
	return raw_text
}

[inline] pub fn imin(a int, b int) int {
	return if a < b { a } else { b }
}

[inline] pub fn imax(a int, b int) int {
	return if a > b { a } else { b }
}

pub fn strip_mod_name(name string) string {
	return name.all_after_last('.')
}

pub fn no_dots(s string) string {
	return s.replace('.', '__')
}
