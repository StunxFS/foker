# El lenguaje de scripting FokerScript
Bienvenidos al repositorio oficial del lenguaje de scripting para los juegos de la 3ra generación de Pokémon en GBA. Yeah, este lenguaje funciona solo con el binario, si se desea usar un lenguaje parecido o familiar para los proyectos de decompilación, puede recurrir a [Poryscript](https://github.com/huderlem/poryscript), que es desarrollado por el usuario [**huderlem**](https://github.com/huderlem).

## ¿Qué es esto?
**FokerScript** es un nuevo intento de facilitar el desarrollo de scripts en el ROMHacking binario del Pokémon Advance de 3ra Gen. Este lenguaje está inspirado en gran parte por su contraparte para el decomp, **Poryscript**. Este lenguaje transpila el código dado por el usuario al scripting del **XSE (desarrollado por HackMew)**.

A lo largo de estos años, todos los ROMHackers, que han llegado recientemente a este mundillo, han tenido que lidiarse con el scripting del XSE. Debido a su dificultad de escritura, el scripting de XSE ***semi-facilita*** las cosas, por eso, este proyecto intenta quitar ese **semi** de ahí y dejar solo el **facilita**.

## Objetivos
FokerScript tiene como objetivos los siguientes puntos:
* **Fácil aprendizaje y escritura** - aprender en menos de 1 hora el lenguaje, escribir en menos de 5 minutos un buen script.
* **Sencillez** - no sobrecargar el lenguaje con sintaxis innecesaria.
* **Modularización** - permitir que el usuario pueda reutilizar scripts en otros proyectos sin problemas.

También tiene otro objetivo que está en estado tentativo:
* Transpilar su código a los 2 modos: en binario y en decompilación.

Con este objetivo tentativo deseamos que cualquier script hecho con FokerScript pueda funcionar tanto en el binario como en decompilación, con tan solo algunos ajustes.

## Backends
Actualmente este es el estado de implementación de los backends en FokerScript:
| Juego             | Binario | Decompilación |
| :---              | :---:   | :---:         |
| Ruby/Sapphire     |         |               |
| FireRed/LeafGreen |         |               |
| Emerald           |         |               |

Los juegos aquí mencionados son soportados tanto en inglés y español.

## Más sobre el objetivo tentativo: Generación al scripting de decompilación
Como ya se ha dicho, esto está en estado tentativo, es decir, puede que se haga o puede que no, es cuestión de analizar cuántas modificaciones son necesarias para generar código compatible con decompilación. Si estas modificaciones no llegan a un punto en el que el backend de binario se vea afectado, puede que se cumpla totalmente, de lo contrario, lamentablemente, tendremos que eliminar este objetivo.

## Ejemplos de FokerScript
```cs
script main {
    msg("¡Hola mundo!");
    checkgender {
        boy {
            msg("¡Eres un maestro pokémon!");
        }
        girl {
            msg("¡Eres una estrella pokémon!");
        }
    }
}
```
```cs
const MIRUTINA_ESPECIAL = 0x80AB24DF;

script main {
    callasm(MIRUTINA_ESPECIAL);
    var mirutina_especial_var_usada: long at 0x8013; // Esta sintaxis se usa para declarar variables que, por ejemplo, una rutina utiliza.
    if mirutina_especial_var_usada == 100 or mirutina_especial_var_usada > 200 {
        msg("¡La rutina ha funcionado correctamente!");
    }
    free mirutina_especial_var_usada; // liberamos la variable utilizada.
}
```
Si quiere más ejemplos, vaya a la carpeta [ejemplos](/ejemplos/).

## Documentación y especificaciones del lenguaje
En [docs.pdf](docs.pdf) se encuentra toda la información, puede descargarlo en su dispositivo o verlo directamente en el navegador.

## Licencia MIT
Copyright 2020 Stunx.

Por la presente se concede permiso, libre de cargos, a cualquier persona que obtenga una copia de este software y de los archivos de documentación asociados (el "Software"), a utilizar el Software sin restricción, incluyendo sin limitación los derechos a usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar, y/o vender copias del Software, y a permitir a las personas a las que se les proporcione el Software a hacer lo mismo, sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso se incluirán en todas las copias o partes sustanciales del Software.

EL SOFTWARE SE PROPORCIONA "COMO ESTÁ", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O IMPLÍCITA, INCLUYENDO PERO NO LIMITADO A GARANTÍAS DE COMERCIALIZACIÓN, IDONEIDAD PARA UN PROPÓSITO PARTICULAR E INCUMPLIMIENTO. EN NINGÚN CASO LOS AUTORES O PROPIETARIOS DE LOS DERECHOS DE AUTOR SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN, DAÑOS U OTRAS RESPONSABILIDADES, YA SEA EN UNA ACCIÓN DE CONTRATO, AGRAVIO O CUALQUIER OTRO MOTIVO, DERIVADAS DE, FUERA DE O EN CONEXIÓN CON EL SOFTWARE O SU USO U OTRO TIPO DE ACCIONES EN EL SOFTWARE.
