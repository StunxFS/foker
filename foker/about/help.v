// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module about

import os

pub fn help() {
	program := os.args[0]
	println("=================================================
FokerScript | Mensaje de Ayuda | Work In Progress
=================================================
Autor: StunxFS
Fecha de compilación: $about.build_time
Versión: $about.version

Uso:
    $program [opciones] archivo-fkr

Información básica sobre los backends:
    Versión del backend de binario: $about.gen_bin_version
    Versión del backend de decomp: Aún no disponible [TODO].

Descripción:
    Bienvenido al compilador oficial del proyecto FokerScript. Este compilador, actualmente,
    convierte el código que se le pasa a un único archivo auto-contenido de script de XSE,
    el cual está listo para ser compilado con XSE e insertado en la ROM.
    Este compilador aún está bajo desarrollo, es decir, que todavía es un trabajo en progreso.

Argumentos:
    archivo-fkr
        Este argumento no se declara, sino que recibe el archivo de script .fkr que será
        compilado.
        Ejemplo de uso:
            $program miarchivo.fkr

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
    
    -no-use-color
        Esta opción hace que el compilador nunca use colores en los mensajes de error, advertencia, etc
        Ejemplo de uso:
            $program -no-use-color main_282.fkr

    -use-color
        Esta opción hace que el compilador siempre use los colores en los mensajes de error, advertencia, etc
        Ejemplo de uso:
            $program -use-color main_13.fkr

Ejemplo de uso del programa:
    $program -o mi_script_perron.inc -g rs -b decomp mi_script.fkr
    $program -fast -skip-warnings -g rs mi_script.fkr
    $program -debug -warn-are-errors -g rs mi_script.fkr")
}
