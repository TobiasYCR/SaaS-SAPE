# 02 · Diagrama entidad-relación

Fuente Mermaid (se renderiza en GitHub y VS Code). Imagen exportada: [`der.png`](der.png).

```mermaid
erDiagram
    AUTH_USERS ||--|| PERFILES : "tiene"
    ESCUELAS |o--o{ PERFILES : "emplea"
    EMPRESAS |o--o{ PERFILES : "emplea"
    ESCUELAS ||--o{ ALUMNOS : "administra"
    EMPRESAS ||--o{ CONVENIOS : "se postula"
    ESCUELAS ||--o{ CONVENIOS : "recibe"
    CONVENIOS ||--o{ REQUISITOS : "define"
    CONVENIOS ||--o{ INSCRIPCIONES : "incluye"
    ALUMNOS ||--o{ INSCRIPCIONES : "participa"
    INSCRIPCIONES ||--o{ DATOS_INSCRIPCION : "completa"
    REQUISITOS ||--o{ DATOS_INSCRIPCION : "se responde en"
    INSCRIPCIONES ||--o{ SEGUIMIENTOS : "registra"
    PERFILES |o--o{ SEGUIMIENTOS : "escribe"
    PERFILES |o--o{ INSCRIPCIONES : "tutorea"

    AUTH_USERS {
        uuid id PK
        text email
        text encrypted_password "gestionado por Supabase"
    }
    ESCUELAS {
        uuid id PK
        text nombre
        text cue UK
        text modalidad
        text_array especialidades
        text descripcion
        text direccion
        text localidad
        text provincia
        text email
        text telefono
        text logo_url
        text logo_ruta
        boolean activa
        timestamptz creado_en
        timestamptz actualizado_en
    }
    EMPRESAS {
        uuid id PK
        text razon_social
        text nombre_fantasia
        text cuit UK
        text rubro
        text descripcion
        text direccion
        text localidad
        text provincia
        text email
        text telefono
        text sitio_web
        text logo_url
        text logo_ruta
        boolean activa
        timestamptz creado_en
        timestamptz actualizado_en
    }
    PERFILES {
        uuid id PK,FK "auth.users.id"
        text nombre_completo
        text email
        text telefono
        rol_usuario rol
        uuid escuela_id FK
        uuid empresa_id FK
        boolean activo
        timestamptz creado_en
    }
    ALUMNOS {
        uuid id PK
        uuid escuela_id FK
        text nombre
        text apellido
        text dni "UK con escuela_id"
        date fecha_nacimiento
        smallint curso
        text division
        text especialidad
        text email
        text telefono
        text responsable_nombre
        text responsable_telefono
        boolean activo
        timestamptz creado_en
        timestamptz actualizado_en
    }
    CONVENIOS {
        uuid id PK
        uuid empresa_id FK
        uuid escuela_id FK
        smallint ciclo_lectivo "UK con empresa_id y escuela_id"
        text area
        text descripcion
        smallint cupos
        date fecha_inicio
        date fecha_fin
        estado_convenio estado
        timestamptz respondido_en
        uuid creado_por FK
        timestamptz creado_en
        timestamptz actualizado_en
    }
    REQUISITOS {
        uuid id PK
        uuid convenio_id FK
        text nombre "UK con convenio_id"
        text descripcion
        tipo_requisito tipo
        boolean obligatorio
        smallint orden
        uuid creado_por FK
        timestamptz creado_en
    }
    INSCRIPCIONES {
        uuid id PK
        uuid convenio_id FK "FK compuesta con escuela_id"
        uuid alumno_id FK "FK compuesta con escuela_id"
        uuid escuela_id FK
        estado_inscripcion estado
        date fecha_inicio
        date fecha_fin
        smallint horas_totales
        uuid tutor_escuela_id FK
        uuid tutor_empresa_id FK
        text observaciones
        timestamptz creado_en
        timestamptz actualizado_en
    }
    DATOS_INSCRIPCION {
        uuid id PK
        uuid inscripcion_id FK "FK compuesta con convenio_id"
        uuid requisito_id FK "FK compuesta con convenio_id"
        uuid convenio_id FK
        text valor
        text archivo_ruta
        uuid cargado_por FK
        timestamptz actualizado_en
    }
    SEGUIMIENTOS {
        uuid id PK
        uuid inscripcion_id FK
        uuid autor_id FK
        date fecha
        smallint progreso
        text observaciones
        date proxima_fecha
        timestamptz creado_en
    }
```

## Relaciones y cardinalidades

| Relación | Cardinalidad | FK | On delete |
|---|---|---|---|
| auth.users → perfiles | 1 : 1 | `perfiles.id` | cascade |
| escuelas → perfiles | 1 : 0..N | `perfiles.escuela_id` | restrict |
| empresas → perfiles | 1 : 0..N | `perfiles.empresa_id` | restrict |
| escuelas → alumnos | 1 : 0..N | `alumnos.escuela_id` | cascade |
| empresas → convenios | 1 : 0..N | `convenios.empresa_id` | cascade |
| escuelas → convenios | 1 : 0..N | `convenios.escuela_id` | cascade |
| escuelas ↔ empresas | N : M | resuelta por `convenios` (UK empresa + escuela + ciclo) | |
| convenios → requisitos | 1 : 0..N | `requisitos.convenio_id` | cascade |
| convenios → inscripciones | 1 : 0..N | `inscripciones (convenio_id, escuela_id)` | cascade |
| alumnos → inscripciones | 1 : 0..N | `inscripciones (alumno_id, escuela_id)` | cascade |
| convenios ↔ alumnos | N : M | resuelta por `inscripciones` (UK convenio + alumno) | |
| inscripciones → datos_inscripcion | 1 : 0..N | `datos_inscripcion (inscripcion_id, convenio_id)` | cascade |
| requisitos → datos_inscripcion | 1 : 0..N | `datos_inscripcion (requisito_id, convenio_id)` | cascade |
| inscripciones ↔ requisitos | N : M | resuelta por `datos_inscripcion` (UK inscripción + requisito) | |
| inscripciones → seguimientos | 1 : 0..N | `seguimientos.inscripcion_id` | cascade |
| perfiles → seguimientos | 0..1 : 0..N | `seguimientos.autor_id` | set null |
| perfiles → inscripciones (tutores) | 0..1 : 0..N | `tutor_escuela_id`, `tutor_empresa_id` | set null |
