# 05 · Función principal: inscribir un alumno en una pasantía

Actor: administrador de escuela (`escuela_admin`).
Precondición: la escuela tiene al menos un convenio `activo` (la empresa se postuló, la escuela aceptó y se configuraron los requisitos).

## Recorrido

| # | Paso | Pantalla / ruta | Operación | Validaciones y mensajes |
|---|---|---|---|---|
| 1 | Ingresa con email y contraseña | `/login` | Supabase Auth | Credenciales incorrectas: "Email o contraseña incorrectos." |
| 2 | Abre Alumnos y toca **+ Nuevo alumno** | `/alumnos` | `listarAlumnos` | — |
| 3 | Completa y guarda el formulario | `/alumnos` | `crearAlumno` → INSERT `alumnos` con `escuela_id` de su escuela | Apellido, nombre y DNI obligatorios; DNI 7-8 dígitos; curso 1-7; email válido; DNI repetido. Éxito: "Ana Prueba se agregó a la escuela." + enlace al paso siguiente |
| 4 | Abre el detalle del alumno | `/alumnos/:id` | `obtenerAlumno`, `listarConvenios({estado:'activo'})`, `listarInscripciones({alumnoId})` | Sin convenios activos: aviso con enlace a Convenios |
| 5 | Elige un convenio activo y toca **Inscribir y completar datos** | `/alumnos/:id` | `inscribirAlumno` → INSERT `inscripciones` (estado `borrador`) | Convenio obligatorio; alumno ya inscripto; convenio no activo |
| 6 | Completa los requisitos y toca **Guardar datos** | `/inscripciones/:id` | `guardarDato` (upsert `datos_inscripcion`), `subirDocumento` (Storage `documentos`) | Valor según tipo: número, fecha, sí/no, archivo PDF/JPG/PNG ≤ 10 MB. Éxito: "Datos guardados." |
| 7 | Toca **Enviar a la empresa** | `/inscripciones/:id` | `cambiarEstadoInscripcion('enviada')` | Botón deshabilitado mientras falten obligatorios ("Faltan N requisito(s)…"); confirmación previa |
| 8 | Consulta el resultado | `/inscripciones`, `/alumnos/:id` | `listarInscripciones` | Estado visible: Enviada → Aceptada / Rechazada (responde la empresa) |

## Vinculación de los datos

| Registro | Vínculo | Garantizado por |
|---|---|---|
| Alumno | `escuela_id` = escuela del usuario | Política RLS de INSERT en `alumnos` |
| Inscripción | `escuela_id` completado por trigger; FK compuesta con alumno y convenio de la misma escuela | `validar_inscripcion` + FKs compuestas |
| Datos de inscripción | `convenio_id` completado por trigger; FK compuesta con requisito del mismo convenio | `validar_dato_inscripcion` + FKs compuestas |
| Archivos | Ruta `{convenio}/{inscripcion}/archivo` | Políticas de Storage del bucket `documentos` |

Otra escuela no ve ni modifica estos registros. La empresa los ve recién cuando la inscripción se envía.

## Verificación

- `supabase/tests/funcion_principal.sql`: 30 casos, incluidos datos faltantes e inválidos. Corre en una transacción con `ROLLBACK`; no deja datos.
- Errores de conexión: la app muestra "Conectando con el servidor..." y luego "No hay conexión con el servidor" con **Reintentar**, sin perder la sesión ni redirigir.
