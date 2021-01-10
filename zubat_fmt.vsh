// Script para formatear cada archivo de código del compilador
// Usar con: v run zubat_fmt.vsh

const no_fmt = ['']

cmd_f := walk_ext('cmd/', '.v')
cmd_c := walk_ext('compiler/', '.v')

for cf in cmd_f {
	println('>>> Formateando $cf desde "cmd/"')
	system('v fmt -w $cf')
}

for cf in cmd_c {
	println('>>> Formateando $cf desde "compiler/"')
	system('v fmt -w $cf')
}

