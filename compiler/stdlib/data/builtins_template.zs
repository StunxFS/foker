/*
* builtins.zs | Archivo creado para la generación de comandos, variables y alias
* debido a que ZubatScript no soporta la modularización.
* NOTA: Por favor, usar este código con cuidado.
*/

#if BINARY
//! Para comparar los resultados de ciertos comandos que utilizan esta
//! variable para depositar valores. (ejemplo: checkgender)
var LASTRESULT at 0x8000: int;
var LASTTALKED at 0x800F: int;

<stdlib.zs>

#endif

//! Comandos básicos de ROMHacking
cmd msgbox(
	msg: string
#if BINARY
	, type: int = 6
#endif
);
alias msg = msgbox;
