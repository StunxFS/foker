# Contribuciones (Contributing)

Este documento trata sobre las contribuciones para el proyecto.

## ¿Qué se debe hacer?

Bien, antes que todo leer el [código de conducta](CODE_OF_CONDUCT.md), luego de haberlo leído se tiene que hacer lo siguiente:

1) Disponer con una cuenta en Github, sí o sí.
2) Tener instalado en la computadora Github Desktop.

Bien, aqui tienes unas sencillas reglas para cada cosa en la que quieras contribuir:

## Regla general para los Pull Requests

Al hacer un pull request intenta seguir la siguiente esquema:

``all: se ha arreglado siete errores extraños``

Bien, el esquema es el siguiente: ``nombre_de_lo_modificado``: ``titulo``

En el primer apartado debes mencionar que has modificado, si has hecho cambios en la parte general debes usar ``all``, si has modificado parte del compilador o el generador puedes usar: ``foker.gen``, ``foker.compiler``, ``compiler`` o ``gen``, si se trata de la documentación usa: ``docs``.

En el segundo apartado intenta hacer una descripción de lo que has arreglado, cambiado o añadido, por ejemplo:

```ruby
all: se ha cambiado el soporte de XXX a XServer.com
gen: se ha añadido soporte para X11
docs: se ha añadido más explicaciones sobre la parte de los condicionales
```

## Compilador/Generation

Si vas a añadir alguna función, struct, o vas a arreglar algún error o bug, procura siempre seguir los estándares del código fuente, es decir, seguirlo tal como está escrito.

Cuando tengas tus cambios procura en una terminal ejecutar ``v tests foker/tests`` para chequear que el compilador está trabajando bien.

Procura añadir archivos de testeo en la carpeta [foker/tests](foker/tests) con cada cambio, añadido, o arreglo que hagas.

## Documentación

Si lo que vas a contribuir es pura documentación, debes hacer lo siguiente:

* Primero que nada, modifica el archivo [docs.md](docs/docs.md) con lo que piensas añadir en el área que mejor le convenga (por favor, intente ser ordenado con esto).
* Luego, procede a abrir una terminal ubicada en la carpeta ``docs`` y escribe ``make gen-doc``, para que el docs.md se genere en formato HTML y actualice el [docs.html](docs/docs.html).

Bien luego que cumplas con todo esto, haz un pull-request para hacer un merge con tus añadidos.
