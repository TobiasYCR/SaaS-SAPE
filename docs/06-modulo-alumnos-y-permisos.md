# 06 · Módulo Alumnos, roles y permisos

## Información que administra el usuario

La escuela administra a sus alumnos: datos personales (apellido, nombre, DNI, fecha de nacimiento), datos escolares (curso, división, especialidad), contacto (email, teléfono) y responsable (nombre y teléfono). Cada alumno tiene un estado (activo o dado de baja) y un historial de inscripciones.

## Revisión del módulo

| Requisito | Antes | Ahora |
|---|---|---|
| Crear | Listado | Listado |
| Consultar | Listado y detalle | Listado y detalle con historial |
| Modificar | Solo desde el listado | Listado y detalle (mismo componente `FormAlumno` y mismas reglas que el alta) |
| Eliminar / dar de baja | Solo desde el listado | Listado y detalle. Sin inscripciones: eliminación; con inscripciones: baja lógica |
| Buscar | Apellido, nombre, DNI | Igual |
| Filtrar | Curso, activos / dados de baja | Igual |
| Ordenar | Fijo por apellido | Apellido A-Z / Z-A, DNI, curso y división, últimos cargados (orden en la base) |
| Mensajes y confirmación | Sí | Sí, también en el detalle |
| Sesión cerrada en otra pestaña o vencida | La pantalla abierta seguía visible | Redirige al login con aviso |
| Usuario desactivado | Veía botones que la base rechazaba | Aviso "cuenta desactivada", sin pantallas |

## Tipos de usuario

| Rol | Organización | Tareas | Justificación |
|---|---|---|---|
| `escuela_admin` | Escuela | Alta, modificación, baja y eliminación de alumnos; inscripciones; aceptar convenios; sumar miembros | Responsable institucional de los datos de los alumnos |
| `escuela_tutor` | Escuela | Consultar alumnos e inscripciones; registrar seguimientos | Docente que acompaña la pasantía; no debe alterar el padrón |
| `empresa_admin` | Empresa | Ver alumnos con inscripción enviada; aceptar o rechazar inscripciones | Decide qué pasantes recibe; no administra datos de la escuela |
| `empresa_tutor` | Empresa | Ver alumnos de sus convenios; registrar seguimientos | Acompaña al pasante en la empresa |

Usuario registrado sin organización: solo puede registrar su escuela o empresa. Usuario desactivado (`perfiles.activo = false`): sin acceso a datos.

## Vínculo usuario → organización → rol

- `perfiles.id` = `auth.users.id` (1:1). Contraseñas en Supabase Auth.
- CHECK `perfil_una_organizacion`: rol de escuela ⇒ solo `escuela_id`; rol de empresa ⇒ solo `empresa_id`; sin rol ⇒ sin organización.
- El usuario no puede cambiar su rol ni su organización (permisos de columna en `perfiles`); solo `registrar_organizacion` y `asignar_miembro` los asignan.

## Dónde se controla cada permiso

| Capa | Control |
|---|---|
| Base de datos (RLS) | `alumnos`: SELECT por `mi_escuela()` o inscripción enviada en convenio de `mi_empresa()`; INSERT / UPDATE / DELETE solo `escuela_admin` de esa escuela. `mi_rol()` devuelve null si el perfil está desactivado. |
| Base de datos (restricciones) | CHECK de DNI, curso y email; UNIQUE (escuela, DNI); FK sin cascada desde inscripciones (no se borra un alumno con historial). |
| Router | `meta.tipo: 'escuela'` en `/alumnos` y `/alumnos/:id`; sin sesión → `/login`; sin organización → registro. |
| Interfaz | Botones según rol; aviso "rol de consulta" para tutores. Solo usabilidad: el permiso real es el de la base. |

## Matriz de permisos (verificada en Supabase)

`supabase/tests/roles_alumnos.sql`, 45 casos con ROLLBACK.

Resumen para los cuatro roles de SAPE. Los permisos se limitan a los registros de la organización y de los convenios en los que participa cada usuario.

| Acción | `escuela_admin` | `escuela_tutor` | `empresa_admin` | `empresa_tutor` |
|---|---|---|---|---|
| Consultar | Sí: registros de su escuela | Sí: registros de su escuela | Sí: registros de su empresa y alumnos con inscripción no borrador | Sí: registros de sus convenios y alumnos con inscripción no borrador |
| Crear | Sí: alumnos, inscripciones, requisitos y seguimientos | Sí: seguimientos | Sí: convenios, requisitos y seguimientos | Sí: seguimientos |
| Modificar | Sí: registros de su escuela y estados permitidos | Solo sus propios seguimientos | Sí: registros de su empresa/convenios y estados permitidos | Solo sus propios seguimientos |
| Eliminar / dar de baja | Sí, con límites: alumnos con historial se dan de baja; puede borrar inscripciones borrador | Solo sus propios seguimientos | Puede retirar postulaciones propias aún no respondidas y borrar requisitos del convenio | Solo sus propios seguimientos |
| Gestionar usuarios | Sí: sumar miembros registrados a su escuela | No | Sí: sumar miembros registrados a su empresa | No |

La baja de alumnos se implementa como `activo = false`; el borrado físico está limitado por las relaciones de historial. “Modificar” y “eliminar” también respetan las transiciones de estado y restricciones de cada registro. La gestión documentada permite sumar miembros; no ofrece una operación para eliminar miembros.

| Acción | Admin escuela | Tutor escuela | Admin otra escuela | Admin empresa | Tutor empresa | Sin organización | Desactivado | Sin sesión |
|---|---|---|---|---|---|---|---|---|
| Ver alumnos de la escuela | ✅ 4 | ✅ 4 | ❌ 0 | Solo con inscripción enviada (2) | Solo con inscripción enviada (2) | ❌ 0 | ❌ 0 | ❌ error |
| Buscar / ordenar | ✅ | ✅ | Solo los suyos | — | — | — | — | ❌ |
| Crear alumno | ✅ | ❌ RLS | ❌ RLS | ❌ RLS | — | ❌ RLS | ❌ RLS | ❌ error |
| Modificar | ✅ | ❌ 0 filas | ❌ 0 filas | ❌ 0 filas | ❌ 0 filas | — | — | — |
| Modificar con datos inválidos | ❌ CHECK / UNIQUE / NOT NULL | — | — | — | — | — | — | — |
| Mover a otra escuela | ❌ RLS | — | — | — | — | — | — | — |
| Dar de baja / reactivar | ✅ | ❌ 0 filas | — | — | — | — | — | — |
| Eliminar sin inscripciones | ✅ | ❌ 0 filas | ❌ 0 filas | ❌ 0 filas | — | — | — | — |
| Eliminar con inscripciones | ❌ FK | — | — | — | — | — | — | — |
| Cambiarse rol u organización | ❌ permiso | — | — | — | — | — | — | — |
| Sumar miembros | ✅ | ❌ función | — | — | — | — | — | — |

## Sesión

| Situación | Comportamiento |
|---|---|
| Cerrar sesión | Va al login; "atrás" y rutas directas a pantallas privadas vuelven al login |
| Cierre en otra pestaña | Supabase avisa a las demás pestañas; la pantalla abierta pasa al login |
| Token vencido sin renovar | La primera consulta rechazada cierra la sesión local y lleva al login con "Tu sesión se cerró" |
| Sin sesión | Toda ruta privada → `/login?redirect=…` |
