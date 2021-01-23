// ZubatTest | ValenLoveForever
//import "Z2.zs";

const ANIO_ACTUAL = 2020;
const AGE = ANIO_ACTUAL - 1971;
const AGE2 = AGE * 2;
const BOOLEAN = true;
text MSG = "Mensaje real";

movement Mov1 {
	walk_up * 2
	walk_down * 4
}

script my_script {}

script main {
	msgbox("Hola mundo!");
	msgbox(2020, arg);
	call my_script;
	if BOOLEAN {}
	//var myvar: bool = 4;
	//myvar = 2020;
}
