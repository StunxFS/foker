// ZubatTest | ValenLoveForever
include "stdlib.rbh";

const OTHER = 2;
const AGE = OTHER * 200;
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
}
