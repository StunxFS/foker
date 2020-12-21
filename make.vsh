// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de FokerScript
// Especial para compilar el compilador y el administrador de proyectos FPM
//


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

$if macos {
	panic('lo sentimos, macOS todavía no es soportado.')
}

if !exists('bin') {
	mkdir('bin')
}

foker_bin_path := join_path('bin', exe_name)
fpm_bin_path := join_path('bin', fpm_exe_name)

system('v -prod -o ${foker_bin_path} foker/')
//system('v -prod -o ${fpm_bin_path} fpm/')
