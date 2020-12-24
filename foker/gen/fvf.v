// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module gen

import os

const (
	separator = '#-- ponga aqui abajo sus flags --#'
)

struct FVF {
mut:
	vars	map[string]bool
	flags	map[string]bool
}

pub fn new_fvf(file string) ?FVF {
	content := os.read_file(file)?
	content_splitted := content.split(separator)
	mut vars := map[string]bool{}
	mut flags := map[string]bool{}
	if content_splitted.len == 2 {
		for v in content_splitted[0].split('\n') { // variables
			if v != "" { vars[v] = false }
		}
		for f in content_splitted[1].split('\n') { // flags
			if f != "" { flags[f] = false }
		}
	}
	return FVF{
		vars: vars
		flags: flags
	}
}

pub fn (mut fvf FVF) get_var() ?string {
	for k, v in fvf.vars {
		if !v { // no used
			return k
		}
	}
	return error("no se ha podido obtener una variable, ya que todas están ocupadas")
}

pub fn (mut fvf FVF) get_flag() ?string {
	for k, v in fvf.flags {
		if !v { // no used
			return k
		}
	}
	return error("no se ha podido obtener una flag, ya que todas están ocupadas")
}

pub fn (mut fvf FVF) free_var(var string) ? {
	if var in fvf.vars {
		if fvf.vars[var] { // used
			fvf.vars[var] = false
		} else {
			return error("imposible liberar la variable '${var}': no está en uso tal variable")
		}
	} else {
		return error("imposible liberar la variable '${var}': no existe tal variable")
	}
} 

pub fn (mut fvf FVF) free_flag(flag string) ? {
	if flag in fvf.flags {
		if fvf.flags[flag] { // used
			fvf.flags[flag] = false
		} else {
			return error("imposible liberar la flag '${flag}': no está en uso tal flag")
		}
	} else {
		return error("imposible liberar la flag '${flag}': no existe tal flag")
	}
}

pub fn make_new_fvf_file() ? {
	os.write_file("fvf.txt", separator)?
}
