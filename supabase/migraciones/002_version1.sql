-- =====================================================================
-- SAPE · Migración 002 (versión 1 de la aplicación)
-- Solo para una base creada con la versión anterior de schema.sql.
-- En una base nueva no hace falta: schema.sql ya incluye estos cambios.
-- =====================================================================

-- 1. Marca de datos de prueba en las organizaciones
alter table public.escuelas add column if not exists datos_prueba boolean not null default false;
alter table public.empresas add column if not exists datos_prueba boolean not null default false;

update public.escuelas set datos_prueba = true where id in (
  '10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002');
update public.empresas set datos_prueba = true where id in (
  '20000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002',
  '20000000-0000-4000-8000-000000000003');

-- 2. Conservar historial: un alumno con inscripciones no se puede borrar (se da de baja)
alter table public.inscripciones drop constraint if exists inscripciones_alumno_id_escuela_id_fkey;
alter table public.inscripciones add constraint inscripciones_alumno_id_escuela_id_fkey
  foreign key (alumno_id, escuela_id) references public.alumnos(id, escuela_id);

-- 3. Privacidad: la empresa no ve inscripciones en borrador ni sus alumnos y datos
create or replace function public.puede_ver_inscripcion(p_inscripcion uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.inscripciones i
    where i.id = p_inscripcion and public.es_parte_convenio(i.convenio_id)
      and (i.escuela_id = public.mi_escuela() or i.estado <> 'borrador')
  )
$$;

drop policy if exists "escuela ve sus alumnos y empresa los inscriptos" on public.alumnos;
create policy "escuela ve sus alumnos y empresa los inscriptos" on public.alumnos
  for select to authenticated using (
       escuela_id = (select public.mi_escuela())
    or exists (select 1 from public.inscripciones i
               join public.convenios c on c.id = i.convenio_id
               where i.alumno_id = alumnos.id and i.estado <> 'borrador'
                 and c.empresa_id = (select public.mi_empresa()))
  );

drop policy if exists "partes ven inscripciones" on public.inscripciones;
create policy "partes ven inscripciones" on public.inscripciones
  for select to authenticated using (
    (select public.es_parte_convenio(convenio_id))
    and (escuela_id = (select public.mi_escuela()) or estado <> 'borrador')
  );

drop policy if exists "admins de las partes actualizan inscripciones" on public.inscripciones;
create policy "admins de las partes actualizan inscripciones" on public.inscripciones
  for update to authenticated
  using (
    (select public.es_admin()) and (select public.es_parte_convenio(convenio_id))
    and (escuela_id = (select public.mi_escuela()) or estado <> 'borrador')
  )
  with check ((select public.es_parte_convenio(convenio_id)));

drop policy if exists "partes ven datos de inscripcion" on public.datos_inscripcion;
create policy "partes ven datos de inscripcion" on public.datos_inscripcion
  for select to authenticated using ((select public.puede_ver_inscripcion(inscripcion_id)));

notify pgrst, 'reload schema';
