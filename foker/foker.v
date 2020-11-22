// Copyright (c) 2020 Stunx. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import os
import compiler.about
import compiler.prefs
import compiler.scanner

fn main() {
	if os.args.len == 1 || (os.args.len == 2 && os.args[1] in ["-h", "help", "ayuda"]) {
		help()
		exit(1)
	}
	pref := prefs.parse_args_and_get_prefs()
	mut scan := scanner.new_scanner_file("foker/foker_test.foker", .skip_comments, pref)
	for tok := scan.scan(); tok.kind != .eof; tok = scan.scan() {
		println(tok)
	}
	println(scan.errors)
	println(scan.warnings)
}

fn help() {
	program := os.args[0]
	println("FokerScript v${about.version} | Mensaje de Ayuda

Uso:
    ${program} [opciones] [argumentos]

Descripción:
    Bienvenido al compilador oficial del proyecto FokerScript. Este compilador, actualmente,
    convierte el código que se le pasa a un único archivo auto-contenido de script de XSE,
    el cual está listo para ser compilado con XSE e insertado en la ROM.

Argumentos:
    archivos
        Este argumento no se declara, sino que recibe archivos que serán compilados a un único
        archivo de script de XSE.
        Ejemplo de uso:
            ${program} miarchivo.foker otroarchivo.foker

Opciones:
    -h, help, ayuda
        Muestra este mensaje de ayuda

    -b, -backend
        Esta opción se usa para especificarle a FokerScript que backend debe usar para generar
        el archivo único de script XSE, por defecto se usa 'binary' como valor.
        Este acepta los siguientes valores:
            binary
            decomp
        Ejemplo de uso:
            ${program} -b decomp miarchivo.foker
            ${program} -b binary miarchivo.foker

    -o, -output
        Esta opción le especifica al compilador cómo debería llamarse el archivo de salida
        Ejemplo de uso:
            ${program} -o micarpeta/miarchivo.rbh miarchivo.foker

    -r, -rom
        Esta opción le especifica al compilador que ROM se usará para el script, por defecto
        se usa 'frlf' como el valor default.
        Actualmente -g soporta los siguientes valores:
            rs, rubysapphire: Pokémon Ruby/Sapphire
            frlf, fireredleafgreen: Pokémon FireRed/LeafGreen
            e, emerald: Pokémon Emerald
        Ejemplo de uso:
            ${program} -g fr miarchivo.foker

    -fast, -debug
        Estas opciones le dicen al compilador que nivel de optimización debe usar para generar
        el script, esto permite realizar un script que pueda ser feo y lento (-debug), o uno rápido
        y limpio (-fast). Por defecto el valor es -debug
        Ejemplo de uso:
            ${program} -fast miarchivo.foker
            ${program} -debug miarchivo.foker

Ejemplo de uso de las opciones anteriores:
    ${program} -o mi_script_perron.inc -r rs -b decomp mi_script_para_el_concurso.foker
")
}

/*enum HexOutput {
	byte  = 255
	word  = 510
	dword = 1020
}

fn to_hex(val int, output HexOutput) string {
	/*byte_max  := int(HexOutput.byte)
	word_max  := int(HexOutput.word)
	dword_max := int(HexOutput.dword)*/
	return "0x${val.hex().str().to_upper()}"
}*/


//println(token.Token{.name, 'foker_name', 2, 122, 10})
	
	/*mut script := bin.new_fscript("main")
	script.add_string("stunx", "Me llamo stunx")
	
	mut block := bin.new_fblock("main")
		block.add_cmd("msgbox", ["@stunx", "0x2"])
		block.add_cmd("msgbox", ["@"+script.add_tmp_string("String temporal"), "0x2"])
		block.end()
	script.add_block(block)
	
	block = bin.new_fblock("main_2")
		block.add_cmd("msgbox", ["@stunx", "0x2"])
		block.add_cmd("msgbox", ["@"+script.add_tmp_string("String temporal"), "0x2"])
		block.end()
	script.add_block(block)*/
	
	//os.write_file("${script.name}.rbh", script.generate_script())?

	//println(to_hex(100, .byte))
	//gen.make_new_fvf_file()?
	//fvf := gen.new_fvf("fvf.txt")?
	//println(fvf)