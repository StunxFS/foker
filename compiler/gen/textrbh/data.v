// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module textrbh

import os

struct Data {
mut:
	content map[string]bool
}

pub fn new_data(text string) Data {
	content_splitted := text.split_into_lines()
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
	return Data{
		content: cnt
	}
}

pub fn new_data_from_file(file string) ?Data {
	content := os.read_file(file) ?
	return new_data(content)
}

pub fn (mut data Data) get() ?string {
	for k, v in data.content {
		if !v { // no used
			data.content[k] = true
			return k
		}
	}
	return error('no se ha podido obtener una variable/flag, ya que todos están ocupados')
}

pub fn (mut data Data) free(id string) ? {
	if id in data.content {
		if data.content[id] { // used
			data.content[id] = false
		} else {
			return error("imposible liberar el variable '$id': no está en uso")
		}
	} else {
		return error("imposible liberar el la variable '$id': no existe")
	}
}
