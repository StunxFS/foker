// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de ZubatScript
//
import os

$if macos {
	panic('make.vsh: lo sentimos, macOS todavía no está soportado.')
}
exe_name := $if windows { 'zubat.exe' } $else { 'zubat' }
exe_symlink := $if windows { 'zubat-symlink.exe' } $else { 'zubat-symlink' }
exec_symlink := $if windows { '.\zubat-symlink.exe' } $else { './zubat-symlink' }
if os.args.len > 2 || os.args.len == 1 {
	panic('make.vsh necesita un comando para funcionar')
}
cmd := os.args[1]
match cmd {
	'build' {
		if exists(exe_name) {
			println('> Removiendo el antiguo compilador...')
			rm(exe_name)
		}
		println('> Compilando a ZubatScript...')
		system('v -prod -o $exe_name cmd/zubat.v')
	}
	'symlink' {
		if !exists(exe_symlink) {
			println('> Compilando la herramienta para symlink...')
			system('v -prod -o $exe_symlink cmd/tools/zs_symlink.v')
			println('> Ejecutando ${exe_symlink}...')
			system(exec_symlink)
			rm(exe_symlink)
		} else {
			println('> Saltando la compilación para la herramienta de symlinking, esto ya está compilado...')
		}
	}
	else {
		panic('make.vsh: comando `$cmd` desconocido')
	}
}
