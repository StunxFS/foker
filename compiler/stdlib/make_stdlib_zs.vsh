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

mut gflags := map[string][]string{}

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
				taks := name.split('_')
				if taks[0] in ['RS', 'EM', 'FR'] {
					g := taks[0]
					gflags[g] << 'const $name = $val;'
					continue
				}
				stdlib_zs.writeln('const $name = $val;')
			}
			else {}
		}
	}
	stdlib_zs.writeln('')
}

stdlib_zs.writeln('// Desde "stdlib.rbh", constantes por juego')
for k, v in gflags {
	stdlib_zs.writeln('#if $k')
	stdlib_zs.writeln(v.join('\n'))
	stdlib_zs.writeln('#endif')
	stdlib_zs.writeln('')
}

write_file('builtins.zs', builtins.replace('<stdlib.zs>', stdlib_zs.str().trim_space()))?
