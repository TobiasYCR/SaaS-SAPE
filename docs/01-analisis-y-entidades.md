# 01 · Análisis y entidades

## Función principal

SAPE intermedia entre **escuelas** y **empresas** para gestionar pasantías escolares.

1. Escuelas y empresas se registran y se ven entre sí en un directorio.
2. La empresa elige una escuela y se postula → **convenio** `postulado`.
3. La escuela acepta o rechaza → `aceptado` / `rechazado`.
4. Con el convenio aceptado se configuran los **requisitos** (datos que se piden para inscribir alumnos).
5. Configuración cerrada → convenio `activo`.
6. La escuela inscribe **alumnos**, completa los requisitos y envía la inscripción.
7. La empresa acepta o rechaza cada inscripción (respetando los cupos).
8. Durante la pasantía se registran **seguimientos**.

## Entidades

| Tabla | Representa | Datos que guarda |
|---|---|---|
| `escuelas` | Institución educativa cliente | nombre, CUE, modalidad, especialidades, ubicación, contacto, logo, activa |
| `empresas` | Organización cliente que recibe pasantes | razón social, nombre de fantasía, CUIT, rubro, ubicación, contacto, logo, activa |
| `perfiles` | Usuario de la plataforma (1:1 con `auth.users`) | nombre, email, teléfono, rol, escuela **o** empresa a la que pertenece |
| `alumnos` | Estudiante de una escuela (sin cuenta) | datos personales, DNI, curso, división, especialidad, responsable |
| `convenios` | Vínculo empresa ↔ escuela por ciclo lectivo | área, descripción, cupos, fechas, estado |
| `requisitos` | Dato exigido para inscribir alumnos en un convenio | nombre, tipo (`texto`, `numero`, `fecha`, `archivo`, `si_no`), obligatorio, orden |
| `inscripciones` | Alumno inscripto en un convenio (la pasantía) | estado, fechas, horas, tutores, observaciones |
| `datos_inscripcion` | Valor cargado para cada requisito de una inscripción | valor o ruta de archivo |
| `seguimientos` | Control periódico de una pasantía en curso | fecha, progreso %, observaciones, próxima fecha |

`requisitos` + `datos_inscripcion` permiten que cada convenio defina sus propios campos sin modificar la estructura de la base.

## Representación de cada cliente (multi-organización)

- Cada cliente es una fila en `escuelas` o en `empresas`.
- Cada usuario pertenece a una sola organización: `perfiles.escuela_id` **o** `perfiles.empresa_id` (CHECK `perfil_una_organizacion`).
- Datos propios de la escuela: `alumnos.escuela_id`.
- Datos compartidos: `convenios` lleva `empresa_id` y `escuela_id`; requisitos, inscripciones, datos y seguimientos cuelgan del convenio.
- FKs compuestas impiden mezclar organizaciones:
  - `inscripciones (alumno_id, escuela_id) → alumnos (id, escuela_id)`
  - `inscripciones (convenio_id, escuela_id) → convenios (id, escuela_id)`
  - `datos_inscripcion (requisito_id, convenio_id) → requisitos (id, convenio_id)`
- Row Level Security filtra cada consulta según la organización del usuario logueado (`mi_escuela()`, `mi_empresa()`).

| Dato | Escuela | Empresa |
|---|---|---|
| Directorio de escuelas y empresas | Ve todo | Ve todo |
| Convenios | Los suyos | Los suyos |
| Alumnos | Los suyos | Solo los inscriptos en sus convenios |
| Requisitos, inscripciones, datos, seguimientos | Los de sus convenios | Los de sus convenios |

## Usuarios y roles

Credenciales, contraseñas y sesiones: **Supabase Auth** (`auth.users`). No existe tabla de contraseñas.
Al registrarse, el trigger `al_crear_usuario` crea la fila en `perfiles` sin rol ni organización.

| Rol | Organización | Permisos |
|---|---|---|
| `escuela_admin` | Escuela | Editar la escuela, ABM de alumnos, aceptar/rechazar convenios, configurar requisitos, inscribir y enviar alumnos, sumar miembros |
| `escuela_tutor` | Escuela | Consultar y cargar seguimientos |
| `empresa_admin` | Empresa | Editar la empresa, postularse a escuelas, configurar requisitos, aceptar/rechazar inscripciones, sumar miembros |
| `empresa_tutor` | Empresa | Consultar y cargar seguimientos |

Alta de organización: RPC `registrar_organizacion(tipo, datos)` → crea la escuela/empresa y deja al usuario como admin.
Alta de miembros: RPC `asignar_miembro(email, rol)` → el admin suma a un usuario ya registrado.

## Transiciones de estado (validadas por triggers)

**Convenio**

| De | A | Quién |
|---|---|---|
| `postulado` | `aceptado` / `rechazado` | escuela_admin |
| `postulado` | `cancelado` | empresa_admin |
| `aceptado` | `activo` | cualquier admin de las partes |
| `aceptado` / `activo` | `finalizado` / `cancelado` | cualquier admin de las partes |

**Inscripción**

| De | A | Quién | Condición |
|---|---|---|---|
| `borrador` | `enviada` | escuela_admin | Requisitos obligatorios completos |
| `enviada` | `aceptada` / `rechazada` | empresa_admin | Aceptar requiere cupo libre |
| `aceptada` | `en_curso` | cualquier admin | |
| `en_curso` | `finalizada` | cualquier admin | |
| `borrador` / `enviada` / `aceptada` | `cancelada` | escuela_admin | |
