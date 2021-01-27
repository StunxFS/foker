/*
* builtins.zs | Archivo creado para la generación de comandos, variables y alias.
* Este depende de builtins_bin.zs y builtins_decomp.zs
*/

#if __BINARY__
import std::builtins::builtins_bin;
#else
import std::builtins::builtins_decomp; // __DECOMP__
#endif

//! Comandos básicos de ROMHacking
cmd msgbox(
	msg: string
#if __BINARY__
	, type: int
#endif
);
alias msg = msgbox;

/*
TODO: Soporte de macros:
macro msgbox6 {
     ($msg: expr) : stmt => msgbox($msg, 6);
}
*/
