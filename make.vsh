// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de FokerScript
// Especial para compilar el compilador y el administrador de proyectos FPM
//

$if macos {
	panic('lo sentimos, macOS todavía no es soportado.')
}

exe_name := $if windows {
	'foker.exe'
} $else {
	'foker'
}
fpm_exe_name := $if windows {
	'fpm.exe'
} $else {
	'foker'
}

if !exists('bin') {
	mkdir('bin')
}

foker_bin_path := join_path('bin', exe_name)
fpm_bin_path := join_path('bin', fpm_exe_name)

if !exists(exe_name) {
	println('- Compilando el compilador de FokerScript...')
	system('v -prod -o ${foker_bin_path} foker/')
} else {
	println('- Saltando compilación del compilador de FokerScript, esto ya está compilado...)
}
//system('v -prod -o ${fpm_bin_path} fpm/')
