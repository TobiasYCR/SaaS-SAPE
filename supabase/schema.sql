-- =====================================================================
-- SAPE · Esquema de base de datos (Supabase / PostgreSQL)
-- Ejecutar completo en el SQL Editor de Supabase sobre una base vacía.
-- Para reconstruir desde cero: ejecutar antes supabase/reset.sql.
-- Contraseñas y sesiones: Supabase Auth (auth.users). No hay tabla propia.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Tipos enumerados
-- ---------------------------------------------------------------------
create type public.rol_usuario as enum (
  'escuela_admin', 'escuela_tutor', 'empresa_admin', 'empresa_tutor'
);

create type public.estado_convenio as enum (
  'postulado',   -- la empresa eligió la escuela y se postuló
  'aceptado',    -- la escuela aceptó: etapa de configuración de requisitos
  'rechazado',   -- la escuela rechazó la postulación
  'activo',      -- configuración cerrada: se pueden inscribir alumnos
  'finalizado',
  'cancelado'
);

create type public.tipo_requisito as enum ('texto', 'numero', 'fecha', 'archivo', 'si_no');

create type public.estado_inscripcion as enum (
  'borrador', 'enviada', 'aceptada', 'rechazada', 'en_curso', 'finalizada', 'cancelada'
);

-- ---------------------------------------------------------------------
-- 2. Tablas
-- ---------------------------------------------------------------------

-- Organización cliente: escuela
create table public.escuelas (
  id              uuid primary key default gen_random_uuid(),
  nombre          text not null check (length(trim(nombre)) > 0),
  cue             text not null unique check (cue ~ '^[0-9]{9}$'),
  modalidad       text,
  especialidades  text[] not null default '{}',
  descripcion     text,
  direccion       text,
  localidad       text not null,
  provincia       text not null,
  email           text check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  telefono        text,
  logo_url        text,
  logo_ruta       text,
  activa          boolean not null default true,
  datos_prueba    boolean not null default false,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

-- Organización cliente: empresa
create table public.empresas (
  id               uuid primary key default gen_random_uuid(),
  razon_social     text not null check (length(trim(razon_social)) > 0),
  nombre_fantasia  text,
  cuit             text not null unique check (cuit ~ '^[0-9]{11}$'),
  rubro            text,
  descripcion      text,
  direccion        text,
  localidad        text not null,
  provincia        text not null,
  email            text check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  telefono         text,
  sitio_web        text,
  logo_url         text,
  logo_ruta        text,
  activa           boolean not null default true,
  datos_prueba     boolean not null default false,
  creado_en        timestamptz not null default now(),
  actualizado_en   timestamptz not null default now()
);

-- Datos del usuario (1:1 con auth.users). Pertenece a una sola organización.
create table public.perfiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  nombre_completo  text,
  email            text,
  telefono         text,
  rol              public.rol_usuario,
  escuela_id       uuid references public.escuelas(id),
  empresa_id       uuid references public.empresas(id),
  activo           boolean not null default true,
  creado_en        timestamptz not null default now(),
  constraint perfil_una_organizacion check (
       (rol is null and escuela_id is null and empresa_id is null)
    or (rol in ('escuela_admin', 'escuela_tutor') and escuela_id is not null and empresa_id is null)
    or (rol in ('empresa_admin', 'empresa_tutor') and empresa_id is not null and escuela_id is null)
  )
);
create index perfiles_escuela_idx on public.perfiles (escuela_id);
create index perfiles_empresa_idx on public.perfiles (empresa_id);

-- Alumnos: los administra la escuela, no tienen cuenta
create table public.alumnos (
  id                    uuid primary key default gen_random_uuid(),
  escuela_id            uuid not null references public.escuelas(id) on delete cascade,
  nombre                text not null,
  apellido              text not null,
  dni                   text not null check (dni ~ '^[0-9]{7,8}$'),
  fecha_nacimiento      date,
  curso                 smallint check (curso between 1 and 7),
  division              text,
  especialidad          text,
  email                 text check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  telefono              text,
  responsable_nombre    text,
  responsable_telefono  text,
  activo                boolean not null default true,
  creado_en             timestamptz not null default now(),
  actualizado_en        timestamptz not null default now(),
  unique (escuela_id, dni),
  unique (id, escuela_id)
);

-- Convenio empresa ↔ escuela. Lo inicia siempre la empresa.
create table public.convenios (
  id              uuid primary key default gen_random_uuid(),
  empresa_id      uuid not null references public.empresas(id) on delete cascade,
  escuela_id      uuid not null references public.escuelas(id) on delete cascade,
  ciclo_lectivo   smallint not null check (ciclo_lectivo between 2020 and 2100),
  area            text,
  descripcion     text,
  cupos           smallint not null check (cupos > 0),
  fecha_inicio    date,
  fecha_fin       date,
  estado          public.estado_convenio not null default 'postulado',
  respondido_en   timestamptz,
  creado_por      uuid default auth.uid() references public.perfiles(id) on delete set null,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now(),
  check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio),
  unique (empresa_id, escuela_id, ciclo_lectivo),
  unique (id, escuela_id)
);
create index convenios_escuela_idx on public.convenios (escuela_id);

-- Datos que se piden para inscribir un alumno en un convenio (definición dinámica)
create table public.requisitos (
  id           uuid primary key default gen_random_uuid(),
  convenio_id  uuid not null references public.convenios(id) on delete cascade,
  nombre       text not null check (length(trim(nombre)) > 0),
  descripcion  text,
  tipo         public.tipo_requisito not null default 'texto',
  obligatorio  boolean not null default true,
  orden        smallint not null default 0,
  creado_por   uuid default auth.uid() references public.perfiles(id) on delete set null,
  creado_en    timestamptz not null default now(),
  unique (convenio_id, nombre),
  unique (id, convenio_id)
);

-- Alumno inscripto en un convenio
create table public.inscripciones (
  id                uuid primary key default gen_random_uuid(),
  convenio_id       uuid not null,
  alumno_id         uuid not null,
  escuela_id        uuid not null,
  estado            public.estado_inscripcion not null default 'borrador',
  fecha_inicio      date,
  fecha_fin         date,
  horas_totales     smallint check (horas_totales > 0),
  tutor_escuela_id  uuid references public.perfiles(id) on delete set null,
  tutor_empresa_id  uuid references public.perfiles(id) on delete set null,
  observaciones     text,
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now(),
  -- FKs compuestas: convenio y alumno deben ser de la misma escuela
  foreign key (convenio_id, escuela_id) references public.convenios(id, escuela_id) on delete cascade,
  -- Sin cascada: un alumno con inscripciones no se borra (se da de baja con activo = false)
  foreign key (alumno_id, escuela_id)   references public.alumnos(id, escuela_id),
  check (fecha_fin is null or fecha_inicio is null or fecha_fin >= fecha_inicio),
  unique (convenio_id, alumno_id),
  unique (id, convenio_id)
);
create index inscripciones_alumno_idx on public.inscripciones (alumno_id);

-- Valor cargado para cada requisito de una inscripción
create table public.datos_inscripcion (
  id              uuid primary key default gen_random_uuid(),
  inscripcion_id  uuid not null,
  requisito_id    uuid not null,
  convenio_id     uuid not null,
  valor           text,
  archivo_ruta    text,
  cargado_por     uuid default auth.uid() references public.perfiles(id) on delete set null,
  actualizado_en  timestamptz not null default now(),
  -- FKs compuestas: el requisito debe ser del mismo convenio que la inscripción
  foreign key (inscripcion_id, convenio_id) references public.inscripciones(id, convenio_id) on delete cascade,
  foreign key (requisito_id, convenio_id)   references public.requisitos(id, convenio_id)   on delete cascade,
  check (valor is not null or archivo_ruta is not null),
  unique (inscripcion_id, requisito_id)
);
create index datos_inscripcion_requisito_idx on public.datos_inscripcion (requisito_id);

-- Seguimiento periódico de una pasantía en curso
create table public.seguimientos (
  id              uuid primary key default gen_random_uuid(),
  inscripcion_id  uuid not null references public.inscripciones(id) on delete cascade,
  autor_id        uuid default auth.uid() references public.perfiles(id) on delete set null,
  fecha           date not null default current_date,
  progreso        smallint not null check (progreso between 0 and 100),
  observaciones   text not null,
  proxima_fecha   date,
  creado_en       timestamptz not null default now(),
  check (proxima_fecha is null or proxima_fecha >= fecha)
);
create index seguimientos_inscripcion_idx on public.seguimientos (inscripcion_id);

-- ---------------------------------------------------------------------
-- 3. Funciones auxiliares de sesión (usadas por RLS)
-- ---------------------------------------------------------------------
create function public.mi_rol() returns public.rol_usuario
language sql stable security definer set search_path = '' as $$
  select rol from public.perfiles where id = auth.uid() and activo
$$;

create function public.mi_escuela() returns uuid
language sql stable security definer set search_path = '' as $$
  select escuela_id from public.perfiles where id = auth.uid() and activo
$$;

create function public.mi_empresa() returns uuid
language sql stable security definer set search_path = '' as $$
  select empresa_id from public.perfiles where id = auth.uid() and activo
$$;

create function public.es_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(public.mi_rol() in ('escuela_admin', 'empresa_admin'), false)
$$;

-- ¿El usuario pertenece a la escuela o a la empresa del convenio?
create function public.es_parte_convenio(p_convenio uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.convenios c
    where c.id = p_convenio
      and (c.escuela_id = public.mi_escuela() or c.empresa_id = public.mi_empresa())
  )
$$;

-- La empresa ve una inscripción recién cuando la escuela la envía (no ve borradores)
create function public.puede_ver_inscripcion(p_inscripcion uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.inscripciones i
    where i.id = p_inscripcion and public.es_parte_convenio(i.convenio_id)
      and (i.escuela_id = public.mi_escuela() or i.estado <> 'borrador')
  )
$$;

-- ---------------------------------------------------------------------
-- 4. Triggers
-- ---------------------------------------------------------------------

-- actualizado_en automático
create function public.tocar_actualizado_en() returns trigger
language plpgsql as $$
begin
  new.actualizado_en := now();
  return new;
end $$;

create trigger escuelas_actualizado       before update on public.escuelas          for each row execute function public.tocar_actualizado_en();
create trigger empresas_actualizado       before update on public.empresas          for each row execute function public.tocar_actualizado_en();
create trigger alumnos_actualizado        before update on public.alumnos           for each row execute function public.tocar_actualizado_en();
create trigger convenios_actualizado      before update on public.convenios         for each row execute function public.tocar_actualizado_en();
create trigger inscripciones_actualizado  before update on public.inscripciones     for each row execute function public.tocar_actualizado_en();
create trigger datos_actualizado          before update on public.datos_inscripcion for each row execute function public.tocar_actualizado_en();

-- Alta de usuario en Supabase Auth → crea su perfil (sin organización todavía)
create function public.crear_perfil_nuevo_usuario() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.perfiles (id, nombre_completo, email)
  values (new.id, new.raw_user_meta_data ->> 'full_name', new.email);
  return new;
end $$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_nuevo_usuario();

-- Convenios: inmutables empresa/escuela/ciclo y transiciones de estado por rol.
-- Las validaciones se omiten cuando no hay usuario (SQL Editor / service role).
create function public.validar_convenio() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_rol public.rol_usuario := public.mi_rol();
begin
  if auth.uid() is null then return new; end if;

  if new.empresa_id <> old.empresa_id or new.escuela_id <> old.escuela_id
     or new.ciclo_lectivo <> old.ciclo_lectivo then
    raise exception 'No se puede cambiar la empresa, la escuela ni el ciclo lectivo de un convenio';
  end if;

  -- Propuesta (área, cupos, fechas, descripción): solo la empresa, antes de activarse
  if (new.area, new.descripcion, new.cupos, new.fecha_inicio, new.fecha_fin)
     is distinct from (old.area, old.descripcion, old.cupos, old.fecha_inicio, old.fecha_fin)
     and not (v_rol = 'empresa_admin' and old.estado in ('postulado', 'aceptado')) then
    raise exception 'Solo la empresa puede modificar la propuesta, y únicamente antes de activar el convenio';
  end if;

  if new.estado is distinct from old.estado then
    if not (
         (old.estado = 'postulado' and new.estado in ('aceptado', 'rechazado') and v_rol = 'escuela_admin')
      or (old.estado = 'postulado' and new.estado = 'cancelado' and v_rol = 'empresa_admin')
      or (old.estado = 'aceptado'  and new.estado = 'activo'    and v_rol in ('escuela_admin', 'empresa_admin'))
      or (old.estado in ('aceptado', 'activo') and new.estado in ('finalizado', 'cancelado')
          and v_rol in ('escuela_admin', 'empresa_admin'))
    ) then
      raise exception 'Transición de convenio no permitida: % → % (rol %)', old.estado, new.estado, v_rol;
    end if;
    if new.estado in ('aceptado', 'rechazado') then new.respondido_en := now(); end if;
  end if;

  return new;
end $$;

create trigger convenios_validar
  before update on public.convenios
  for each row execute function public.validar_convenio();

-- Requisitos: solo se configuran mientras el convenio está 'aceptado'
create function public.validar_requisito() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_estado public.estado_convenio;
begin
  if auth.uid() is null then return coalesce(new, old); end if;

  select estado into v_estado from public.convenios
  where id = coalesce(new.convenio_id, old.convenio_id);

  if v_estado <> 'aceptado' then
    raise exception 'Los requisitos solo se configuran con el convenio en estado aceptado (estado actual: %)', v_estado;
  end if;
  return coalesce(new, old);
end $$;

create trigger requisitos_validar
  before insert or update or delete on public.requisitos
  for each row execute function public.validar_requisito();

-- Inscripciones: completa escuela_id, valida tutores, cupos y transiciones
create function public.validar_inscripcion() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_conv     public.convenios%rowtype;
  v_rol      public.rol_usuario := public.mi_rol();
  v_ocupados int;
  v_faltan   int;
begin
  if tg_op = 'INSERT' and new.escuela_id is null then
    select escuela_id into new.escuela_id from public.convenios where id = new.convenio_id;
  end if;

  select * into v_conv from public.convenios where id = new.convenio_id;

  -- Tutores: cada uno debe pertenecer a su organización (siempre se valida)
  if new.tutor_escuela_id is not null and not exists (
       select 1 from public.perfiles where id = new.tutor_escuela_id and escuela_id = new.escuela_id) then
    raise exception 'El tutor de escuela no pertenece a la escuela del alumno';
  end if;
  if new.tutor_empresa_id is not null and not exists (
       select 1 from public.perfiles where id = new.tutor_empresa_id and empresa_id = v_conv.empresa_id) then
    raise exception 'El tutor de empresa no pertenece a la empresa del convenio';
  end if;

  if auth.uid() is null then return new; end if;

  if tg_op = 'INSERT' then
    if v_conv.estado <> 'activo' then
      raise exception 'Solo se inscriben alumnos en convenios activos (estado actual: %)', v_conv.estado;
    end if;
    return new;
  end if;

  if new.convenio_id <> old.convenio_id or new.alumno_id <> old.alumno_id then
    raise exception 'No se puede cambiar el convenio ni el alumno de una inscripción';
  end if;

  if new.estado is distinct from old.estado then
    if not (
         (old.estado = 'borrador' and new.estado = 'enviada' and v_rol = 'escuela_admin')
      or (old.estado = 'enviada'  and new.estado in ('aceptada', 'rechazada') and v_rol = 'empresa_admin')
      or (old.estado = 'aceptada' and new.estado = 'en_curso'   and v_rol in ('escuela_admin', 'empresa_admin'))
      or (old.estado = 'en_curso' and new.estado = 'finalizada' and v_rol in ('escuela_admin', 'empresa_admin'))
      or (old.estado in ('borrador', 'enviada', 'aceptada') and new.estado = 'cancelada' and v_rol = 'escuela_admin')
    ) then
      raise exception 'Transición de inscripción no permitida: % → % (rol %)', old.estado, new.estado, v_rol;
    end if;

    -- Al enviar: todos los requisitos obligatorios deben tener dato cargado
    if new.estado = 'enviada' then
      select count(*) into v_faltan
      from public.requisitos r
      where r.convenio_id = new.convenio_id and r.obligatorio
        and not exists (select 1 from public.datos_inscripcion d
                        where d.inscripcion_id = new.id and d.requisito_id = r.id);
      if v_faltan > 0 then
        raise exception 'Faltan % requisito(s) obligatorio(s) por completar', v_faltan;
      end if;
    end if;

    -- Al aceptar: respetar los cupos del convenio
    if new.estado = 'aceptada' then
      select count(*) into v_ocupados from public.inscripciones
      where convenio_id = new.convenio_id and estado in ('aceptada', 'en_curso', 'finalizada');
      if v_ocupados >= v_conv.cupos then
        raise exception 'El convenio no tiene cupos disponibles (% de %)', v_ocupados, v_conv.cupos;
      end if;
    end if;
  end if;

  return new;
end $$;

create trigger inscripciones_validar
  before insert or update on public.inscripciones
  for each row execute function public.validar_inscripcion();

-- Datos de inscripción: completa convenio_id y valida el valor según el tipo de requisito
create function public.validar_dato_inscripcion() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_tipo public.tipo_requisito;
begin
  select convenio_id into new.convenio_id from public.inscripciones where id = new.inscripcion_id;
  select tipo into v_tipo from public.requisitos where id = new.requisito_id;

  if v_tipo = 'archivo' and new.archivo_ruta is null then
    raise exception 'El requisito es de tipo archivo: falta archivo_ruta';
  elsif v_tipo = 'numero' and new.valor !~ '^-?[0-9]+([.,][0-9]+)?$' then
    raise exception 'El valor "%" no es un número', new.valor;
  elsif v_tipo = 'si_no' and new.valor not in ('si', 'no') then
    raise exception 'El valor debe ser "si" o "no"';
  elsif v_tipo = 'fecha' then
    begin
      perform new.valor::date;
    exception when others then
      raise exception 'El valor "%" no es una fecha válida (AAAA-MM-DD)', new.valor;
    end;
  end if;
  return new;
end $$;

create trigger datos_inscripcion_validar
  before insert or update on public.datos_inscripcion
  for each row execute function public.validar_dato_inscripcion();

-- Seguimientos: solo sobre pasantías en curso
create function public.validar_seguimiento() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then return new; end if;
  if (select estado from public.inscripciones where id = new.inscripcion_id) <> 'en_curso' then
    raise exception 'Solo se registran seguimientos de pasantías en curso';
  end if;
  return new;
end $$;

create trigger seguimientos_validar
  before insert on public.seguimientos
  for each row execute function public.validar_seguimiento();

-- ---------------------------------------------------------------------
-- 5. Funciones RPC (llamadas desde el frontend con supabase.rpc)
-- ---------------------------------------------------------------------

-- Registra la organización del usuario logueado y lo deja como admin.
-- p_tipo: 'escuela' | 'empresa'. p_datos: columnas de la tabla en JSON.
create function public.registrar_organizacion(p_tipo text, p_datos jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Sesión requerida'; end if;
  if exists (select 1 from public.perfiles where id = auth.uid() and rol is not null) then
    raise exception 'El usuario ya pertenece a una organización';
  end if;

  if p_tipo = 'escuela' then
    insert into public.escuelas (nombre, cue, modalidad, especialidades, descripcion, direccion,
                                 localidad, provincia, email, telefono)
    select nombre, cue, modalidad, coalesce(especialidades, '{}'), descripcion, direccion,
           localidad, provincia, email, telefono
    from jsonb_populate_record(null::public.escuelas, p_datos)
    returning id into v_id;
    update public.perfiles set rol = 'escuela_admin', escuela_id = v_id where id = auth.uid();
  elsif p_tipo = 'empresa' then
    insert into public.empresas (razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion,
                                 localidad, provincia, email, telefono, sitio_web)
    select razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion,
           localidad, provincia, email, telefono, sitio_web
    from jsonb_populate_record(null::public.empresas, p_datos)
    returning id into v_id;
    update public.perfiles set rol = 'empresa_admin', empresa_id = v_id where id = auth.uid();
  else
    raise exception 'Tipo de organización inválido: %', p_tipo;
  end if;

  return v_id;
end $$;

-- El admin suma a su organización a un usuario ya registrado (por email)
create function public.asignar_miembro(p_email text, p_rol public.rol_usuario) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_rol public.rol_usuario := public.mi_rol();
begin
  if v_rol = 'escuela_admin' and p_rol in ('escuela_admin', 'escuela_tutor') then
    update public.perfiles set rol = p_rol, escuela_id = public.mi_escuela()
    where lower(email) = lower(p_email) and rol is null;
  elsif v_rol = 'empresa_admin' and p_rol in ('empresa_admin', 'empresa_tutor') then
    update public.perfiles set rol = p_rol, empresa_id = public.mi_empresa()
    where lower(email) = lower(p_email) and rol is null;
  else
    raise exception 'No tenés permiso para asignar el rol %', p_rol;
  end if;

  if not found then
    raise exception 'No existe un usuario libre registrado con el email %', p_email;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 6. Permisos y Row Level Security
-- ---------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke execute on all functions in schema public from anon, public;
grant execute on all functions in schema public to authenticated;

grant select, insert, update, delete on
  public.escuelas, public.empresas, public.alumnos, public.convenios,
  public.requisitos, public.inscripciones, public.datos_inscripcion, public.seguimientos
to authenticated;

-- perfiles: el usuario solo edita sus datos personales (rol y organización vía RPC)
revoke all on public.perfiles from authenticated;
grant select on public.perfiles to authenticated;
grant update (nombre_completo, telefono) on public.perfiles to authenticated;

alter table public.escuelas          enable row level security;
alter table public.empresas          enable row level security;
alter table public.perfiles          enable row level security;
alter table public.alumnos           enable row level security;
alter table public.convenios         enable row level security;
alter table public.requisitos        enable row level security;
alter table public.inscripciones     enable row level security;
alter table public.datos_inscripcion enable row level security;
alter table public.seguimientos      enable row level security;

-- Directorio mutuo: escuelas y empresas se ven entre sí
create policy "directorio de escuelas" on public.escuelas
  for select to authenticated using (true);
create policy "admin edita su escuela" on public.escuelas
  for update to authenticated
  using (id = (select public.mi_escuela()) and (select public.mi_rol()) = 'escuela_admin')
  with check (id = (select public.mi_escuela()));

create policy "directorio de empresas" on public.empresas
  for select to authenticated using (true);
create policy "admin edita su empresa" on public.empresas
  for update to authenticated
  using (id = (select public.mi_empresa()) and (select public.mi_rol()) = 'empresa_admin')
  with check (id = (select public.mi_empresa()));

-- Perfiles: el propio y los compañeros de organización
create policy "ver perfiles de mi organizacion" on public.perfiles
  for select to authenticated using (
       id = (select auth.uid())
    or (escuela_id is not null and escuela_id = (select public.mi_escuela()))
    or (empresa_id is not null and empresa_id = (select public.mi_empresa()))
  );
create policy "editar mi perfil" on public.perfiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- Alumnos: la escuela gestiona; la empresa ve solo los inscriptos en sus convenios
create policy "escuela ve sus alumnos y empresa los inscriptos" on public.alumnos
  for select to authenticated using (
       escuela_id = (select public.mi_escuela())
    or exists (select 1 from public.inscripciones i
               join public.convenios c on c.id = i.convenio_id
               where i.alumno_id = alumnos.id and i.estado <> 'borrador'
                 and c.empresa_id = (select public.mi_empresa()))
  );
create policy "admin escuela crea alumnos" on public.alumnos
  for insert to authenticated
  with check (escuela_id = (select public.mi_escuela()) and (select public.mi_rol()) = 'escuela_admin');
create policy "admin escuela edita alumnos" on public.alumnos
  for update to authenticated
  using (escuela_id = (select public.mi_escuela()) and (select public.mi_rol()) = 'escuela_admin')
  with check (escuela_id = (select public.mi_escuela()));
create policy "admin escuela elimina alumnos" on public.alumnos
  for delete to authenticated
  using (escuela_id = (select public.mi_escuela()) and (select public.mi_rol()) = 'escuela_admin');

-- Convenios: lo ven las dos partes; solo la empresa lo inicia
create policy "partes ven el convenio" on public.convenios
  for select to authenticated using (
    escuela_id = (select public.mi_escuela()) or empresa_id = (select public.mi_empresa())
  );
create policy "empresa se postula a una escuela" on public.convenios
  for insert to authenticated with check (
    (select public.mi_rol()) = 'empresa_admin'
    and empresa_id = (select public.mi_empresa())
    and estado = 'postulado'
  );
create policy "admins de las partes actualizan" on public.convenios
  for update to authenticated
  using ((select public.es_admin()) and (escuela_id = (select public.mi_escuela()) or empresa_id = (select public.mi_empresa())))
  with check (escuela_id = (select public.mi_escuela()) or empresa_id = (select public.mi_empresa()));
create policy "empresa retira su postulacion" on public.convenios
  for delete to authenticated using (
    (select public.mi_rol()) = 'empresa_admin' and empresa_id = (select public.mi_empresa()) and estado = 'postulado'
  );

-- Requisitos: los ven las partes; los configuran los admins de cualquiera de las dos
create policy "partes ven requisitos" on public.requisitos
  for select to authenticated using ((select public.es_parte_convenio(convenio_id)));
create policy "admins crean requisitos" on public.requisitos
  for insert to authenticated with check ((select public.es_admin()) and (select public.es_parte_convenio(convenio_id)));
create policy "admins editan requisitos" on public.requisitos
  for update to authenticated
  using ((select public.es_admin()) and (select public.es_parte_convenio(convenio_id)))
  with check ((select public.es_parte_convenio(convenio_id)));
create policy "admins eliminan requisitos" on public.requisitos
  for delete to authenticated using ((select public.es_admin()) and (select public.es_parte_convenio(convenio_id)));

-- Inscripciones: las crea la escuela; la empresa acepta/rechaza (ver trigger)
create policy "partes ven inscripciones" on public.inscripciones
  for select to authenticated using (
    (select public.es_parte_convenio(convenio_id))
    and (escuela_id = (select public.mi_escuela()) or estado <> 'borrador')
  );
create policy "escuela inscribe alumnos" on public.inscripciones
  for insert to authenticated with check (
    (select public.mi_rol()) = 'escuela_admin' and escuela_id = (select public.mi_escuela()) and estado = 'borrador'
  );
create policy "admins de las partes actualizan inscripciones" on public.inscripciones
  for update to authenticated
  using (
    (select public.es_admin()) and (select public.es_parte_convenio(convenio_id))
    and (escuela_id = (select public.mi_escuela()) or estado <> 'borrador')
  )
  with check ((select public.es_parte_convenio(convenio_id)));
create policy "escuela elimina borradores" on public.inscripciones
  for delete to authenticated using (
    (select public.mi_rol()) = 'escuela_admin' and escuela_id = (select public.mi_escuela()) and estado = 'borrador'
  );

-- Datos de inscripción: los carga la escuela mientras la inscripción es borrador
create policy "partes ven datos de inscripcion" on public.datos_inscripcion
  for select to authenticated using ((select public.puede_ver_inscripcion(inscripcion_id)));
create policy "escuela carga datos" on public.datos_inscripcion
  for insert to authenticated with check (
    (select public.mi_rol()) = 'escuela_admin'
    and exists (select 1 from public.inscripciones i
                where i.id = inscripcion_id and i.escuela_id = (select public.mi_escuela()) and i.estado = 'borrador')
  );
create policy "escuela edita datos" on public.datos_inscripcion
  for update to authenticated
  using (
    (select public.mi_rol()) = 'escuela_admin'
    and exists (select 1 from public.inscripciones i
                where i.id = inscripcion_id and i.escuela_id = (select public.mi_escuela()) and i.estado = 'borrador')
  )
  with check (
    exists (select 1 from public.inscripciones i
            where i.id = inscripcion_id and i.escuela_id = (select public.mi_escuela()) and i.estado = 'borrador')
  );
create policy "escuela elimina datos" on public.datos_inscripcion
  for delete to authenticated using (
    (select public.mi_rol()) = 'escuela_admin'
    and exists (select 1 from public.inscripciones i
                where i.id = inscripcion_id and i.escuela_id = (select public.mi_escuela()) and i.estado = 'borrador')
  );

-- Seguimientos: cualquier miembro de las partes; cada autor edita los suyos
create policy "partes ven seguimientos" on public.seguimientos
  for select to authenticated using ((select public.puede_ver_inscripcion(inscripcion_id)));
create policy "miembros cargan seguimientos" on public.seguimientos
  for insert to authenticated with check (
    autor_id = (select auth.uid()) and (select public.puede_ver_inscripcion(inscripcion_id))
  );
create policy "autor edita su seguimiento" on public.seguimientos
  for update to authenticated
  using (autor_id = (select auth.uid())) with check (autor_id = (select auth.uid()));
create policy "autor elimina su seguimiento" on public.seguimientos
  for delete to authenticated using (autor_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- 7. Storage
--   logos       (público): {id_organizacion}/archivo
--   documentos  (privado): {id_convenio}/{id_inscripcion}/archivo
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('logos', 'logos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('documentos', 'documentos', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "admin sube logo de su organizacion" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'logos' and (select public.es_admin())
    and (storage.foldername(name))[1] in ((select public.mi_escuela())::text, (select public.mi_empresa())::text)
  );
create policy "admin elimina logo de su organizacion" on storage.objects
  for delete to authenticated using (
    bucket_id = 'logos' and (select public.es_admin())
    and (storage.foldername(name))[1] in ((select public.mi_escuela())::text, (select public.mi_empresa())::text)
  );

create policy "partes ven documentos del convenio" on storage.objects
  for select to authenticated using (
    bucket_id = 'documentos'
    and exists (select 1 from public.convenios c where c.id::text = (storage.foldername(name))[1])
  );
create policy "escuela sube documentos" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'documentos' and (select public.mi_rol()) = 'escuela_admin'
    and exists (select 1 from public.convenios c
                where c.id::text = (storage.foldername(name))[1] and c.escuela_id = (select public.mi_escuela()))
  );
create policy "escuela elimina documentos" on storage.objects
  for delete to authenticated using (
    bucket_id = 'documentos' and (select public.mi_rol()) = 'escuela_admin'
    and exists (select 1 from public.convenios c
                where c.id::text = (storage.foldername(name))[1] and c.escuela_id = (select public.mi_escuela()))
  );

notify pgrst, 'reload schema';
