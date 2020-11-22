// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module prefs

import os
import term
import os.cmdline

const (
	err_header = term.red(term.bold("FokerScript CLI Error:"))
)

pub enum ROM {
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

pub struct Preferences {
pub mut:
	// ROM en el que se usará el script generado. Esto es usado para
	// generar código exacto sin problemas.
	rom			    ROM      = .firered_leafgreen
	backend 		Backend  = .binary
	// Por defecto se coge este archivo, ya que se crea automaticamente
	// con todas las variables y banderas disponibles. Si en ella hay
	// una variable o flag ocupada, simplemente abrir el archivo y borrarla.
	flags_vars_file	string   = "fvf.txt"
	output			string   // nombre de salida del script
	output_dir 		string   // nombre del directorio de salida
	optlevel		Optlevel = .debug
	files			[]string // los archivos a compilar
}

pub fn parse_args_and_get_prefs() &Preferences {
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
					}
					else {
						err('la opción ${arg} solo soporta los valores: binary o decomp')
					}
				}
				i++
			}
			'-o', '-output' {
				res.output = cmdline.option(current_args, arg, '')
				res.output_dir = res.output.split(os.path_separator)[..1].join(os.path_separator)
				i++
			}
			'-r', '-rom' {
				target_rom := cmdline.option(current_args, arg, '')
				match target_rom {
					'rs', 'rubysapphire' {
						res.rom = .ruby_sapphire
					}
					'frlf', 'fireredleafgreen' {
						res.rom = .firered_leafgreen
					}
					'e', 'emerald' {
						res.rom = .emerald
					}
					else {
						err('la opción ${arg} solo soporta los valores: rs, rubysapphire, frlf, fireredleafgreen, e, emerald')
					}
				}
				i++
			}
			'-fast' {
				res.optlevel = .fast
			}
			'-debug' {
				res.optlevel = .debug
			}
			else {
				if arg.ends_with(".foker") || arg.ends_with(".fkr") {
					res.files << arg
				} else {
					err("no se reconoce el comando ${arg}")
				}
			}
		}
	}
	return res
}

fn err(msg string) {
	eprintln("${err_header} ${msg}")
	exit(1)
}
