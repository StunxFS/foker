// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de ZubatScript
//

$if macos {
	panic("make.vsh: lo sentimos, macOS todavía no está soportado.")
}

exe_name := $if windows { "zubat.exe" } $else { "zubat" }

if !exists(exe_name) {
	println('> Compilando a ZubatScript...')
	system('v -prod -o ${exe_name} cmd/main.v')
} else {
	println('> Saltando la compilación para ZubatScript, esto ya está compilado...')
}
