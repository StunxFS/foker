// ZubatTest | ValenLoveForever
/*import Z3; // compiler/tests/Z3.zs
//import impfolder::Z3 as Z3_2;

text Kakawate = "Dd";

const ANIO_ACTUAL = 2020;
const AGE = ANIO_ACTUAL - 1971;
const AGE2 = AGE * 2;
const AGGE = ATK_NONE + Z3::CCC;*/

//const DESPUES = ANTES;
//const ANTES = 2;

const OFFSET: offset = 0x800000;

/*pub movement my_movement {
	walk_down_vslow
}*/

//script my_script {}

//alias Z3_mycommand = Z3::mycommand;

//cmd applymovement(mov: movement);
//alias move = applymovement;

script con_script {
	msgbox("a y b no son iguales", 6);
}

script main {
	var a = 100;
	if a == 100 {
		msgbox("a y b son iguales! 100", 6);
	} else {
		call con_script;
		if a > 100 {
			msgbox("a > 100", 6);
		} elif a == 1000 {
			msgbox("b == 1000", 6);
		}
	}
	msgbox("Holaaa!", 6);
	question "¿Quieres leche?" {
		yes {
			msgbox("Toma un poco", 6);
		}
		no {
			msgbox("Cualquier cosa me dices", 6);
		}
	}
}
