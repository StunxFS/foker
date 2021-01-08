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

</td></tr>
</table>

## ¡Hola Mundo!

```cs
script main {
	msgbox("¡Hola Mundo!");
}
```

Guardamos este pedazo de código dentro de un archivo llamado `main.zubat`, y estando en la terminal/consola escribimos: ``zubat main.zubat``, nos debería salir un salida idéntica a esta:

> Esto asumiendo que ya tiene a Zubat en su PATH, de lo contrario, ejecute make.vsh:
> `sudo v run make.vsh symlink` si está en linux
> de lo contrario, si está en Windows, abra un cmd.exe como administrador y ejecute:
> `v run make.vsh symlink`

```
stunxfs@stunxfs-pc:~$ zubat main.zubat
> Compilando main.zubat, con archivo de salida "main.rbh"
> Se ha compilado exitósamente el archivo main.zubat
stunxfs@stunxfs-pc:~$
```

Con el archivo generado proceda a usar XSE para insertar el script generado en su ROM.

> Por ahora ZubatScript no puede insertar scripts en la ROM, pero en un futuro tendrá esta utilidad.

Si el script ha corrido bien, entonces ¡FELICIDADES! has creado tu primer script.

Si te has dado cuenta, y si has programado antes scripts, verás que es casi idéntico a como se hacía antes, aquí la misma versión del script anterior, solo que escrita siguiendo la sintaxis de XSE:

```nim
#dynanmic 0x800000

#org @main
msgbox @msg 0x6
end

#org @msg
= ¡Hola Mundo!
```

En este caso, se omite el `#dynamic` y el `#org` se cambia por `script`, también en vez de terminar un bloque con `end`, se encierra el bloque dentro de `{` y `}`.

## Comentarios

```v
// Este es un simple comentario de una línea.
/*
Este es un comentario de multiples líneas.
   /* Este es otro comentario multilínea dentro de otro.*/
*/
```
