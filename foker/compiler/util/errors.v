// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module util

import os
import term
import compiler.token

pub const (
	emanager = new_error_manager()
)

pub struct EManager {
mut:
	support_color	bool
}

pub fn new_error_manager() &EManager {
	return &EManager{
		support_color: term.can_show_color_on_stderr() && term.can_show_color_on_stdout()
	}
}

pub fn (e &EManager) set_support_color(b bool) {
	unsafe {
		mut me := e
		me.support_color = b
	}
}

pub fn bold(msg string) string {
	if !emanager.support_color {
		return msg
	}
	return term.bold(msg)
}

fn color(kind string, msg string) string {
	if !emanager.support_color {
		return msg
	}
	if kind.contains('error') {
		return term.red(msg)
	} else { // 'note' or 'warning'
		return term.magenta(msg)
	}
}

pub fn formatted_error(kind string, msg string, filepath string, pos token.Position) string {
	mut path := filepath
	workdir := os.getwd() + os.path_separator
	if path.starts_with(workdir) {
		path = path.replace(workdir, '')
	}

	source, column := filepath_pos_to_source_and_column(filepath, pos)
	position := "${path}:${pos.line_nr+1}:${imax(1, column + 1)}:"

	mut sline := ''
	println(column.str() + "<<<< column")
	if pos.line_nr <= source.split_into_lines().len {
		sline = source.split_into_lines()[pos.line_nr]
		start_column := imax(0, imin(column, sline.len))
		end_column := imax(0, imin(column + imax(0, pos.len), sline.len))
		sline = "${pos.line_nr+1:5d} | " +
				sline[..start_column] + color(kind, sline[start_column..end_column]) + sline[end_column..]
		println(sline)
	}

	final_position := bold(position)
	final_kind := bold(color(kind, kind))
	final_context := if sline.len > 0 { '\n${sline}' } else { '' }
	return '$final_position $final_kind $msg$final_context'.trim_space()
}

pub fn filepath_pos_to_source_and_column(filepath string, pos token.Position) (string, int) {
	source := read_file(filepath) or {
		''
	}
	mut p := imax(0, imin(source.len - 1, pos.pos))
	if source.len > 0 {
		for ; p >= 0; p-- {
			if source[p] == `\n` || source[p] == `\r` {
				break
			} 
		}
	}
	column := imax(0, pos.pos - p - 1)
	return source, column
}

pub fn fserror(kind string, s string) {
	final_kind := bold(color(kind, kind))
	eprintln("${final_kind}: ${s}")
	exit(1)
}

pub fn fslines_escape_path(path string) string {
	return cescaped_path(os.real_path(path))
}
