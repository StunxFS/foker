// ZubatTest | ValenForever
include "stdlib.rbh";

const AGE = 10 * 20;
text MSG = "Tu edad es de $(AGE)";

movement Mov1 {
	walk_up * 2
	walk_down * 4
}

// Probando preprocesador :)
script main {
	var d1 = 200;
	if (d1 == 100 and d1 < 10) {}
}

