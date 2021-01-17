// ZubatTest | ValenLoveForever
include "stdlib.rbh";

const AGE = 10 * 20;
text MSG = "Mensaje real";

movement Mov1 {
	walk_up * 2
	walk_down * 4
}

script main {
	var d1 = 200;
	msgbox("Hola mundo!");
	msgbox(2020, name: arg);
	call my_script;
	if myvar == 100 {
		call got_2;
	}
}
