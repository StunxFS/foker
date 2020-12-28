// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

const (
builtins_file = 'in_memory/builtins.fkr'

/*
* Builtins.fkr | Archivo guardado en memoria para la generación de comandos, variables y alias
* debido a que FokerScript no soporta la modularización.
* NOTA: Por favor, usar este código con cuidado.
*/

// ======================= BUILTINS PARA BINARIO ===============================================

builtins_code ='
// variable utilizada para comparar los resultados de ciertos comandos que utilizan a esta
// para depositar valores. (ejemplo: checkgender)
var LASTRESULT at 0x800D: int;

//! Comandos básicos de ROMHacking
cmd msgbox(msg: string, type: byte = 6);
'

// ======================= BUILTINS PARA DECOMP =================================================

builtins_code_decomp ='
//! Comandos básicos de Decompilación
// TODO
'
)
