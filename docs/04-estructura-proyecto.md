# 04 · Estructura del proyecto

Stack: Vue 3 + Vite + Vue Router + Supabase (Auth, PostgreSQL, Storage).

```
SaaS-SAPE/
├─ src/
│  ├─ main.js                   Punto de entrada: monta App, router y estilos
│  ├─ App.vue                   Layout raíz: login sin layout, resto con menú + barra superior
│  ├─ views/                    Pantallas completas, una por ruta
│  │  ├─ AuthView               Login y registro de usuario
│  │  ├─ RegistroOrganizacion   Alta de la escuela o empresa del usuario
│  │  ├─ Dashboard              Resumen, pendientes y próximos seguimientos
│  │  ├─ Escuelas / Empresas    Directorios con búsqueda y filtros (la empresa se postula)
│  │  ├─ Alumnos / Detalle      ABM de alumnos e inscripción a una pasantía (solo escuelas)
│  │  ├─ Convenios / Detalle    Postulaciones, estados y requisitos
│  │  ├─ Inscripciones / Detalle  Datos de requisitos, estados y seguimientos
│  │  ├─ Seguimientos           Progreso de pasantías
│  │  ├─ Organizacion           Datos de la organización y miembros
│  │  └─ ChangePassword         Cambio de contraseña
│  ├─ components/
│  │  ├─ layout/                Estructura fija (AppSidebar, AppTopbar)
│  │  ├─ common/                Avisos, campo de formulario, etiquetas de estado y de prueba
│  │  ├─ organizacion/          Formularios de escuela y empresa
│  │  └─ convenios/             Formulario de propuesta
│  ├─ router/
│  │  └─ index.js               Rutas y guardas: sesión, organización, tipo y rol
│  ├─ services/                 ÚNICO lugar con consultas a Supabase (un archivo por entidad)
│  ├─ composables/
│  │  ├─ useAuth.js             Sesión, perfil, organización y rol
│  │  └─ useOperacion.js        Estado de carga, confirmación y error de cada operación
│  ├─ utils/
│  │  ├─ validaciones.js        Reglas de los formularios (las mismas que aplica la base)
│  │  ├─ errores.js             Traducción de errores de Supabase a mensajes legibles
│  │  └─ catalogos.js           Provincias, estados, tipos de requisito, fechas
│  └─ assets/styles/            Hojas de estilo globales (app.css: formularios y celulares)
├─ supabase/
│  ├─ reset.sql                 Borra toda la estructura de la app
│  ├─ schema.sql                Tablas, tipos, FKs, CHECKs, triggers, RPC, RLS y Storage
│  ├─ seed.sql                  Datos ficticios (2 escuelas, 3 empresas), marcados como prueba
│  ├─ migraciones/
│  │  ├─ 002_version1.sql       Lleva una base de la etapa anterior a la versión 1
│  │  └─ 003_seguridad.sql      Ajustes del Security Advisor de Supabase
│  └─ tests/
│     ├─ verificacion.sql       Consultas para revisar relaciones
│     ├─ pruebas_rls.sql        Aislamiento entre organizaciones (tabla OK/FALLA)
│     ├─ flujo_completo.sql     Recorrido completo con usuarios nuevos (tabla OK/FALLA)
│     └─ funcion_principal.sql  Inscripción de un alumno, con ROLLBACK (no deja datos)
├─ docs/                        Análisis, DER, diccionario y esta estructura
└─ public/                      Archivos estáticos servidos tal cual
```

Regla: las vistas no llaman a `supabase.from(...)`; importan funciones de `services/`. Las vistas de autenticación usan `supabase.auth` directamente.

## Reconstruir la base

SQL Editor de Supabase, en este orden:

1. `supabase/reset.sql` (solo si ya existe la estructura)
2. `supabase/schema.sql`
3. `supabase/seed.sql`
4. `supabase/tests/pruebas_rls.sql` y `supabase/tests/flujo_completo.sql` (opcional; modifican datos)

Base existente con datos a conservar: ejecutar las migraciones que falten de `supabase/migraciones/`, en orden.
