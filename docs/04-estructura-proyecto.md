# 04 · Estructura del proyecto

Stack: Vue 3 + Vite + Vue Router + Supabase (Auth, PostgreSQL, Storage).

```
SaaS-SAPE/
├─ src/
│  ├─ main.js                 Punto de entrada: monta App, router y estilos
│  ├─ App.vue                 Layout raíz: login sin layout, resto con sidebar + topbar
│  ├─ views/                  Pantallas completas, una por ruta
│  ├─ components/
│  │  ├─ layout/              Estructura fija de la app (AppSidebar, AppTopbar)
│  │  └─ common/              Piezas reutilizables entre vistas (EstadoBadge)
│  ├─ router/
│  │  └─ index.js             Rutas y guarda de autenticación
│  ├─ services/               ÚNICO lugar con consultas a Supabase
│  │  ├─ supabase.js          Cliente, db() y ejecutar()
│  │  ├─ perfilService.js     Perfil, registrar organización, asignar miembros
│  │  ├─ escuelasService.js   Directorio y edición de escuelas
│  │  ├─ empresasService.js   Directorio y edición de empresas
│  │  ├─ conveniosService.js  Postulación, estados y requisitos
│  │  ├─ alumnosService.js    ABM de alumnos
│  │  ├─ inscripcionesService.js  Inscripciones, datos de requisitos y documentos
│  │  └─ seguimientosService.js   Seguimientos de pasantías
│  ├─ composables/
│  │  └─ useAuth.js           Estado global de sesión: usuario, perfil, organización
│  └─ assets/styles/          Hojas de estilo globales
├─ supabase/
│  ├─ reset.sql               Borra toda la estructura de la app
│  ├─ schema.sql              Tablas, tipos, FKs, CHECKs, triggers, RPC, RLS y Storage
│  ├─ seed.sql                Datos ficticios (2 escuelas, 3 empresas)
│  └─ tests/
│     ├─ verificacion.sql     Consultas para revisar relaciones
│     └─ pruebas_rls.sql      Pruebas de aislamiento y reglas (tabla OK/FALLA)
├─ docs/                      Análisis, DER, diccionario y esta estructura
└─ public/                    Archivos estáticos servidos tal cual
```

Regla: las vistas no llaman a `supabase.from(...)`; importan funciones de `services/`. Las vistas de autenticación usan `supabase.auth` directamente.

## Reconstruir la base

SQL Editor de Supabase, en este orden:

1. `supabase/reset.sql` (solo si ya existe la estructura)
2. `supabase/schema.sql`
3. `supabase/seed.sql`
4. `supabase/tests/pruebas_rls.sql` (opcional; modifica datos del seed)
