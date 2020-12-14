// Copyright (c) 2020 Pizcofy. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os

// Script de compilación de FokerScript
fn main() {
	$if macos {
		panic('lo sentimos, macOS todavía no es soportado.')
	} $else {
		mut exe_name := 'foker'
		$if windows {
			exe_name += '.exe'
		}
		os.system('v -prod -o ${exe_name} foker')
	}
}
