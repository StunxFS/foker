// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module main

import os
import time
import about
import compiler.prefs
import compiler.ast
import compiler.parser

fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ['-h', 'help', 'ayuda']) {
		help()
		exit(1)
	}
	prefs := prefs.parse_args_and_get_prefs()
	_ := parser.parse_files(prefs.files, &ast.Table{}, prefs, &ast.Scope{
		parent: 0
	})
	// println(parsed_file)
}

fn help() {
	program := os.args[0]
	current_time := time.now().str()
	println("=================================================
FokerScript | Mensaje de Ayuda | Work In Progress
=================================================
Autor: StunxFS
Fecha de compilación: $current_time
Versión: $about.version

Uso:
    $program [opciones] [argumentos]

Información básica sobre los backends:
    Versión del backend de binario: $about.gen_bin_version
    Versión del backend de decomp: Aún no disponible [TODO].

Descripción:
    Bienvenido al compilador oficial del proyecto FokerScript. Este compilador, actualmente,
    convierte el código que se le pasa a un único archivo auto-contenido de script de XSE,
    el cual está listo para ser compilado con XSE e insertado en la ROM.
    Este compilador aún está bajo desarrollo, es decir, que todavía es un trabajo en progreso.

Argumentos:
    archivos
        Este argumento no se declara, sino que recibe los archivos que serán compilados, estos
        archivos deben tener la extensión .fkr
        Ejemplo de uso:
            $program miarchivo.foker otroarchivo.fkr

Opciones:
    -h, help, ayuda
        Muestra este mensaje de ayuda

    -b, -backend
        Esta opción se usa para especificarle a FokerScript que backend debe usar para generar
        el archivo único de script XSE, por defecto se usa el valor 'binary'.
        Este acepta los siguientes valores:
            binary
            decomp
        Ejemplo de uso:
            $program -b decomp miarchivo.foker
            $program -b binary miarchivo.foker

    -o, -output
        Esta opción le especifica al compilador cómo debería llamarse el archivo de salida
        Ejemplo de uso:
            $program -o micarpeta/miarchivo.rbh miarchivo.fkr
    
    -r, -rom
        Esta opción le dice al compilador el nombre de la ROM que se usará para insertar el
        script. OJO: Esta opción no se puede usar junto a -o, -output
        Ejemplo de uso:
            $program -r mirom.gba miscript.fkr

    -g, -game
        Esta opción le especifica al compilador que ROM se usará para el script, por defecto
        se usa el valor 'frlf'.
        Actualmente -g soporta los siguientes valores:
            rs, rubysapphire: Pokémon Ruby/Sapphire
            frlf, fireredleafgreen: Pokémon FireRed/LeafGreen
            e, emerald: Pokémon Emerald
        Ejemplo de uso:
            $program -g fr miarchivo.fkr

    -fast, -debug
        Estas opciones le dicen al compilador que nivel de optimización debe usar para generar
        el script, esto permite realizar un script que pueda ser feo y lento (-debug), o uno rápido
        y limpio (-fast). Por defecto el valor es -debug
        Ejemplo de uso:
            $program -fast miarchivo.fkr
            $program -debug miarchivo.fkr
    
    -warn-are-errors
        Esta opción le dice al compilador que trate las advertencias como errores.
        Ejemplo de uso:
            $program -warn-are-errors

    -skip-warnings
        Esta opción hace que el compilador no muestre advertencias.
        Ejemplo de uso:
            $program -skip-warnings

Ejemplo de uso del programa:
    $program -o mi_script_perron.inc -g rs -b decomp mi_script.fkr
    $program -fast -skip-warnings -g rs mi_script.fkr
    $program -debug -warn-are-errors -g rs mi_script.fkr")
}

fn to_hex(val int) string {
	/*
	byte_max  := int(HexOutput.byte)
	word_max  := int(HexOutput.word)
	dword_max := int(HexOutput.dword)
	*/
	return '0x$val.hex().str().to_upper()'
}

/*
TODO: Retirar esto de aquí
enum HexOutput {
	byte  = 255
	word  = 510
	dword = 1020
}

mut script := bin.new_fscript("main")
script.add_string("StunxFS", "Me llamo StunxFS")
	
mut block := bin.new_fblock("main")
	block.add_cmd("msgbox", ["@StunxFS", "0x2"])
	block.add_cmd("msgbox", ["@"+script.add_tmp_string("String temporal"), "0x2"])
	block.end()
script.add_block(block)
	
block = bin.new_fblock("main_2")
	block.add_cmd("msgbox", ["@StunxFS", "0x2"])
	block.add_cmd("msgbox", ["@"+script.add_tmp_string("String temporal"), "0x2"])
	block.end()
script.add_block(block)
	
os.write_file("${script.name}.rbh", script.generate_script())?

println(to_hex(100, .byte))
gen.make_new_fvf_file()?
fvf := gen.new_fvf("fvf.txt")?
println(fvf)
https://www.tmohentai.com/reader/5fdab3d2b2bb9/paginated/92?
*/
