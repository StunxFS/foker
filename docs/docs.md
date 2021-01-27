# Documentación de ZubatScript

## Introducción

ZubatScript es un lenguaje de scripting, de tipado fuerte, creado para la fácil creación de scripts en los fangames basados en el ROMHacking binario de Pokémon (juegos de la GBA, 3ra generación).

Debido a que ZubatScript es muy sencillo, el tiempo de aprendizaje del lenguaje no debería superar la media hora. En esa cantidad de tiempo ya deberías ser un experto en el desarrollo de scripts.

ZubatScript promueve el fácil y rápido desarrollo de scripts con una sintaxis ordenada y fácil de entender, sin tener que sufrir con la sintaxis de XSE.

## Tabla de contenido

<table>
<tr><td width=33% valign=top>
    
* [Hola Mundo](#hola-mundo)
* [Comentarios](#comentarios)
* [Expresiones](#expresiones)
* [Archivos e importes](#archivos-e-importes)
* [Módulos](#módulos)

</td></tr>
</table>

## ¡Hola Mundo!

```cs
script main {
	msgbox("¡Hola Mundo!");
}
```

Guardamos este pedazo de código dentro de un archivo llamado `main.zs`, y estando en la terminal/consola escribimos: ``zubat main.zs``, nos debería salir un salida idéntica a esta:

> Esto asumiendo que ya tienes a Zubat en el PATH, de lo contrario, ejecute make.vsh:
> `sudo v run make.vsh symlink` si está en linux
> si está en Windows, abra un cmd.exe como administrador y ejecute:
> `v run make.vsh symlink`

```
stunxfs@stunxfs-pc:~$ zubat main.zs
> Compilando "main.zs", con archivo de salida "main.rbh"
> Se ha compilado exitósamente el archivo main.zubat
stunxfs@stunxfs-pc:~$
```

Con el archivo generado procede a usar XSE para insertar el script generado en su ROM.

> Por ahora ZubatScript no puede insertar scripts en la ROM, pero en un futuro tendrá esta utilidad.

Si el script ha corrido bien, entonces ¡FELICIDADES! has creado tu primer script.

Si te has dado cuenta, y si has programado antes scripts, verás que es casi idéntico a como se hacía antes, aquí la misma versión del script anterior, solo que escrita siguiendo la sintáxis de XSE:

```llvm
#dynanmic 0x800000

#org @main__main
msgbox @str1 0x6
end

#org @str1
= ¡Hola Mundo!
```

En este caso, se omite el `#dynamic`, ya que este se inserta automáticamente, y el `#org` se cambia por `script`, también en vez de terminar un bloque con `end`, se encierra dentro de `{` y `}`.

## Comentarios

```v
// Este es un simple comentario de una línea.
/*
Este es un comentario de multiples líneas.
   /* Este es otro comentario multilínea dentro de otro.*/
*/
```

Todos los comentarios que el compilador se encuentra son ignorados.

## Expresiones

Para comenzar el aprendizaje de ZubatScript hay que pasar primero por las expresiones, si pasamos por esta parte lo demás ya será fácil de aprender.

Una expresión es esta parte: `1 + 2 * AGE / 10` de aquí: `var new_age = 1 + 2 * AGE / 10;`. En las expresiones podemos hacer operaciones matemáticas básicas (sumar, restar, multiplicar y dividir), entre otras cosas que serán enumeradas a continuación.

Las expresiones devuelven un tipo, este tipo se obtiene calculando cada una de las partes de la expresión, por ejemplo, `2 + 2` devolverá un tipo `int` (entero, numérico), `2 + SUMANDO` devolverá `int` si la constante `SUMANDO` es de tipo `int`.

Si queremos darle importancia a una parte de la expresión, podemos encerrar esa parte entre paréntesis así: `2 + 2 * (666 / 222)`

### ¿Qué podemos hacer en las expresiones?

Podemos hacer lo siguiente:

**1) Sumar, restar, multiplicar y dividir literales numéricos, constantes y variables**

Yep, podemos hacer operaciones básicas en las expresiones. Por ejemplo: `2 + 4` suma 2 literales numéricos, `myvar + MYCONST` suma una variable y una constante. `myvar * 2 * (MYCONST * 2)` multiplica una variable por 2 y el resultado de este lo multiplica por el resultado de multiplicar una constante por 2.

La única regla aquí es que los literales, las variables y constantes a usar deben ser del algún tipo numérico, no se pueden hacer estas operaciones básicas con los literales de cadena (string, ""), los booleanos (bool, true/false) y mucho menos con los movimientos; si intentamos esto, obtendremos un error similar a este:

```c
myscript.zs:1:22: error: estas operaciones no están permitidas con bool/flags
    1 | const BOOLEAN = true + false;
      |                      ^
    2 | text STRING = "Kaka" + "wate";
    3 |
myscript.zs:2:22: error: estas operaciones no están permitidas con strings
    1 | const BOOLEAN = true + true;
    2 | text STRING = "Kaka" + "wate";
      |                      ^
    3 |
    4 | script main {
```

**2) Crear movimientos**

Si por algún motivo tienes una serie de movimientos que no requieren un nombre en especifico, ya que será de uso temporal, puedes crear una variable de tipo `movement` que sea local, así:

```go
script main {
	var mymov = movement {
		walk_up * 2
	};
	applymovement(mymov, PLAYER_ID);
}
```

Si no se quiere usar una variable, se puede crear un `movement` inline así:

```rust
script main {
	applymovement(movement {
		walk_up * 2
	}, PLAYER_ID);
}
```

Las constantes no pueden recibir este tipo de expresión, para estos fines es mejor usar la declaración `movement`:

```go
movement MyMovement {
	walk_up * 2
}

script main {
	applymovement(MyMovement, PLAYER_ID);
}
```

Esto es todo lo que se puede hacer con las expresiones por ahora; hay más tipos de expresiones, pero estas no han sido implementadas aún.

## Archivos e importes

Comencemos pues, ya luego de haber visto todo sobre las expresiones, a aprender sobre el cómo ve ZubatScript a un archivo .zs. Para ZubatScript cada archivo que se importe y/o use es un módulo. Si tengo un archivo que se llama `question.zs`, el módulo importado se llamará `question`.

Esto nos abre caminos a una declaración muy importante en ZubatScript: `import`, la cual se usa para importar archivos. Veamos un ejemplo:

```v
import std::maths;
import myfile;
import stuffs::stuffs;
import myfolder::myfile as myfile2;

script main {
  var square_of_2004 = math::square!(2004);
  call myfile::my_script;
  callasm(stuffs::MY_ROUTINE_OFFSET);
  call myfile2::super_duper_foquerisgay;
}
```

Wow, demasiadas cosas nuevas, bueno, calma, poco a poco sabrás entenderlas todas. Como vemos, hacemos uso de 4 archivos de código .zs, usando las 3 formas de importes que tiene ZubatScript, vamos a verlas una por una:

**1) Importes de archivos de la librería estandard**

Además de proveer todo un sistema de compilación para facilitar el desarrollo de scripts, Zubat también provee una librería estandard que está llena de utilidades, mayormente estas son macros. Entonces, para importar un archivo de la librería estandard se debe usar la forma: `import std::<ruta::al::archivo>`, en donde `<ruta::al::archivo>` se reemplazará por la ruta al archivo que queramos importar; si no sabemos que archivo importar, podemos echarle un vistazo a la carpeta `stdlib`.

En este caso, se importa desde la carpeta `stdlib`, el archivo `maths.zs`, que contiene macros útiles para funciones matemáticas avanzadas que no se pueden hacer fácilmente en Zubat por medio de las expresiones.

**2) Un archivo local**

Un archivo local puede ser otro archivo .zs que esté en la misma carpeta que el archivo que se está compilando, o en varias subcarpetas. Una cuestión a tener en cuenta es que no se pueden usar rutas relativas (`../ruta/relativa`), ni se permiten importes circulares (por ejemplo, `file1.zs` importa a `file2.zs`, y, a la vez, `file2.zs` importa a `file1.zs`).

Además, otra cosa a tener en cuenta es que, para importar un archivo .zs, se debe comenzar desde la carpeta base del archivo .zs que se le pasó al compilador. Ejemplo: tenemos esta estructura de directorio, dentro de la carpeta de un proyecto, para nuestro script:

```bash
scripts/
    pallet_town.zs
    StunxFS/
        random.zs
    Rub3n/
        goals.zs
```

Entonces, en `pallet_town.zs` importamos a `StunxFS/random.zs`, y en `StunxFS/random.zs` queremos hacer uso de `Rub3n/goals.zs`, pero... ¿cómo hacerlo? podriamos usar una ruta relativa así: `import ..::Rub3n::goals;`, pero no está permitido esta forma, entonces, podemos usar una ruta absoluta, partiendo desde la carpeta scripts, así: `import Rub3n::goals;`. Para que esto funcione, siempre se debe ejecutar a Zubat dede la carpeta raíz así: `zubat script/pallet_town.zs`, o en la misma carpeta `scripts`: `zubat pallet_town.zs`. De todas formas, el compilador nos avisará si estamos importando algo inexistente o que.

**3) Importar un archivo con un alias**

Puede pasar que existan 2 archivos con el mismo nombre (`stuffs.zs` y `FR/stuffs.zs`, por ejemplo), entonces, si importamos ambos:

```v
import stuffs;
import FR::stuffs;
```

Tendremos problemas, ¿por qué? pues el nombre del módulo del primer archivo será `stuff`, al momento de importar el módulo del segundo archivo, obtendremos un error de duplicación de módulos, entonces ¿cómo hacemos para usar los 2 sin problemas? pues haciendo uso de un alias:

```v
import stuffs;
import FR::stuffs as fr_stuffs;
```

En este caso, se importa el módulo del segundo archivo sin problemas debido al alias que tiene (`fr_stuffs`). Y para hacer uso del contenido de este módulo, usamos el alias: `fr_stuffs::mymacro!();`.

## Módulos

Vale, ahora vamos con el tema de los módulos. Un módulo es como una caja que contiene varios elementos que pueden ser públicos o privados.

Para Zubat, como ya se ha dicho, cada archivo .zs representa un módulo, y el nombre de este, es, exactamente, el mismo nombre del archivo. Dentro de un módulo todo es privado por defecto, para hacer un elemento público se debe hacer uso de la palabra clave `pub` antes de una de las declaraciones `const` y `var` (en su forma global), `script` (en su forma normal y externa), en `movement` (en su forma global), en `text` y en `macro`.

Si se hace uso de un elemento que es privado en un módulo, el compilador lanzará un error sobre esto.

Para poder hacer uso del contenido de un módulo usamos la sintaxis `<module>::<object>`, en donde `<module>` será el nombre del módulo (o alias, si se importó con uno), y `<object>` será un elemento público del módulo, ejemplo: `call mymod::myscript;` hará una llamada al script `myscript` contenido en el módulo `mymod` (este es un alias, el nombre real es `mymodule`), obviamente, esta sintaxis es para los módulos importados.
Si estamos en un módulo y queremos hacer uso de un script que hemos hecho, pues simplemente usamos el nombre del script y ya. 

Ejemplo de un módulo sería este:

```rust
import std::maths;
import std::buffers;

script square_250000 {
    var square = maths::square!(250000);
    buffers::prepare_fmt!(square);
    buffers::go_msg!();
    buffers::free_fmt!();
}

script main {
    question "¿Quieres saber cuánto es el doble de 205000?" {
        yes {
            call square_250000;
        }
        no {
            msg!("Datos que son muy interesantes. ¡Fuera de aquí, pedazo de caca!");
        }
    }
}
```

<!-- TODO: Seguir con el desarrollo de la documentación -->

* * *

(C) 2020-2021 **StunxFS**. Todos los derechos reservados.
