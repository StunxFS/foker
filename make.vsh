// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de FokerScript
//

$if macos {
	panic('lo sentimos, macOS todavía no es soportado.')
}

exe_name := $if windows {
	'foker.exe'
} $else {
	'foker'
}

if !exists('bin') {
	mkdir('bin')
}

const (
    foker_bin_path = join_path('bin', exe_name)
)

if !exists(foker_bin_path) {
	println('- Compilando el compilador de FokerScript...')
	system('v -prod -o ${foker_bin_path} foker/')
} else {
	println('- Saltando compilación del compilador de FokerScript, esto ya está compilado...')
}
