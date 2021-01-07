# Documentación de ZubatScript

## Introducción

ZubatScript es un lenguaje de scripting, de tipado fuerte, creado para la fácil creación de scripts en los fangames basados en el ROMHacking binario de Pokémon (juegos de la GBA, 3ra generación).

Debido a que ZubatScript es muy sencillo, el tiempo de aprendizaje del lenguaje no debería superar la media hora. En esa cantidad de tiempo ya deberías ser un experto en el desarrollo de scripts.

ZubatScript promueve el fácil y rápido desarrollo de scripts con una sintaxis ordenada y fácil de entender, sin tener que sufrir con la sintaxis del Rubikhon (RBH).

## Tabla de contenido

<table>
<tr><td width=33% valign=top>
    
* [Hola Mundo](#hola-mundo)

</td></tr>
</table>

## ¡Hola Mundo!

```cs
script main {
	msgbox("¡Hola Mundo!");
}
```

Guardamos este pedazo de código dentro de un archivo llamado `main.zubat`, y estando en la terminal/consola escribimos: ``zubat main.zubat``, nos debería salir un salida idéntica a esta:

> Esto asumiendo que ya tiene a zubat con un symlinking, de lo contrario, ejecute: `./zubat-symlink`

```
stunxfs@stunxfs-pc:~$ zubat main.zubat
> Compilando main.zubat, con archivo de salida "main.rbh"
> Se ha compilado exitósamente el archivo main.zubat
```
