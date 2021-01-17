// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.

// Este script genera un archivo 'builtins.zs' único con todas las constantes usadas
// en el scripting de XSE.

import strings

const ignored = ['stdmoves.rbh']

files := ls('.')?
headers := files.filter(it.ends_with('.rbh'))

mut stdlib_zs := strings.new_builder(100)
builtins := read_file('builtins_template.zs')?

for header in headers {
	if header in ignored { continue }
	content := read_file(header)?
	header_content := content.split_into_lines()
	stdlib_zs.writeln('// Desde: "$header"')
	for line in header_content {
		if line == '' { continue }
		tokens := line.split(' ')
		match tokens[0] {
			'#define' {
				mut name := tokens[1].to_upper().replace_each(['/', '_OR_', '-', '_TO_', '+', 'MORE', '%', '_PERCENTAGE'])
				if name[0].is_digit() {
					name = '_' + name
				}
				val := tokens[2]
				stdlib_zs.writeln('const $name = $val;')
			}
			else {}
		}
	}
	stdlib_zs.writeln('')
}

write_file('builtins.zs', builtins.replace('<stdlib.zs>', stdlib_zs.str().trim_space()))?
