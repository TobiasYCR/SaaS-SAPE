-- =====================================================================
-- SAPE · Prueba de la función principal: inscribir un alumno en una pasantía
-- Recorre: ingresar como escuela → cargar alumno → inscribirlo → completar
-- requisitos → enviar → consultar el resultado (escuela, otra escuela y
-- empresa), y los casos de datos faltantes o inválidos.
-- Requiere schema.sql + seed.sql. Corre dentro de una transacción y termina
-- con ROLLBACK: no deja nada guardado. Devuelve una tabla OK / FALLA.
-- =====================================================================

begin;

create temp table res (n serial, resultado text, prueba text, detalle text);
create temp table ids (clave text primary key, valor text);
grant all on res, ids to authenticated, anon;
grant usage on sequence res_n_seq to authenticated, anon;

-- Usuarios temporales (se deshacen con el rollback)
insert into auth.users (id, email, aud, role, raw_user_meta_data) values
  ('c0000000-0000-4000-8000-000000000001', 'escuela.fp@sape.test', 'authenticated', 'authenticated', '{"full_name":"Escuela FP"}'),
  ('c0000000-0000-4000-8000-000000000002', 'otra.fp@sape.test',    'authenticated', 'authenticated', '{"full_name":"Otra escuela FP"}'),
  ('c0000000-0000-4000-8000-000000000003', 'empresa.fp@sape.test', 'authenticated', 'authenticated', '{"full_name":"Empresa FP"}');
update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000001' where id = 'c0000000-0000-4000-8000-000000000001'; -- Río Claro
update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000002' where id = 'c0000000-0000-4000-8000-000000000002'; -- Los Aromos
update public.perfiles set rol = 'empresa_admin', empresa_id = '20000000-0000-4000-8000-000000000001' where id = 'c0000000-0000-4000-8000-000000000003'; -- Pixel Andino

-- Ejecuta p_sql como el usuario (o sin sesión si p_email es null) y compara con lo esperado:
-- 'ok' | 'error' | valor exacto devuelto. p_guardar guarda el valor devuelto en ids.
create function pg_temp.paso(p_prueba text, p_email text, p_esperado text, p_sql text, p_guardar text default null) returns void
language plpgsql as $$
declare v_uid text; v_res text; v_ok boolean; v_det text;
begin
  select id::text into v_uid from auth.users where email = p_email;
  perform set_config('request.jwt.claim.sub', coalesce(v_uid, ''), true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  if p_email is null then set local role anon; else set local role authenticated; end if;
  begin
    execute p_sql into v_res;
    v_ok := case when p_esperado ~ '^[0-9]+$' then v_res = p_esperado else p_esperado = 'ok' end;
    v_det := coalesce(v_res, 'sin error');
    if p_guardar is not null then insert into ids values (p_guardar, v_res) on conflict (clave) do update set valor = excluded.valor; end if;
  exception when others then
    v_ok := p_esperado = 'error';
    v_det := sqlerrm;
  end;
  reset role;
  insert into res (resultado, prueba, detalle) values (case when v_ok then 'OK' else 'FALLA' end, p_prueba, left(v_det, 110));
end $$;
create function pg_temp.id(c text) returns text language sql as $$ select valor from ids where clave = c $$;

-- 1. Ingresa y carga el alumno (AlumnosView)
select pg_temp.paso('01. Escuela ve sus alumnos activos',          'escuela.fp@sape.test', '4',     $q$select count(*) from alumnos where activo$q$);
select pg_temp.paso('02. Falta el DNI',                            'escuela.fp@sape.test', 'error', $q$insert into alumnos (escuela_id, nombre, apellido) values (mi_escuela(), 'Ana', 'Prueba')$q$);
select pg_temp.paso('03. DNI con formato inválido',                'escuela.fp@sape.test', 'error', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values (mi_escuela(), 'Ana', 'Prueba', '12.345')$q$);
select pg_temp.paso('04. Curso fuera de rango',                    'escuela.fp@sape.test', 'error', $q$insert into alumnos (escuela_id, nombre, apellido, dni, curso) values (mi_escuela(), 'Ana', 'Prueba', '47000001', 9)$q$);
select pg_temp.paso('05. Email inválido',                          'escuela.fp@sape.test', 'error', $q$insert into alumnos (escuela_id, nombre, apellido, dni, email) values (mi_escuela(), 'Ana', 'Prueba', '47000001', 'ana@')$q$);
select pg_temp.paso('06. Carga alumno válido',                     'escuela.fp@sape.test', 'ok',    $q$with a as (insert into alumnos (escuela_id, nombre, apellido, dni, curso, division, especialidad) values (mi_escuela(), 'Ana', 'Prueba', '47000001', 6, 'A', 'Programación') returning id) select id from a$q$, 'alumno');
select pg_temp.paso('07. DNI repetido en la escuela',              'escuela.fp@sape.test', 'error', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values (mi_escuela(), 'Otra', 'Persona', '47000001')$q$);
select pg_temp.paso('08. Alumno queda vinculado a su escuela',     'escuela.fp@sape.test', '1',     format($q$select count(*) from alumnos where id = %L and escuela_id = '10000000-0000-4000-8000-000000000001'$q$, pg_temp.id('alumno')));
select pg_temp.paso('09. No puede cargar alumnos en otra escuela', 'escuela.fp@sape.test', 'error', $q$insert into alumnos (escuela_id, nombre, apellido, dni) values ('10000000-0000-4000-8000-000000000002', 'X', 'Y', '47000002')$q$);

-- 2. Lo inscribe (AlumnoDetalleView / ConvenioDetalleView)
select pg_temp.paso('10. Inscribir en convenio no activo',         'escuela.fp@sape.test', 'error', format($q$insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000002', %L)$q$, pg_temp.id('alumno')));
select pg_temp.paso('11. Inscribe en convenio activo',             'escuela.fp@sape.test', 'ok',    format($q$with i as (insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000001', %L) returning id) select id from i$q$, pg_temp.id('alumno')), 'insc');
select pg_temp.paso('12. Queda en borrador y en su escuela',       'escuela.fp@sape.test', '1',     format($q$select count(*) from inscripciones where id = %L and estado = 'borrador' and escuela_id = mi_escuela()$q$, pg_temp.id('insc')));
select pg_temp.paso('13. Inscribirlo dos veces',                   'escuela.fp@sape.test', 'error', format($q$insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000001', %L)$q$, pg_temp.id('alumno')));
select pg_temp.paso('14. Empresa no ve el borrador',               'empresa.fp@sape.test', '0',     format($q$select count(*) from inscripciones where id = %L$q$, pg_temp.id('insc')));

-- 3. Completa requisitos y envía (InscripcionDetalleView)
select pg_temp.paso('15. Enviar con requisitos faltantes',         'escuela.fp@sape.test', 'error', format($q$update inscripciones set estado = 'enviada' where id = %L$q$, pg_temp.id('insc')));
select pg_temp.paso('16. Fecha con formato inválido',              'escuela.fp@sape.test', 'error', format($q$insert into datos_inscripcion (inscripcion_id, requisito_id, valor) values (%L, '50000000-0000-4000-8000-000000000104', '31/02/2026')$q$, pg_temp.id('insc')));
select pg_temp.paso('17. Valor sí/no inválido',                    'escuela.fp@sape.test', 'error', format($q$insert into datos_inscripcion (inscripcion_id, requisito_id, valor) values (%L, '50000000-0000-4000-8000-000000000103', 'quizas')$q$, pg_temp.id('insc')));
select pg_temp.paso('18. Requisito archivo sin archivo',           'escuela.fp@sape.test', 'error', format($q$insert into datos_inscripcion (inscripcion_id, requisito_id, valor) values (%L, '50000000-0000-4000-8000-000000000101', 'dni')$q$, pg_temp.id('insc')));
select pg_temp.paso('19. Guarda los 5 datos (upsert)',             'escuela.fp@sape.test', '5',     format($q$with d as (insert into datos_inscripcion (inscripcion_id, requisito_id, valor, archivo_ruta) values
  (%1$L, '50000000-0000-4000-8000-000000000101', null, '40000000-0000-4000-8000-000000000001/x/dni.pdf'),
  (%1$L, '50000000-0000-4000-8000-000000000102', null, '40000000-0000-4000-8000-000000000001/x/cert.pdf'),
  (%1$L, '50000000-0000-4000-8000-000000000103', 'si', null),
  (%1$L, '50000000-0000-4000-8000-000000000104', '2026-11-01', null),
  (%1$L, '50000000-0000-4000-8000-000000000105', 'HTML y CSS', null)
  on conflict (inscripcion_id, requisito_id) do update set valor = excluded.valor, archivo_ruta = excluded.archivo_ruta returning 1)
  select count(*) from d$q$, pg_temp.id('insc')));
select pg_temp.paso('20. Envía la inscripción',                    'escuela.fp@sape.test', '1',     format($q$with u as (update inscripciones set estado = 'enviada' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('insc')));
select pg_temp.paso('21. Datos fijos después de enviar',           'escuela.fp@sape.test', '0',     format($q$with u as (update datos_inscripcion set valor = 'no' where inscripcion_id = %L returning 1) select count(*) from u$q$, pg_temp.id('insc')));

-- 4. Consulta el resultado
select pg_temp.paso('22. Escuela consulta: enviada con 5 datos',   'escuela.fp@sape.test', '5',     format($q$select count(*) from inscripciones i join datos_inscripcion d on d.inscripcion_id = i.id where i.id = %L and i.estado = 'enviada'$q$, pg_temp.id('insc')));
select pg_temp.paso('23. Otra escuela no ve el alumno',            'otra.fp@sape.test',    '0',     format($q$select count(*) from alumnos where id = %L$q$, pg_temp.id('alumno')));
select pg_temp.paso('24. Otra escuela no ve la inscripción',       'otra.fp@sape.test',    '0',     format($q$select count(*) from inscripciones where id = %L$q$, pg_temp.id('insc')));
select pg_temp.paso('25. Otra escuela no modifica el alumno',      'otra.fp@sape.test',    '0',     format($q$with u as (update alumnos set nombre = 'X' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('alumno')));
select pg_temp.paso('26. Empresa ve la inscripción enviada',       'empresa.fp@sape.test', '1',     format($q$select count(*) from inscripciones where id = %L$q$, pg_temp.id('insc')));
select pg_temp.paso('27. Empresa ve al alumno inscripto',          'empresa.fp@sape.test', '1',     format($q$select count(*) from alumnos where id = %L$q$, pg_temp.id('alumno')));
select pg_temp.paso('28. Empresa acepta',                          'empresa.fp@sape.test', '1',     format($q$with u as (update inscripciones set estado = 'aceptada' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('insc')));
select pg_temp.paso('29. Escuela ve el resultado: aceptada',       'escuela.fp@sape.test', '1',     format($q$select count(*) from inscripciones where id = %L and estado = 'aceptada'$q$, pg_temp.id('insc')));
select pg_temp.paso('30. Sin sesión no accede a los alumnos',      null,                   'error', $q$select count(*) from alumnos$q$);

select resultado, prueba, detalle from res order by n;

rollback;
