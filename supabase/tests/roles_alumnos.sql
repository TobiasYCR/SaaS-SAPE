-- =====================================================================
-- SAPE · Matriz de permisos del módulo Alumnos por rol y organización
-- Prueba qué acciones se permiten y cuáles se bloquean para cada tipo de
-- usuario. Requiere schema.sql + seed.sql. Corre dentro de una transacción
-- con ROLLBACK: no deja nada guardado. Devuelve una tabla OK / FALLA.
-- =====================================================================

begin;

create temp table res (n serial, resultado text, usuario text, accion text, esperado text, obtenido text);
create temp table ids (clave text primary key, valor text);
grant all on res, ids to authenticated, anon;
grant usage on sequence res_n_seq to authenticated, anon;

-- Usuarios temporales: uno por tipo
insert into auth.users (id, email, aud, role, raw_user_meta_data) values
  ('d0000000-0000-4000-8000-000000000001', 'admin.escuela@roles.test',  'authenticated', 'authenticated', '{"full_name":"Admin Río Claro"}'),
  ('d0000000-0000-4000-8000-000000000002', 'tutor.escuela@roles.test',  'authenticated', 'authenticated', '{"full_name":"Tutor Río Claro"}'),
  ('d0000000-0000-4000-8000-000000000003', 'admin.otra@roles.test',     'authenticated', 'authenticated', '{"full_name":"Admin Los Aromos"}'),
  ('d0000000-0000-4000-8000-000000000004', 'admin.empresa@roles.test',  'authenticated', 'authenticated', '{"full_name":"Admin Pixel"}'),
  ('d0000000-0000-4000-8000-000000000005', 'tutor.empresa@roles.test',  'authenticated', 'authenticated', '{"full_name":"Tutor Pixel"}'),
  ('d0000000-0000-4000-8000-000000000006', 'sin.org@roles.test',        'authenticated', 'authenticated', '{"full_name":"Sin organización"}'),
  ('d0000000-0000-4000-8000-000000000007', 'inactivo@roles.test',       'authenticated', 'authenticated', '{"full_name":"Admin desactivado"}');
update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000001' where id = 'd0000000-0000-4000-8000-000000000001';
update public.perfiles set rol = 'escuela_tutor', escuela_id = '10000000-0000-4000-8000-000000000001' where id = 'd0000000-0000-4000-8000-000000000002';
update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000002' where id = 'd0000000-0000-4000-8000-000000000003';
update public.perfiles set rol = 'empresa_admin', empresa_id = '20000000-0000-4000-8000-000000000001' where id = 'd0000000-0000-4000-8000-000000000004';
update public.perfiles set rol = 'empresa_tutor', empresa_id = '20000000-0000-4000-8000-000000000001' where id = 'd0000000-0000-4000-8000-000000000005';
update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000001', activo = false where id = 'd0000000-0000-4000-8000-000000000007';

-- p_esperado: 'permitido' (sin error y afecta filas si es escritura) | 'bloqueado' (error o 0 filas) | número exacto
create function pg_temp.probar(p_usuario text, p_accion text, p_esperado text, p_sql text, p_guardar text default null) returns void
language plpgsql as $$
declare v_uid text; v_res text; v_obtenido text; v_ok boolean;
begin
  select id::text into v_uid from auth.users where email = p_usuario;
  perform set_config('request.jwt.claim.sub', coalesce(v_uid, ''), true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  if p_usuario is null then set local role anon; else set local role authenticated; end if;
  begin
    execute p_sql into v_res;
    v_obtenido := case when v_res in ('0', '') or v_res is null then 'bloqueado (0 filas)' else 'permitido (' || v_res || ')' end;
    if p_esperado ~ '^[0-9]+$' then v_ok := v_res = p_esperado; v_obtenido := coalesce(v_res, 'null') || ' fila(s)';
    else v_ok := (p_esperado = 'permitido') = (v_obtenido like 'permitido%'); end if;
    if p_guardar is not null then insert into ids values (p_guardar, v_res) on conflict (clave) do update set valor = excluded.valor; end if;
  exception when others then
    v_obtenido := 'bloqueado: ' || left(sqlerrm, 80);
    v_ok := p_esperado = 'bloqueado';
  end;
  reset role;
  insert into res (resultado, usuario, accion, esperado, obtenido)
  values (case when v_ok then 'OK' else 'FALLA' end, coalesce(p_usuario, 'sin sesión'), p_accion, p_esperado, v_obtenido);
end $$;
create function pg_temp.id(c text) returns text language sql as $$ select valor from ids where clave = c $$;

-- Integridad del modelo: todo usuario con rol pertenece a exactamente una organización
insert into res (resultado, usuario, accion, esperado, obtenido)
select case when count(*) = 0 then 'OK' else 'FALLA' end, 'base de datos', 'Usuarios con rol pero sin organización', '0', count(*) || ' usuario(s)'
from public.perfiles where rol is not null and escuela_id is null and empresa_id is null;

-- ---------- Administrador de escuela: gestiona sus alumnos ----------
select pg_temp.probar('admin.escuela@roles.test', 'Listar alumnos de su escuela',          '4',         $q$select count(*) from alumnos where activo$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Buscar por apellido (ilike)',           '1',         $q$select count(*) from alumnos where apellido ilike '%ríos%'$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Ordenar por curso',                     'permitido', $q$select string_agg(dni, ',' order by curso, division, apellido) from alumnos$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Crear alumno',                          'permitido', $q$with a as (insert into alumnos (escuela_id, nombre, apellido, dni, curso) values (mi_escuela(), 'Nuevo', 'Alumno', '48000001', 5) returning id) select id from a$q$, 'nuevo');
select pg_temp.probar('admin.escuela@roles.test', 'Modificar alumno',                      'permitido', format($q$with u as (update alumnos set curso = 6 where id = %L returning 1) select count(*) from u$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Modificar con DNI inválido',            'bloqueado', format($q$with u as (update alumnos set dni = '12' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Modificar con DNI repetido',            'bloqueado', format($q$with u as (update alumnos set dni = '45000101' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Modificar con curso fuera de rango',    'bloqueado', format($q$with u as (update alumnos set curso = 0 where id = %L returning 1) select count(*) from u$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Modificar quitando el apellido',        'bloqueado', format($q$with u as (update alumnos set apellido = null where id = %L returning 1) select count(*) from u$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Mover alumno a otra escuela',           'bloqueado', format($q$with u as (update alumnos set escuela_id = '10000000-0000-4000-8000-000000000002' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Dar de baja (activo = false)',          'permitido', $q$with u as (update alumnos set activo = false where dni = '45000104' returning 1) select count(*) from u$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Reactivar',                             'permitido', $q$with u as (update alumnos set activo = true where dni = '45000104' returning 1) select count(*) from u$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Eliminar alumno sin inscripciones',     'permitido', format($q$with d as (delete from alumnos where id = %L returning 1) select count(*) from d$q$, pg_temp.id('nuevo')));
select pg_temp.probar('admin.escuela@roles.test', 'Eliminar alumno con inscripciones',     'bloqueado', $q$with d as (delete from alumnos where dni = '45000101' and escuela_id = mi_escuela() returning 1) select count(*) from d$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Ver alumnos de otra escuela',           '0',         $q$select count(*) from alumnos where escuela_id = '10000000-0000-4000-8000-000000000002'$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Buscar por DNI de otra escuela',        '0',         $q$select count(*) from alumnos where dni = '45000202'$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Crear alumno en otra escuela',          'bloqueado', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values ('10000000-0000-4000-8000-000000000002', 'X', 'Y', '48000002') returning 1$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Modificar alumno de otra escuela',      'bloqueado', $q$with u as (update alumnos set nombre = 'X' where dni = '45000201' returning 1) select count(*) from u$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Eliminar alumno de otra escuela',       'bloqueado', $q$with d as (delete from alumnos where dni = '45000203' returning 1) select count(*) from d$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Cambiarse el rol',                      'bloqueado', $q$with u as (update perfiles set rol = 'empresa_admin' where id = auth.uid() returning 1) select count(*) from u$q$);
select pg_temp.probar('admin.escuela@roles.test', 'Pasarse a otra organización',           'bloqueado', $q$with u as (update perfiles set escuela_id = '10000000-0000-4000-8000-000000000002' where id = auth.uid() returning 1) select count(*) from u$q$);

-- ---------- Tutor de escuela: consulta ----------
select pg_temp.probar('tutor.escuela@roles.test', 'Listar alumnos de su escuela',          '4',         $q$select count(*) from alumnos where activo$q$);
select pg_temp.probar('tutor.escuela@roles.test', 'Crear alumno',                          'bloqueado', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values (mi_escuela(), 'X', 'Y', '48000003') returning 1$q$);
select pg_temp.probar('tutor.escuela@roles.test', 'Modificar alumno',                      'bloqueado', $q$with u as (update alumnos set nombre = 'X' where dni = '45000102' returning 1) select count(*) from u$q$);
select pg_temp.probar('tutor.escuela@roles.test', 'Dar de baja',                           'bloqueado', $q$with u as (update alumnos set activo = false where dni = '45000102' returning 1) select count(*) from u$q$);
select pg_temp.probar('tutor.escuela@roles.test', 'Eliminar alumno',                       'bloqueado', $q$with d as (delete from alumnos where dni = '45000104' returning 1) select count(*) from d$q$);
select pg_temp.probar('tutor.escuela@roles.test', 'Sumar miembros',                        'bloqueado', $q$select asignar_miembro('sin.org@roles.test', 'escuela_tutor')$q$);

-- ---------- Administrador de otra escuela ----------
select pg_temp.probar('admin.otra@roles.test',    'Listar: solo los de su escuela',        '4',         $q$select count(*) from alumnos$q$);
select pg_temp.probar('admin.otra@roles.test',    'Ver alumnos de Río Claro',              '0',         $q$select count(*) from alumnos where escuela_id = '10000000-0000-4000-8000-000000000001'$q$);
select pg_temp.probar('admin.otra@roles.test',    'Modificar alumno de Río Claro',         'bloqueado', $q$with u as (update alumnos set nombre = 'X' where dni = '45000102' returning 1) select count(*) from u$q$);
select pg_temp.probar('admin.otra@roles.test',    'Eliminar alumno de Río Claro',          'bloqueado', $q$with d as (delete from alumnos where dni = '45000104' returning 1) select count(*) from d$q$);

-- ---------- Administrador de empresa ----------
select pg_temp.probar('admin.empresa@roles.test', 'Ver alumnos con inscripción enviada',   '2',         $q$select count(*) from alumnos$q$);
select pg_temp.probar('admin.empresa@roles.test', 'Ver alumno en borrador (Lucía)',        '0',         $q$select count(*) from alumnos where dni = '45000103'$q$);
select pg_temp.probar('admin.empresa@roles.test', 'Crear alumno',                          'bloqueado', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values ('10000000-0000-4000-8000-000000000001', 'X', 'Y', '48000004') returning 1$q$);
select pg_temp.probar('admin.empresa@roles.test', 'Modificar alumno',                      'bloqueado', $q$with u as (update alumnos set nombre = 'X' where dni = '45000101' returning 1) select count(*) from u$q$);
select pg_temp.probar('admin.empresa@roles.test', 'Eliminar alumno',                       'bloqueado', $q$with d as (delete from alumnos where dni = '45000101' returning 1) select count(*) from d$q$);

-- ---------- Tutor de empresa ----------
select pg_temp.probar('tutor.empresa@roles.test', 'Ver alumnos con inscripción enviada',   '2',         $q$select count(*) from alumnos$q$);
select pg_temp.probar('tutor.empresa@roles.test', 'Modificar alumno',                      'bloqueado', $q$with u as (update alumnos set nombre = 'X' where dni = '45000101' returning 1) select count(*) from u$q$);

-- ---------- Usuario sin organización, desactivado y sin sesión ----------
select pg_temp.probar('sin.org@roles.test',       'Listar alumnos',                        '0',         $q$select count(*) from alumnos$q$);
select pg_temp.probar('sin.org@roles.test',       'Crear alumno',                          'bloqueado', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values ('10000000-0000-4000-8000-000000000001', 'X', 'Y', '48000005') returning 1$q$);
select pg_temp.probar('inactivo@roles.test',      'Listar alumnos (admin desactivado)',    '0',         $q$select count(*) from alumnos$q$);
select pg_temp.probar('inactivo@roles.test',      'Crear alumno (admin desactivado)',      'bloqueado', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values ('10000000-0000-4000-8000-000000000001', 'X', 'Y', '48000006') returning 1$q$);
select pg_temp.probar(null,                       'Listar alumnos',                        'bloqueado', $q$select count(*) from alumnos$q$);
select pg_temp.probar(null,                       'Crear alumno',                          'bloqueado', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values ('10000000-0000-4000-8000-000000000001', 'X', 'Y', '48000007') returning 1$q$);

select resultado, usuario, accion, esperado, obtenido from res order by n;

rollback;
