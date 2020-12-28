// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module about

import os

pub const (
	version 			= "0.1.0a0"
	emitter_bin_version = "alpha0"
	build_time			= '<unknown>'
)

pub fn help() {
	program := os.args[0]
	println("=================================================
FokerScript | Mensaje de Ayuda | Work In Progress
=================================================
Autor: StunxFS
Fecha de compilación: $build_time
Versión: $version

Descripción:
    Bienvenido al compilador oficial del proyecto FokerScript.
    Este compilador aún está bajo desarrollo, es decir, que todavía es un trabajo en progreso.

Uso:
    $program [opciones] archivo.fkr

Información básica sobre los backends:
    Versión del backend de binario: $emitter_bin_version
    Versión del backend de decomp: Aún no disponible [WIP].

Argumentos:
    archivo-fkr
        Este argumento no se declara, sino que recibe el archivo de script .fkr que será
        compilado.
        Ejemplo de uso:
            $program miarchivo.fkr

Opciones:
    -h, -a, help, ayuda
        Muestra este mensaje de ayuda.

    -b, -backend
        Esta opción se usa para especificarle a FokerScript que backend debe usar para generar
        el archivo único de script XSE, por defecto se usa el valor 'binary'.
        Este acepta los siguientes valores:
            binary
            decomp
        Ejemplo de uso:
            $program -b decomp miarchivo.foker
            $program -b binary miarchivo.foker

    -d, -define
        Esta opción define el nombre de la bandera que se le pase, esto es muy útil para manejar
        código que se compila condicionalmente. (ej: #if DEFINED_2020)
        Ejemplo de uso:
            $program -d DEFINED_2020 main_def_test.fkr

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
    
    -warns-are-errors
        Esta opción le dice al compilador que trate las advertencias como errores.
        Ejemplo de uso:
            $program -warns-are-errors main_12.fkr

    -skip-warnings
        Esta opción hace que el compilador no muestre advertencias.
        Ejemplo de uso:
            $program -skip-warnings main_14.fkr
    
    -verbose
        Esta opción hace que el compilador detalle cada paso que hace
        Ejemplo de uso:
            $program -verbose main_98.fkr
    
    -nocolor
        Esta opción hace que el compilador nunca use colores en los mensajes de error, advertencia, etc
        Ejemplo de uso:
            $program -nocolor main_282.fkr

    -color
        Esta opción hace que el compilador siempre use los colores en los mensajes de error, advertencia, etc
        Ejemplo de uso:
            $program -color main_13.fkr

    -only-check-syntax
        Esta opción solo parsea el archivo dad, evitando el chequeo y la generación del programa, esta opción
        puede ser útil para aprender la sintaxis de FokerScript.
        Ejemplo de uso:
            $program -only-check-syntax main_26.fkr

Ejemplos de usos del programa:
    $program -o mi_script_perron.inc -g rs -b decomp mi_script.fkr
    $program -fast -skip-warnings -g rs mi_script.fkr
    $program -debug -warns-are-errors -g rs mi_script.fkr")
}
