// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os

const (
	exe_name = $if windows {
		'foker.exe'
	} $else {
		'foker'
	}
)

// Script de compilación de FokerScript
$if macos {
	panic('lo sentimos, macOS todavía no es soportado.')
} $else {
	os.system('v -prod -o ${exe_name} foker')
}
