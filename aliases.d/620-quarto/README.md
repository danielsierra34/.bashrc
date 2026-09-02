# Quarto

Funciones para instalar y usar Quarto desde Debian/WSL.

Quarto convierte Markdown, notebooks y proyectos tecnicos en HTML, PDF,
Word, presentaciones, libros y sitios web. La instalacion es global; el
renderizado y la previsualizacion se ejecutan sobre el proyecto actual.

## Funciones

- `quarto_help`: muestra la ayuda del modulo.
- `quarto_check`: verifica Quarto y sus dependencias.
- `quarto_install`: instala Quarto globalmente con el paquete `.deb` oficial.
- `quarto_update`: descarga e instala la version mas reciente.
- `quarto_uninstall`: desinstala Quarto del sistema.
- `quarto_render [ruta|.] [argumentos]`: renderiza un documento o proyecto.
- `quarto_preview [ruta|.] [puerto]`: renderiza y sirve una vista local con recarga.
- `quarto_run [ruta|.] [puerto]`: atajo para `quarto_preview`.

## Uso

```bash
source ~/bashrc/aliases
quarto_install
quarto_check

cd ~/ruta/de/mi-proyecto
quarto_run . 4444
```

Para generar una salida final:

```bash
quarto_render .
quarto_render informe.qmd --to html
```

En Debian/WSL requiere `sudo` y `curl`. El instalador obtiene la version
estable mas reciente desde los releases oficiales de Quarto.

Variable opcional:

- `QUARTO_DEB_URL`: permite fijar una URL concreta del paquete `.deb`.
