# Guía breve de uso y pruebas de SAPE

## Acceso

- **Enlace de prueba:** completar aquí la URL HTTPS obtenida después de publicar en Vercel o Netlify.
- **Requisito de cuenta:** una cuenta registrada en SAPE y asociada a una organización.
- **Datos ficticios:** ejecutar `supabase/schema.sql`, las migraciones pendientes y `supabase/seed.sql` en el SQL Editor de Supabase. El seed incluye 21 alumnos ficticios distribuidos entre Río Claro y Los Aromos. Los registros están marcados como datos de prueba.
- **Usuarios de demostración:** crear las cuentas desde la pantalla de acceso y vincularlas a las organizaciones ficticias siguiendo las instrucciones comentadas al final de `supabase/seed.sql`. No guardar contraseñas en este repositorio.

### Cuentas preparadas para la demostración

Todas usan la contraseña `Sape2026`:

| Email | Rol | Organización |
|---|---|---|
| `rioclaro@test.com` | Administrador de escuela | Escuela Técnica Río Claro |
| `tutor.rioclaro@test.com` | Tutor de escuela | Escuela Técnica Río Claro |
| `pixel@test.com` | Administrador de empresa | Pixel Andino S.R.L. |
| `tutor.pixel@test.com` | Tutor de empresa | Pixel Andino S.R.L. |
| `coopnorte@test.com` | Administrador de empresa | Cooperativa Norte Ltda. |
| `delta@test.com` | Administrador de empresa | Grupo Delta S.A. |

## Roles y tareas

| Rol | Puede hacer |
|---|---|
| Administrador de escuela (`escuela_admin`) | Administrar alumnos, inscripciones y datos de la escuela; responder postulaciones de empresas; sumar miembros. |
| Tutor de escuela (`escuela_tutor`) | Consultar los registros de su escuela y crear, modificar o eliminar sus propios seguimientos. |
| Administrador de empresa (`empresa_admin`) | Administrar datos de la empresa; postularse a escuelas; gestionar requisitos; responder inscripciones; sumar miembros. |
| Tutor de empresa (`empresa_tutor`) | Consultar registros de sus convenios y crear, modificar o eliminar sus propios seguimientos. |

Las operaciones están sujetas a las políticas de la base de datos. La matriz completa y los límites por registro están en [06-modulo-alumnos-y-permisos.md](./06-modulo-alumnos-y-permisos.md).

## Recorrido principal: inscribir un alumno

1. Ingresar con una cuenta `escuela_admin`.
2. Abrir **Alumnos** y elegir **Nuevo alumno**.
3. Completar apellido, nombre y DNI; guardar.
4. Abrir el detalle del alumno y elegir un convenio activo.
5. Completar los requisitos obligatorios y guardar.
6. Elegir **Enviar a la empresa**. La aplicación no debe permitir el envío si faltan requisitos.
7. Ingresar como administrador de la empresa del convenio y consultar o responder la inscripción.
8. Volver a consultar el detalle para comprobar el estado actualizado.

Para más detalle sobre pantallas, validaciones y mensajes, consultar [05-funcion-principal.md](./05-funcion-principal.md).

## Casos de prueba manuales

Ejecutar los casos con cuentas de demostración distintas. Registrar el resultado real y el mensaje observado; no marcar un caso como aprobado hasta ejecutarlo.

| ID | Pasos | Resultado esperado |
|---|---|---|
| P01 Registro e inicio de sesión | Registrar una cuenta con email y contraseña válidos; confirmar el correo si Supabase lo requiere; iniciar sesión. | La cuenta queda autenticada y llega al registro de organización o al panel, según corresponda. |
| P02 Registro de organización | Con una cuenta sin organización, abrir **Registrar organización**; completar los datos válidos de una escuela o empresa y guardar. | Se crea la organización y la cuenta recibe el rol administrador correspondiente. |
| P03 Cierre de sesión | Usar **Cerrar sesión** y luego intentar volver a `/dashboard` con la navegación del navegador y escribiendo la ruta directamente. | Se cierra la sesión; las rutas privadas redirigen al login. |
| P04 Ruta restringida por tipo | Iniciar sesión como empresa y abrir directamente `/alumnos`; repetir como escuela para una ruta exclusiva de escuela, si aplica. | El router redirige a una ruta permitida; la base de datos sigue siendo la autoridad de permisos. |
| P05 Permisos de tutor | Iniciar como tutor de escuela y luego como tutor de empresa; intentar crear/modificar alumnos, cambiar estados y gestionar miembros. | Las operaciones no autorizadas se bloquean; cada tutor puede operar únicamente sobre sus propios seguimientos. |
| P06 Aislamiento entre organizaciones | Iniciar como administrador de una escuela; buscar, abrir, modificar y eliminar un alumno perteneciente a otra escuela. Repetir con otra empresa y sus convenios. | Los registros ajenos no aparecen; consultas y escrituras sobre ellos no tienen efecto o son rechazadas por RLS. |
| P07 Recorrido de inscripción | Completar el recorrido principal de esta guía con una escuela y empresa de prueba. | La escuela crea y envía la inscripción; la empresa solo la ve después del envío y puede responder según las reglas del flujo. |
| P08 Datos inválidos | En los formularios probar campos obligatorios vacíos, email inválido, DNI no numérico o repetido, curso fuera de rango y fechas inválidas. En registro/cambio de contraseña probar menos o más de 8 caracteres, símbolos y una contraseña válida de 8 letras/números. | Se impide guardar datos inválidos. Las contraseñas nuevas aceptan exactamente 8 caracteres alfanuméricos y el botón del ojo alterna entre mostrar y ocultar. La base rechaza también la escritura inválida cuando aplica. |
| P09 Búsqueda sin resultados | En los listados ingresar un texto que no coincida con ningún registro. | Se muestra el estado vacío; no se muestran registros de otra organización. |
| P10 Sesión en otra pestaña | Iniciar sesión en dos pestañas; cerrar sesión en una y operar desde la otra. | La pestaña restante deja de permitir el acceso y vuelve al login con un aviso. |
| P11 Diseño adaptable | Revisar login, listados y formularios en una ventana de escritorio y en un viewport móvil; probar menú, botones, campos y tablas. | El contenido sigue siendo legible y operable; no hay controles inaccesibles ni desbordamiento que impida completar las tareas. |
| P12 Configuración antes de compartir | Revisar los archivos versionados y la configuración del hosting; comprobar que `.env` no se publica y que solo se usan datos ficticios. | No hay claves secretas, contraseñas ni datos personales reales. Las claves del frontend son únicamente publicables. |
| P13 Publicación y rutas | Abrir el enlace publicado desde otro dispositivo; recargar directamente `/login`, `/dashboard` y una ruta de detalle con sesión válida. | La app carga por HTTPS y las rutas de Vue funcionan al abrirse directamente o recargarse. |

## Registro de ejecución e incidencias

Completar esta tabla durante la prueba. Si un caso falla, anotar el paso, el resultado real y la corrección aplicada antes de volver a probarlo.

| Fecha | Caso | Resultado (aprobado / fallido / pendiente) | Mensaje o problema | Corrección y re-prueba |
|---|---|---|---|---|
| 2026-11-18 | P04 (sin sesión) | Aprobado para esta condición | Abrir directamente `/alumnos` redirige a `/login?redirect=/alumnos`. | La comprobación de accesos con cada rol requiere cuentas de Supabase y queda pendiente. |
| 2026-11-18 | P08 (contraseñas distintas) | Aprobado para esta validación | El registro muestra “Las contraseñas no coinciden.” | Otros formatos inválidos y respuestas del backend quedan pendientes. |
| 2026-11-18 | P11 (login) | Pendiente de completar | En el login, 390 px y 1366 px no produjeron desbordamiento horizontal. | Revisar también listados, formularios y acciones con sesión. |

## Pruebas de base de datos existentes

Ejecutar desde el SQL Editor de Supabase, sobre un proyecto de prueba:

1. `supabase/tests/roles_alumnos.sql`: permisos por rol y organización.
2. `supabase/tests/pruebas_rls.sql`: aislamiento y reglas de negocio.
3. `supabase/tests/funcion_principal.sql`: altas, validaciones y recorrido principal.
4. `supabase/tests/flujo_completo.sql`: recorrido de gestión de extremo a extremo.

Consultar cada archivo antes de ejecutarlo: algunos modifican datos de prueba; `roles_alumnos.sql` y `funcion_principal.sql` terminan con `ROLLBACK`.
