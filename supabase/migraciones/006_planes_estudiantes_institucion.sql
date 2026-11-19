-- SAPE - Planes, datos institucionales y tipo de documento

alter table public.escuelas
  add column if not exists numero_escuela text,
  add column if not exists departamento text,
  add column if not exists distrito text,
  add column if not exists codigo_postal text,
  add column if not exists anio_inicio smallint,
  add column if not exists ambito text,
  add column if not exists gestion text,
  add column if not exists director text,
  add column if not exists sitio_web text;

alter table public.alumnos
  add column if not exists tipo_documento text not null default 'DNI';

alter table public.empresas
  add column if not exists referente_nombre text,
  add column if not exists referente_cargo text,
  add column if not exists referente_email text,
  add column if not exists referente_telefono text;

alter table public.convenios
  add column if not exists numero_plan text,
  add column if not exists fecha_carga date,
  add column if not exists tipo_plan text,
  add column if not exists visto boolean not null default false,
  add column if not exists disposicion text;

create table if not exists public.documentos_plan (
  id uuid primary key default gen_random_uuid(),
  convenio_id uuid not null references public.convenios(id) on delete cascade,
  nombre text not null,
  descripcion text,
  ruta text not null,
  tipo_mime text,
  tamano bigint check (tamano >= 0),
  cargado_por uuid default auth.uid() references public.perfiles(id) on delete set null,
  creado_en timestamptz not null default now()
);

create index if not exists documentos_plan_convenio_idx on public.documentos_plan (convenio_id);
alter table public.documentos_plan enable row level security;

grant select, insert, delete on public.documentos_plan to authenticated;

drop policy if exists "partes ven documentos de plan" on public.documentos_plan;
create policy "partes ven documentos de plan" on public.documentos_plan
  for select to authenticated using ((select public.es_parte_convenio(convenio_id)));

drop policy if exists "partes cargan documentos de plan" on public.documentos_plan;
create policy "partes cargan documentos de plan" on public.documentos_plan
  for insert to authenticated with check (
    cargado_por = (select auth.uid()) and (select public.es_parte_convenio(convenio_id))
  );

drop policy if exists "autor elimina documento de plan" on public.documentos_plan;
create policy "autor elimina documento de plan" on public.documentos_plan
  for delete to authenticated using (cargado_por = (select auth.uid()));

create or replace function public.registrar_organizacion(p_tipo text, p_datos jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Sesión requerida'; end if;
  if exists (select 1 from public.perfiles where id = auth.uid() and rol is not null) then
    raise exception 'El usuario ya pertenece a una organización';
  end if;

  if p_tipo = 'escuela' then
    insert into public.escuelas (
      nombre, cue, modalidad, especialidades, descripcion, direccion, localidad, provincia,
      email, telefono, numero_escuela, departamento, distrito, codigo_postal, anio_inicio,
      ambito, gestion, director, sitio_web
    )
    select
      nombre, cue, modalidad, coalesce(especialidades, '{}'), descripcion, direccion, localidad,
      provincia, email, telefono, numero_escuela, departamento, distrito, codigo_postal,
      anio_inicio, ambito, gestion, director, sitio_web
    from jsonb_populate_record(null::public.escuelas, p_datos)
    returning id into v_id;
    update public.perfiles set rol = 'escuela_admin', escuela_id = v_id where id = auth.uid();
  elsif p_tipo = 'empresa' then
    insert into public.empresas (razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion,
                                 localidad, provincia, email, telefono, sitio_web,
                                 referente_nombre, referente_cargo, referente_email, referente_telefono)
    select razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion,
           localidad, provincia, email, telefono, sitio_web,
           referente_nombre, referente_cargo, referente_email, referente_telefono
    from jsonb_populate_record(null::public.empresas, p_datos)
    returning id into v_id;
    update public.perfiles set rol = 'empresa_admin', empresa_id = v_id where id = auth.uid();
  else
    raise exception 'Tipo de organización inválido: %', p_tipo;
  end if;

  return v_id;
end $$;

revoke all on function public.registrar_organizacion(text, jsonb) from public, anon;
grant execute on function public.registrar_organizacion(text, jsonb) to authenticated;

notify pgrst, 'reload schema';
