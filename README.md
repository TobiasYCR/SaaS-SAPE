# SAPE · Pasantías escolares

Plataforma que conecta escuelas y empresas para gestionar pasantías: la empresa elige una escuela y se postula, la escuela acepta, configuran los requisitos, la escuela inscribe alumnos y ambas registran seguimientos.

Stack: Vue 3 + Vite + Vue Router + Supabase (Auth, PostgreSQL, Storage).

## Puesta en marcha

1. Supabase → SQL Editor: ejecutar `supabase/schema.sql` y después `supabase/seed.sql`.
2. Supabase → Authentication → Sign In / Providers → Email: habilitado.
3. Copiar `.env.example` a `.env` y completar con **Project Settings → API**:
   ```
   VITE_SUPABASE_URL=https://<proyecto>.supabase.co
   VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
   Solo la clave publicable. La clave `service_role` / secreta no va en el frontend.
4. Instalar y levantar:
   ```
   npm install
   npm run dev
   ```

## Usuarios de prueba

1. Registrar cuentas desde la pantalla de login.
2. Para usar las organizaciones ficticias del seed, vincular cada cuenta en el SQL Editor (líneas comentadas al final de `supabase/seed.sql`).
3. Una cuenta sin vincular entra a **Registrar organización** y crea su propia escuela o empresa.

## Pruebas

| Archivo | Qué verifica |
|---|---|
| `supabase/tests/pruebas_rls.sql` | Aislamiento entre organizaciones y reglas de negocio (26 casos) |
| `supabase/tests/flujo_completo.sql` | Recorrido completo con usuarios nuevos (50 casos) |
| `supabase/tests/funcion_principal.sql` | Inscripción de un alumno de punta a punta, con datos faltantes e inválidos (30 casos, no deja datos) |
| `supabase/tests/verificacion.sql` | Consultas de solo lectura sobre las relaciones |

`npm run lint` y `npm run build` deben terminar sin errores.

## Documentación

`docs/`: análisis y entidades, DER, diccionario de datos, estructura del proyecto y función principal.

## Base existente

Ejecutar en orden las migraciones de `supabase/migraciones/` que todavía no se aplicaron.
