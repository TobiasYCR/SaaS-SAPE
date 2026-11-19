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

## Publicación

- **Vercel:** importar el repositorio; el build es `npm run build` y el directorio público es `dist`. `vercel.json` conserva las rutas internas de Vue.
- **Netlify:** usar `netlify.toml`; el redirect incluido entrega `index.html` para rutas internas.
- Configurar `VITE_SUPABASE_URL` y `VITE_SUPABASE_PUBLISHABLE_KEY` como variables del entorno de despliegue.
- En Supabase Authentication → URL Configuration, agregar la URL pública como Site URL y como Redirect URL.
- Ejecutar también `supabase/migraciones/006_planes_estudiantes_institucion.sql` en proyectos creados antes de esta actualización.

## Usuarios de prueba

La pantalla de login incluye **Cuentas de demostración por rol** y completa el email y la contraseña `Sape2026`.

1. Crear las cuentas en Supabase Authentication.
2. Vincularlas a las organizaciones ficticias con las instrucciones comentadas al final de `supabase/seed.sql`.
3. Una cuenta sin vincular entra a **Registrar organización** y crea su propia escuela o empresa.

## Pruebas

| Archivo | Qué verifica |
|---|---|
| `supabase/tests/pruebas_rls.sql` | Aislamiento entre organizaciones y reglas de negocio (26 casos) |
| `supabase/tests/flujo_completo.sql` | Recorrido completo con usuarios nuevos (50 casos) |
| `supabase/tests/funcion_principal.sql` | Inscripción de un alumno de punta a punta, con datos faltantes e inválidos (30 casos, no deja datos) |
| `supabase/tests/roles_alumnos.sql` | Qué puede hacer cada rol en el módulo Alumnos y aislamiento entre organizaciones (45 casos, no deja datos) |
| `supabase/tests/seguridad_documentos_usuarios.sql` | Documentos privados, cambio de rol, desactivación/reactivación y aislamiento (13 casos, no deja datos) |
| `supabase/tests/verificacion.sql` | Consultas de solo lectura sobre las relaciones |

`npm test`, `npm run lint` y `npm run build` deben terminar sin errores.

## Documentación

`docs/`: análisis y entidades, DER, diccionario de datos, estructura del proyecto, función principal y módulo Alumnos con roles y permisos.

## Base existente

Ejecutar en orden las migraciones de `supabase/migraciones/` que todavía no se aplicaron.
