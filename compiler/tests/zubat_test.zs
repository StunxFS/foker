// ZubatTest | ValenLoveForever

dynamic 900000;

import Z3; // compiler/tests/Z3.zs
//import impfolder::Z3 as Z3_2;

text Kakawate = "Dd";

const ANIO_ACTUAL = 2020;
const AGE = ANIO_ACTUAL - 1971;
const AGE2 = AGE * 2;
const AGGE = ATK_NONE + Z3::CCC;

//const DESPUES = ANTES;
//const ANTES = 2;

const OFFSET: offset = 0x800000;

pub movement my_movement {
	walk_down_vslow
}

script my_script {}

alias Z3_mycommand = Z3::mycommand;

cmd applymovement(mov: movement);
alias move = applymovement;

script main {
	msgbox("Hola mundo!", 6);
	msgbox("2020", Z3::CCC);
	msg("Stunx", 6);
	msg(Kakawate, 6);
	msg(Z3::Kampo, 6);
	call my_script;
	//call Z3::other_script;
	PKMNMENU = true;
	//var Zurkillo = 200;
	var myvar: int = 4;
	//msg("Stunx", myvar);
	myvar = 2020;
	free myvar;
	myvar = 555;
	Z3::OTHERVAR += 1;
	Z3::mycommand();
	Z3_mycommand();
	raw `compare [MYVAR] OTHERVAR`;

	applymovement(my_movement);
	applymovement(movement {
		walk_up * 4
	});
	var anon_mov = movement {
		walk_up * 4
	};
	applymovement(anon_mov);
	//applymovement(true);
	
	move(my_movement);
	move(movement {
		walk_up * 4
	});
	var anon_mov1 = movement {
		walk_up * 4
	};
	move(anon_mov1);
	//move(true);
	
	// Macro - errores!
	//Z3::macro!();
	//macro!();
	
	if 2 == 0xABC {
		call my_script;
		{
			/*var myvar = movement {
				walk_up * 2
			};
			var other = ANIO_ACTUAL;
			var milk: int = true;*/
		}
	}
}
