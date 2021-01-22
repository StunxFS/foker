// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

import os

struct FVF {
mut:
	content map[string]bool
}

pub fn new_fvf(text string) FVF {
	content_splitted := text.split('\n')
	mut cnt := map[string]bool{}
	for c in content_splitted {
		if c.starts_with('#') || c == '' { // comentarios
			continue
		}
		mut d := c
		if d.contains('#') {
			d = d.all_before('#').trim_space()
		}
		cnt[d] = false
	}
	return FVF{
		content: cnt
	}
}

pub fn new_fvf_from_file(file string) ?FVF {
	content := os.read_file(file) ?
	return new_fvf(content)
}

pub fn (mut fvf FVF) get() ?string {
	for k, v in fvf.content {
		if !v { // no used
			fvf.content[k] = true
			return k
		}
	}
	return error('no se ha podido obtener un id, ya que todos están ocupados')
}

pub fn (mut fvf FVF) free(id string) ? {
	if id in fvf.content {
		if fvf.content[id] { // used
			fvf.content[id] = false
		} else {
			return error("imposible liberar el id '$id': no está en uso tal id")
		}
	} else {
		return error("imposible liberar el id '$id': no existe tal id")
	}
}
