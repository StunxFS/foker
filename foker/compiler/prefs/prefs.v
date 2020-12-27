// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module prefs

import os
import os.cmdline
import compiler.util

pub enum Game {
	firered_leafgreen
	ruby_sapphire
	emerald
}

pub enum Backend {
	decomp
	binary
}

pub enum Optlevel {
	fast
	debug
}

pub enum UseColor {
	always
	never
}

pub struct Preferences {
pub mut:
	// ROM en el que se usará el script generado. Esto es usado para
	// generar código exacto sin problemas.
	game			Game     = .firered_leafgreen
	backend 		Backend  = .binary
	rom				string // la rom en la que se insertará el script
	// Por defecto se coge este archivo, ya que se crea automaticamente
	// con todas las variables y banderas disponibles. Si en ella hay
	// una variable o flag ocupada, simplemente abrir el archivo y borrarla.
	flags_vars_file	string   = "fvf.txt"
	output			string   // nombre de salida del script
	optlevel		Optlevel = .debug
	skip_warnings	bool	// saltarse las advertencias
	warns_are_errors bool	// tratar las advertencias como errores
	file			string  // archivo a compilar
	is_verbose		bool    // el compilador debe detallar cada cosa que hace
	use_color		UseColor
}

pub fn parse_args_and_get_prefs() &Preferences {
	app := os.args[0]
	args := os.args[1..]
	mut res := &Preferences{}
	mut has_file := false
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
					}
					else {
						util.err("la opción ${arg} solo soporta los valores 'binary' o 'decomp'")
					}
				}
				i++
			}
			'-o', '-output' {
				res.output = cmdline.option(current_args, arg, '')
				i++
			}
			'-g', '-game' {
				target_game := cmdline.option(current_args, arg, '')
				match target_game {
					'rs', 'rubysapphire' {
						res.game = .ruby_sapphire
					}
					'frlf', 'fireredleafgreen' {
						res.game = .firered_leafgreen
					}
					'e', 'emerald' {
						res.game = .emerald
					}
					else {
						util.err('la opción ${arg} solo soporta los valores: rs, rubysapphire, frlf, fireredleafgreen, e, emerald')
					}
				}
				i++
			}
			'-r', '-rom' {
				target_rom := cmdline.option(current_args, arg, '')
				if !target_rom.ends_with('.gba') {
					util.err('${arg} espera una ROM de GBA')
				}
				res.rom = target_rom
				i++
			}
			'-fast' {
				res.optlevel = .fast
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
			'-no-use-color' {
				res.use_color = .never
			}
			'-use-color' {
				res.use_color = .always
			}
			else {
				if arg.ends_with(".fkr") {
					if !has_file {
						res.file = arg
					} else {
						util.err("solo se puede soportar un archivo de script .fkr, no varios")
					}
				} else {
					util.err("no se reconoce la opción ${arg}, por favor use '${app} ayuda' para ver las opciones disponibles")
				}
			}
		}
	}
	if res.output != "" && res.rom != "" {
		util.err('no puedes insertar un script en una ROM, y, a la vez, crear un archivo .rbh')
	}
	// TODO: Remover esto cuando el backend de decomp esté completo.
	if res.backend == .decomp {
        util.err('aún no está soportado el backend de decompilación')
    }
	return res
}
