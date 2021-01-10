// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

const (
	builtins_file = 'in_memory/builtins.zs'
	builtins_code = '
/*
* Builtins.fkr | Archivo guardado en memoria para la generación de comandos, variables y alias
* debido a que ZubatScript no soporta la modularización.
* NOTA: Por favor, usar este código con cuidado.
*/

#if !DECOMP
// variable utilizada para comparar los resultados de ciertos comandos que utilizan a esta
// para depositar valores. (ejemplo: checkgender)
var LASTRESULT at 0x8000: int;
#endif

//! Comandos básicos de ROMHacking
cmd msgbox(msg: string, type: int = 6);
'
)
