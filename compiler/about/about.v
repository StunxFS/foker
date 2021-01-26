// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module about

import os
import term

pub const (
	version             = '0.1.0'
	status              = 'alpha'
	complete_version    = '$version $status'
	build_time          = '<unknown>'
	emitter_bin_version = '0.0.0 [NO-STARTED]'
)

pub fn help() {
	program := os.args[0]
	info := term.header('Autor: StunxFS | Fecha de compilación: $about.build_time | Versión: $about.complete_version',
		' ')
	println(term.header('Mensaje de Ayuda | ZubatScript | Work In Progress', ' ') +
		"
$info

Descripción:
    Bienvenido al compilador oficial del proyecto ZubatScript.
    Este compilador aún está bajo desarrollo, es decir, que todavía es un trabajo en progreso.

Uso:
    $program [opciones] archivo.zs

Información básica sobre los backends:
    Versión del backend de binario: ${about.emitter_bin_version}. [WIP]
    Versión del backend de decomp: Aún no disponible [WIP].

Argumentos:
    archivo-zs
        Este argumento no se declara, sino que recibe el archivo de script .zs que será
        compilado.
        Ejemplo de uso:
            $program miarchivo.zs

Opciones:
    -h, -a, help, ayuda
        Muestra este mensaje de ayuda.

    -version
        Muestra la versión y estado del compilador.

    -b, -backend
        Esta opción se usa para especificarle a ZubatScript que backend debe usar para generar
        el archivo único de script XSE, por defecto se usa el valor 'binary'.
        Este acepta los siguientes valores:
            binary
            decomp
        Ejemplo de uso:
            $program -b decomp miarchivo.zs
            $program -b binary miarchivo.zs

    -d, -define
        Esta opción define el nombre de la bandera que se le pase, esto es muy útil para manejar
        código que se compila condicionalmente. (ej: #if DEFINED_2020)
        Ejemplo de uso:
            $program -d DEFINED_2020 main_def_test.zs
            
    -u, -undefine
        Esta opción indefine el nombre de la bandera que se le pase, esto es muy útil para manejar
        código que se compila condicionalmente. (ej: #if !DEFINED_2020)
        Ejemplo de uso:
            $program -u DEFINED_2020 main_def_test.zs

    -o, -output
        Esta opción le especifica al compilador cómo debería llamarse el archivo de salida
        Ejemplo de uso:
            $program -o micarpeta/miarchivo.rbh miarchivo.zs

    -r, -rom
        Esta opción le dice al compilador el nombre de la ROM que se usará para insertar el
        script. OJO: Esta opción no se puede usar junto a -o, -output
        Ejemplo de uso:
            $program -r mirom.gba miscript.zs

    -g, -game
        Esta opción le especifica al compilador que ROM se usará para el script, por defecto
        se usa el valor 'frlf'.
        Actualmente -g soporta los siguientes valores:
            rs, rubysapphire: Pokémon Ruby/Sapphire
            frlf, fireredleafgreen: Pokémon FireRed/LeafGreen
            e, emerald: Pokémon Emerald
        Ejemplo de uso:
            $program -g fr miarchivo.zs

    -library
        Esta opción le dice al compilador que el archivo a compilar es una librería, y no debe pedir
        un script 'main' para su correcta compilación.
        Ejemplo de uso:
            $program -library mis_utilidades.zs

    -fast, -debug
        Estas opciones le dicen al compilador que nivel de optimización debe usar para generar
        el script, esto permite realizar un script que pueda ser feo y lento (-debug), o uno rápido
        y limpio (-fast). Por defecto el valor es -debug
        Ejemplo de uso:
            $program -fast miarchivo.zs
            $program -debug miarchivo.zs

    -warns-are-errors
        Esta opción le dice al compilador que trate las advertencias como errores.
        Ejemplo de uso:
            $program -warns-are-errors main_12.zs

    -skip-warnings
        Esta opción hace que el compilador no muestre advertencias.
        Ejemplo de uso:
            $program -skip-warnings main_14.zs

    -verbose
        Esta opción hace que el compilador detalle cada paso que hace
        Ejemplo de uso:
            $program -verbose main_98.zs

    -nocolor
        Esta opción hace que el compilador nunca use colores en los mensajes de error, advertencia, etc
        Ejemplo de uso:
            $program -nocolor main_282.zs

    -color
        Esta opción hace que el compilador siempre use los colores en los mensajes de error, advertencia, etc
        Ejemplo de uso:
            $program -color main_13.zs

    -only-check-syntax
        Esta opción solo parsea el archivo dad, evitando el chequeo y la generación del programa, esta opción
        puede ser útil para aprender la sintaxis de ZubatScript.
        Ejemplo de uso:
            $program -only-check-syntax main_26.zs

Ejemplos de usos del programa:
    $program -o mi_script_perron.inc -g rs -b decomp mi_script.zs
    $program -fast -skip-warnings -g rs mi_script.zs
    $program -debug -warns-are-errors -g rs mi_script.zs")
}
