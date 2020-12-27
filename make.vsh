// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
//
// Script de compilación de FokerScript
//

/*
>>> import dis
>>> dis.dis("if 100 > 100 and 200 == 300: println('cool')")
  1           0 LOAD_CONST               0 (100)
              2 LOAD_CONST               0 (100)
              4 COMPARE_OP               4 (>)
              6 POP_JUMP_IF_FALSE       24
              8 LOAD_CONST               1 (200)
             10 LOAD_CONST               2 (300)
             12 COMPARE_OP               2 (==)
             14 POP_JUMP_IF_FALSE       24
             16 LOAD_NAME                0 (println)
             18 LOAD_CONST               3 ('cool')
             20 CALL_FUNCTION            1
             22 POP_TOP
        >>   24 LOAD_CONST               4 (None)
             26 RETURN_VALUE
>>> dis.dis("if 100 > 100 or 200 == 300: println('cool')")
  1           0 LOAD_CONST               0 (100)
              2 LOAD_CONST               0 (100)
              4 COMPARE_OP               4 (>)
              6 POP_JUMP_IF_TRUE        16
              8 LOAD_CONST               1 (200)
             10 LOAD_CONST               2 (300)
             12 COMPARE_OP               2 (==)
             14 POP_JUMP_IF_FALSE       24
        >>   16 LOAD_NAME                0 (println)
             18 LOAD_CONST               3 ('cool')
             20 CALL_FUNCTION            1
             22 POP_TOP
        >>   24 LOAD_CONST               4 (None)
             26 RETURN_VALUE
>>> 

*/

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

foker_bin_path := join_path('bin', exe_name)

if !exists(foker_bin_path) {
	println('- Compilando el compilador de FokerScript...')
	system('v -prod -o ${foker_bin_path} foker/')
} else {
	println('- Saltando compilación del compilador de FokerScript, esto ya está compilado...')
}
