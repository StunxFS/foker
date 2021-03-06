# Limitaciones del lenguaje de scripting ZubatScript

El lenguaje de scripting ZubatScript, al estar basado en el bytecode del ROMHacking binario, tiene,
lamentablemente, algunas limitaciones que serán explicadas a continuación:

## Strings:

La primera limitación que existe es esta. Los strings, o cadenas de texto, están limitadas en ZubatScript, ¿por qué? pues en el bytecode del ROMHacking binario no se puede manipular los strings a conveniencia, ya que estos son tratados como constantes. No se pueden concatenar, interpolar ni cambiar, por ese motivo solo hay 2 maneras de crear strings en ZubatScript:

* constantes:
Usando el keyword 'text' se puede declarar strings en el ámbito global del módulo: `text FRASE = "Mi Frase";`.

* literales:
Esto es lo mismo que una constante, pero la diferencia está en que es declarada como temporal, es decir, que no se puede usar como variable, porque se declara literal. `myfunc("micadena");`

## Las variables solo pueden usar valores númericos y booleanos (flags):

La limitación anterior nos abre camino a esta otra, y es que, por el hecho de que los strings no se pueden usar en variables, las variables quedan limitadas a solo valores númericos (vars) y booleanos (flags)

Esto quiere decir que podemos hacer lo siguiente:
```go
var myflag: bool = true; // setflag [myflag] 0x1
var mybyte: byte = 0x23;
var myvar: int = 2004; // int = word
var myword: long = 2002; // long = dword
```
