// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module prefs

import os
import os.cmdline
import compiler.util
import compiler.about

// Game enumera los juegos que ZubatScript soporta actualmente.
pub enum Game {
	firered_leafgreen
	ruby_sapphire
	emerald
}

// Backend enumera los backends soportados por ahora
pub enum Backend {
	decomp
	binary
}

// BuildMode enumera los 2 modos de compilación para el backend de binario
// 'text' y 'direct'
pub enum BuildMode {
	text
	direct
}

// OptLevel enumera los 2 niveles de optimización que existen
pub enum Optlevel {
	fast
	debug
}

// UserColor enumera las 2 opciones que hay para mostrar mensajes de error
// con colores o no
pub enum UseColor {
	always
	never
}

// Preferences, struct universal de las opciones que el usuario le pasa al compilador
pub struct Preferences {
pub mut:
	// ROM en el que se usará el script generado. Esto es usado para
	// generar código exacto sin problemas.
	game              Game      = .firered_leafgreen
	backend           Backend   = .binary
	build_mode        BuildMode = .text
	rom               string // la rom en la que se insertará el script
	flags_file        string = 'flags.data.txt'
	vars_file         string = 'vars.data.txt'
	output            string // nombre de salida del script
	optlevel          Optlevel = .debug
	skip_warnings     bool   // saltarse las advertencias
	warns_are_errors  bool   // tratar las advertencias como errores
	file_dir          string // el directorio en donde se encuentra el archivo
	file              string // archivo a compilar
	is_verbose        bool   // el compilador debe detallar cada cosa que hace
	use_color         UseColor
	only_check_syntax bool
	is_library        bool // para evitar pedir un script 'main'
	defines           []string = ['__FIRERED_LEAFGREEN__', '__BINARY__', '__DEBUG__']
}

// parse_arg_and_get_prefs, trabaja con los argumentos del programa
pub fn parse_args_and_get_prefs() &Preferences {
	app := os.args[0]
	args := os.args[1..]
	mut res := &Preferences{}
	for i := 0; i < args.len; i++ {
		arg := args[i]
		current_args := args[i..]
		match arg {
			'-b', '-backend' {
				target_backend := cmdline.option(current_args, arg, '')
				match target_backend {
					'binary' {
						res.backend = .binary
					}
					'decomp' {
						res.backend = .decomp
						res.defines[res.defines.index('__BINARY__')] = '__DECOMP__'
					}
					else {
						util.err("la opción $arg solo soporta los valores 'binary' o 'decomp'")
					}
				}
				i++
			}
			'-d', '-define' {
				to_define := cmdline.option(current_args, arg, '')
				if to_define.to_lower() in ['true', 'false'] {
					util.err('no se puede definir valores booleanos constantes (true y false)')
				}
				if to_define.starts_with('__') && to_define.ends_with('__') {
					util.err('esta forma de declaración está reservada por el compilador: $to_define')
				}
				if to_define != '' {
					if to_define !in res.defines {
						res.defines << to_define
					} else {
						util.err('esta bandera ya está definida: $to_define')
					}
				} else {
					util.err('no se puede definir una bandera vacía: $to_define')
				}
				i++
			}
			'-u', '-undefine' {
				to_undefine := cmdline.option(current_args, arg, '')
				if to_undefine == '' {
					util.err('no se puede indefinir una bandera vacía: $to_undefine')
				}
				if to_undefine !in res.defines {
					util.err('no se puede indefinir una bandera no definida: $to_undefine')
				}
				if to_undefine.starts_with('__') && to_undefine.ends_with('__') {
					util.err('esta tipo de banderas no se pueden indefinir: $to_undefine')
				}
				i++
			}
			'-o', '-output' {
				res.output = cmdline.option(current_args, arg, '')
				if os.file_ext(res.output) != '' {
					util.err('-output solo recibe un nombre de archivo sin extensión: "$res.output"')
				}
				i++
			}
			'-g', '-game' {
				target_game := cmdline.option(current_args, arg, '')
				match target_game {
					'rs', 'rubysapphire' {
						res.game = .ruby_sapphire
						res.defines[res.defines.index('__FIRERED_LEAFGREEN__')] = '__RUBY_SAPPHIRE__'
					}
					'frlf', 'fireredleafgreen' {
						res.game = .firered_leafgreen
					}
					'e', 'emerald' {
						res.game = .emerald
						res.defines[res.defines.index('__FIRERED_LEAFGREEN__')] = '__EMERALD__'
					}
					else {
						util.err('la opción $arg solo soporta los valores: rs, rubysapphire, frlf, fireredleafgreen, e, emerald')
					}
				}
				i++
			}
			'-r', '-rom' {
				target_rom := cmdline.option(current_args, arg, '')
				if !target_rom.ends_with('.gba') {
					util.err('$arg espera una ROM de GBA')
				}
				res.rom = target_rom
				res.build_mode = .direct
				i++
			}
			'-fast' {
				res.optlevel = .fast
				res.defines[res.defines.index('__DEBUG__')] = '__FAST__'
			}
			'-debug' {
				res.optlevel = .debug
			}
			'-skip-warnings' {
				res.skip_warnings = true
			}
			'-warns-are-errors' {
				res.warns_are_errors = true
			}
			'-verbose' {
				res.is_verbose = true
			}
			'-nocolor' {
				res.use_color = .never
			}
			'-color' {
				res.use_color = .always
			}
			'-only-check-syntax' {
				res.only_check_syntax = true
			}
			'-library' {
				res.is_library = true
			}
			'-version' {
				if args.len > 1 {
					util.err('la opción -version se debe usar sin opciones ni archivo .zs')
				}
				println('ZubatScript $about.complete_version')
				exit(1)
			}
			else {
				if arg.ends_with('.zs') {
					if res.file == '' {
						res.file = arg
						res.file_dir = os.dir(arg)
					} else {
						util.err('solo se puede soportar un archivo de script .zs, no varios')
					}
				} else {
					util.err("no se reconoce la opción $arg, por favor use '$app ayuda' para ver las opciones disponibles")
				}
			}
		}
	}
	if res.output != '' && res.build_mode == .direct {
		util.err('no se puede insertar un script en una ROM, y a la vez crear un archivo .rbh')
	}
	// TODO: Remover esto cuando el backend de decomp esté completo.
	if res.backend == .decomp {
		util.err('aún no está soportado el backend de decompilación')
	}
	return res
}

pub fn zsexe_path() string {
	zsexe := os.getenv('ZSEXE')
	if zsexe != '' {
		return zsexe
	}
	real_zsexe_path := os.real_path(os.executable())
	os.setenv('ZSEXE', real_zsexe_path, true)
	return real_zsexe_path
}
