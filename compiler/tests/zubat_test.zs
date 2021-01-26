// ZubatTest | ValenLoveForever
//import "Z2.zs";
//import "impfolder/Z4.zs";

const KAKA = 200;

const ANIO_ACTUAL = 2020;
const AGE = ANIO_ACTUAL - 1971;
const AGE2 = AGE * 2;
const BOOLEAN = true;

movement my_movement {
	walk_down_vslow
}

script my_script {}

script main {
	msgbox("Hola mundo!");
	msgbox(2020, arg);
	call my_script;
	//var myvar: bool = 4;
	//myvar = 2020;
	{
		var myvar: bool = false;
		myvar = true;
	}
}
