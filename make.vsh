// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de ZubatScript
//
import os

fn help() {
	eprintln('make.vsh solo reconoce los siguientes comandos:')
	eprintln('    build             Para compilar el proyecto')
	eprintln('    build-and-test    Para compilar el proyecto y correr una prueba rápida')
	eprintln('    test              Para hacer una prueba rápida')
	eprintln('    build-for-release Para crear un binario del proyecto optimizado y listo para usarse')
	eprintln('    symlink           Para hacer un symlink del compilador')
}

$if macos {
	panic('make.vsh: lo sentimos, macOS todavía no está soportado.')
}
exe_name := $if windows { 'zubat.exe' } $else { 'zubat' }
exe_symlink := $if windows { 'zubat-symlink.exe' } $else { 'zubat-symlink' }
exec_symlink := $if windows { r'.\zubat-symlink.exe' } $else { './zubat-symlink' }
if os.args.len > 2 || os.args.len == 1 {
	eprintln('make.vsh necesita un comando para funcionar')
	help()
}
cmd := os.args[1]
match cmd {
	'build' {
		if exists(exe_name) {
			println('> Removiendo el antiguo compilador...')
			rm(exe_name)?
		}
		println('> Compilando a ZubatScript...')
		system('v -cg -o $exe_name cmd/')
	}
	'build-for-release' {
		if exists(exe_name) {
			println('> Removiendo el antiguo compilador...')
			rm(exe_name)?
		}
		println('> Compilando a ZubatScript con optimizaciones...')
		system('v -prod -o $exe_name cmd/')
	}
	'build-and-test' {
		if exists(exe_name) {
			println('> Removiendo el antiguo compilador...')
			rm(exe_name)?
		}
		println('> Compilando a ZubatScript...')
		if system('v -cg -o $exe_name cmd/') == 0 {
			println('> Ejecutando el ejecutable generado para ver si funciona...')
			system('./zubat compiler/tests/zubat_test.zs')
		}
	}
	'test' {
		if exists(exe_name) {
			println('> Ejecutando el compilador para ver si funciona...')
			system('./zubat compiler/tests/zubat_test.zs')
		} else {
			println('> Use el comando build-and-test')
		}
	}
	'symlink' {
		if !exists(exe_symlink) {
			println('> Compilando la herramienta para symlink...')
			system('v -prod -o $exe_symlink cmd/tools/zs_symlink.v')
		} else {
			println('> Saltando la compilación para la herramienta de symlinking, esto ya está compilado...')
		}
		println('> Ejecutando ${exe_symlink}...')
		system(exec_symlink)
		rm(exe_symlink)?
	}
	else {
		eprintln('make.vsh: comando `$cmd` desconocido')
		help()
	}
}
