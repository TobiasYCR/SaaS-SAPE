# 03 · Diccionario de datos

Motor: PostgreSQL (Supabase). Esquema: `public`. Fuente: `supabase/schema.sql`.
Abreviaturas: **PK** clave primaria · **FK** clave foránea · **UK** único · **NN** not null.

## Tipos enumerados

| Tipo | Valores |
|---|---|
| `rol_usuario` | `escuela_admin`, `escuela_tutor`, `empresa_admin`, `empresa_tutor` |
| `estado_convenio` | `postulado`, `aceptado`, `rechazado`, `activo`, `finalizado`, `cancelado` |
| `tipo_requisito` | `texto`, `numero`, `fecha`, `archivo`, `si_no` |
| `estado_inscripcion` | `borrador`, `enviada`, `aceptada`, `rechazada`, `en_curso`, `finalizada`, `cancelada` |

## escuelas

Institución educativa que usa la plataforma.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK, default `gen_random_uuid()` | Identificador |
| nombre | text | NN, no vacío | Nombre de la escuela |
| cue | text | NN, UK, 9 dígitos | Clave Única de Establecimiento |
| modalidad | text | | Técnica, orientada, etc. |
| especialidades | text[] | NN, default `{}` | Especialidades u orientaciones que dicta |
| descripcion | text | | Presentación para el directorio |
| direccion | text | | Calle y número |
| localidad | text | NN | Localidad |
| provincia | text | NN | Provincia |
| email | text | formato email | Email de contacto |
| telefono | text | | Teléfono de contacto |
| logo_url | text | | URL pública del logo (bucket `logos`) |
| logo_ruta | text | | Ruta del logo en Storage |
| activa | boolean | NN, default `true` | Visible y operativa |
| datos_prueba | boolean | NN, default `false` | Registro ficticio de `seed.sql`; la app lo muestra con la etiqueta DATOS DE PRUEBA |
| creado_en | timestamptz | NN, default `now()` | Fecha de alta |
| actualizado_en | timestamptz | NN, trigger | Última modificación |

## empresas

Organización que recibe pasantes.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| razon_social | text | NN, no vacío | Razón social |
| nombre_fantasia | text | | Nombre comercial |
| cuit | text | NN, UK, 11 dígitos sin guiones | CUIT |
| rubro | text | | Actividad principal |
| descripcion | text | | Presentación para el directorio |
| direccion | text | | Calle y número |
| localidad | text | NN | Localidad |
| provincia | text | NN | Provincia |
| email | text | formato email | Email de contacto |
| telefono | text | | Teléfono de contacto |
| sitio_web | text | | URL del sitio |
| logo_url | text | | URL pública del logo |
| logo_ruta | text | | Ruta del logo en Storage |
| activa | boolean | NN, default `true` | Visible y operativa |
| datos_prueba | boolean | NN, default `false` | Registro ficticio de `seed.sql`; la app lo muestra con la etiqueta DATOS DE PRUEBA |
| creado_en | timestamptz | NN | Fecha de alta |
| actualizado_en | timestamptz | NN, trigger | Última modificación |

## perfiles

Datos del usuario de la aplicación. La contraseña la gestiona Supabase Auth en `auth.users`.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK, FK → `auth.users.id` (cascade) | Mismo id que el usuario de Auth |
| nombre_completo | text | | Tomado de `full_name` al registrarse |
| email | text | | Copia del email de Auth (para buscar miembros) |
| telefono | text | | Teléfono |
| rol | rol_usuario | null hasta registrar/unirse a una organización | Rol en la plataforma |
| escuela_id | uuid | FK → `escuelas.id` | Escuela a la que pertenece |
| empresa_id | uuid | FK → `empresas.id` | Empresa a la que pertenece |
| activo | boolean | NN, default `true` | Usuario habilitado |
| creado_en | timestamptz | NN | Fecha de alta |

CHECK `perfil_una_organizacion`: rol de escuela ⇒ solo `escuela_id`; rol de empresa ⇒ solo `empresa_id`; sin rol ⇒ ninguna.
El usuario solo puede modificar `nombre_completo` y `telefono`.

## alumnos

Estudiantes de una escuela. No tienen cuenta.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| escuela_id | uuid | NN, FK → `escuelas.id` (cascade) | Escuela del alumno |
| nombre | text | NN | Nombre |
| apellido | text | NN | Apellido |
| dni | text | NN, 7-8 dígitos, UK con `escuela_id` | DNI |
| fecha_nacimiento | date | | Fecha de nacimiento |
| curso | smallint | 1 a 7 | Año que cursa |
| division | text | | División |
| especialidad | text | | Especialidad u orientación |
| email | text | formato email | Email del alumno |
| telefono | text | | Teléfono del alumno |
| responsable_nombre | text | | Madre, padre o tutor legal |
| responsable_telefono | text | | Teléfono del responsable |
| activo | boolean | NN, default `true` | Alumno vigente |
| creado_en | timestamptz | NN | Fecha de alta |
| actualizado_en | timestamptz | NN, trigger | Última modificación |

UK adicional `(id, escuela_id)` para las FKs compuestas.

## convenios

Vínculo entre una empresa y una escuela para un ciclo lectivo. Lo inicia la empresa.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| empresa_id | uuid | NN, FK → `empresas.id` (cascade) | Empresa que se postula |
| escuela_id | uuid | NN, FK → `escuelas.id` (cascade) | Escuela elegida |
| ciclo_lectivo | smallint | NN, 2020-2100 | Año del convenio |
| area | text | | Área o puesto ofrecido |
| descripcion | text | | Propuesta de la empresa |
| cupos | smallint | NN, > 0 | Máximo de alumnos aceptados |
| fecha_inicio | date | | Inicio previsto |
| fecha_fin | date | ≥ fecha_inicio | Fin previsto |
| estado | estado_convenio | NN, default `postulado` | Etapa del convenio |
| respondido_en | timestamptz | trigger | Cuándo la escuela aceptó o rechazó |
| creado_por | uuid | FK → `perfiles.id` (set null), default `auth.uid()` | Usuario que lo creó |
| creado_en | timestamptz | NN | Fecha de postulación |
| actualizado_en | timestamptz | NN, trigger | Última modificación |

UK `(empresa_id, escuela_id, ciclo_lectivo)`: una postulación por escuela y año. UK `(id, escuela_id)` para FKs compuestas.

## requisitos

Dato que se exige para inscribir un alumno en un convenio. Solo se edita con el convenio en `aceptado`.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| convenio_id | uuid | NN, FK → `convenios.id` (cascade) | Convenio al que pertenece |
| nombre | text | NN, UK con `convenio_id` | Nombre del dato (ej. "Certificado médico") |
| descripcion | text | | Aclaración para quien completa |
| tipo | tipo_requisito | NN, default `texto` | Tipo de valor esperado |
| obligatorio | boolean | NN, default `true` | Necesario para enviar la inscripción |
| orden | smallint | NN, default 0 | Orden en el formulario |
| creado_por | uuid | FK → `perfiles.id` (set null) | Usuario que lo creó |
| creado_en | timestamptz | NN | Fecha de alta |

## inscripciones

Alumno inscripto en un convenio. Representa la pasantía.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| convenio_id | uuid | NN, FK compuesta `(convenio_id, escuela_id)` → convenios (cascade) | Convenio |
| alumno_id | uuid | NN, FK compuesta `(alumno_id, escuela_id)` → alumnos (cascade) | Alumno |
| escuela_id | uuid | NN, se completa por trigger | Garantiza misma escuela en alumno y convenio |
| estado | estado_inscripcion | NN, default `borrador` | Etapa de la inscripción |
| fecha_inicio | date | | Inicio real |
| fecha_fin | date | ≥ fecha_inicio | Fin real |
| horas_totales | smallint | > 0 | Carga horaria |
| tutor_escuela_id | uuid | FK → `perfiles.id` (set null), debe ser de la escuela | Tutor docente |
| tutor_empresa_id | uuid | FK → `perfiles.id` (set null), debe ser de la empresa | Tutor de la empresa |
| observaciones | text | | Notas generales |
| creado_en | timestamptz | NN | Fecha de alta |
| actualizado_en | timestamptz | NN, trigger | Última modificación |

UK `(convenio_id, alumno_id)`: un alumno una sola vez por convenio. UK `(id, convenio_id)` para FKs compuestas.

## datos_inscripcion

Valor cargado para cada requisito de una inscripción.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| inscripcion_id | uuid | NN, FK compuesta `(inscripcion_id, convenio_id)` → inscripciones (cascade) | Inscripción |
| requisito_id | uuid | NN, FK compuesta `(requisito_id, convenio_id)` → requisitos (cascade) | Requisito respondido |
| convenio_id | uuid | NN, se completa por trigger | Garantiza que el requisito sea del mismo convenio |
| valor | text | validado según `requisitos.tipo` | Valor (texto, número, fecha AAAA-MM-DD, si/no) |
| archivo_ruta | text | obligatorio si tipo = `archivo` | Ruta en bucket `documentos` |
| cargado_por | uuid | FK → `perfiles.id` (set null), default `auth.uid()` | Usuario que lo cargó |
| actualizado_en | timestamptz | NN, trigger | Última modificación |

CHECK: `valor` o `archivo_ruta` no nulo. UK `(inscripcion_id, requisito_id)`.

## seguimientos

Control periódico de una pasantía en curso.

| Campo | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id | uuid | PK | Identificador |
| inscripcion_id | uuid | NN, FK → `inscripciones.id` (cascade), estado `en_curso` | Pasantía |
| autor_id | uuid | FK → `perfiles.id` (set null), default `auth.uid()` | Quién lo registró |
| fecha | date | NN, default hoy | Fecha del seguimiento |
| progreso | smallint | NN, 0-100 | Avance estimado en % |
| observaciones | text | NN | Detalle del seguimiento |
| proxima_fecha | date | ≥ fecha | Próximo control |
| creado_en | timestamptz | NN | Fecha de carga |

## Storage

| Bucket | Público | Ruta | Uso |
|---|---|---|---|
| `logos` | Sí | `{id_organizacion}/{archivo}` | Logos de escuelas y empresas (JPG/PNG/WEBP, 5 MB) |
| `documentos` | No | `{id_convenio}/{id_inscripcion}/{archivo}` | Archivos de requisitos (PDF/JPG/PNG, 10 MB) |

## Funciones

| Función | Tipo | Descripción |
|---|---|---|
| `mi_rol()`, `mi_escuela()`, `mi_empresa()`, `es_admin()` | Auxiliar RLS | Datos del usuario logueado |
| `es_parte_convenio(uuid)`, `puede_ver_inscripcion(uuid)` | Auxiliar RLS | Pertenencia a un convenio |
| `registrar_organizacion(text, jsonb)` | RPC | Crea escuela/empresa y asigna al usuario como admin |
| `asignar_miembro(text, rol_usuario)` | RPC | El admin suma un usuario registrado a su organización |
| `crear_perfil_nuevo_usuario()` | Trigger `auth.users` | Crea el perfil al registrarse |
| `validar_convenio()`, `validar_requisito()`, `validar_inscripcion()`, `validar_dato_inscripcion()`, `validar_seguimiento()` | Trigger | Reglas de negocio y transiciones de estado |
| `tocar_actualizado_en()` | Trigger | Actualiza `actualizado_en` |
