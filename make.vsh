// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de FokerScript
//

$if macos {
	panic("make.vsh: lo sentimos, macOS todavía no está soportado.")
}

exe_name := $if windows { "zubatscript.exe" } $else { "zubatscript" }

if !exists(exe_name) {
	println('> Compilando a ZubatScript...')
	system('v -prod -o ${exe_name} cmd/main.v')
} else {
	println('> Saltando la compilación para FokerScript, esto ya está compilado...')
}
