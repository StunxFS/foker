// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de ZubatScript
//

$if macos {
	panic("make.vsh: lo sentimos, macOS todavía no está soportado.")
}

exe_name := $if windows { "zubat.exe" } $else { "zubat" }
exe_symlink := $if windows { "zubat-symlink.exe" } $else { "zubat-symlink" }

if !exists(exe_name) {
	println('> Compilando a ZubatScript...')
	system('v -prod -o ${exe_name} cmd/main.v')
} else {
	println('> Saltando la compilación para ZubatScript, esto ya está compilado...')
}

if !exists(exe_symlink) {
	println('> Compilando la herramienta para symlink...')
	system('v -prod -o ${exe_name} cmd/zubascript_symlink.v')
} else {
	println('> Saltando la compilación para la herramienta de symlinking, esto ya está compilado...')
}
