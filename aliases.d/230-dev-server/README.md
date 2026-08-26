# 230-dev-server

Helpers para iniciar servidores de desarrollo desde Bash.

## Funciones

### `backend_iniciar <puerto> [comando]`
Inicia el backend en `0.0.0.0:<puerto>` usando por defecto:

```bash
npm run dev
```

### `frontend_iniciar <puerto> [comando]`
Inicia el frontend en `0.0.0.0:<puerto>` usando por defecto:

```bash
npm run dev
```

## Variables opcionales

- `DEV_SERVER_CMD`: comando por defecto si no se pasa uno como segundo argumento.
- `DEV_SERVER_HOST`: host de escucha. Por defecto es `0.0.0.0`.

## Comportamiento actual

- Si no se pasa comando, ejecuta `npm run dev`.
- Si luego quieres otro stack, puedes pasar un comando distinto como segundo argumento.
