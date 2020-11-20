// Copyright (c) 2020 Stunx (Jose Mendoza). All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module prefs

pub enum ROM {
	fire_red_en // FireRed version English
	// Add more backends roms here
}

pub struct Preferences {
pub:
	// ROM en el que se usará el script generado. Esto es usado para
	// generar código exacto sin problemas.
	target	ROM
	// Por defecto se coge este archivo, ya que se crea automaticamente
	// con todas las variables y banderas disponibles. Si en ella hay
	// una variable o flag ocupada, simplemente abrir el archivo y borrarla.
	flags_vars_file	string = "flags_vars.txt"
	output	string // nombre de salida del script .rbh
	output_dir string // nombre del directorio de salida.
	
}
