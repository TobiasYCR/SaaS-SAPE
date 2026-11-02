-- =====================================================================
-- SAPE · Pruebas de aislamiento (RLS) y reglas de negocio
-- Ejecutar completo en el SQL Editor sobre una base recién cargada
-- (reset.sql → schema.sql → seed.sql). Devuelve una tabla OK / FALLA.
-- Crea usuarios @sape.test y modifica estados del seed: para volver al
-- estado inicial, correr de nuevo reset → schema → seed.
-- =====================================================================

delete from auth.users where email like '%@sape.test';

insert into auth.users (id, email, raw_user_meta_data) values
  ('a0000000-0000-4000-8000-000000000001', 'rioclaro@sape.test',  '{"full_name":"Admin Río Claro"}'),
  ('a0000000-0000-4000-8000-000000000002', 'losaromos@sape.test', '{"full_name":"Admin Los Aromos"}'),
  ('a0000000-0000-4000-8000-000000000003', 'pixel@sape.test',     '{"full_name":"Admin Pixel Andino"}'),
  ('a0000000-0000-4000-8000-000000000004', 'coop@sape.test',      '{"full_name":"Admin Coop Norte"}'),
  ('a0000000-0000-4000-8000-000000000005', 'libre@sape.test',     '{"full_name":"Usuario sin organización"}');

update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000001' where email = 'rioclaro@sape.test';
update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000002' where email = 'losaromos@sape.test';
update public.perfiles set rol = 'empresa_admin', empresa_id = '20000000-0000-4000-8000-000000000001' where email = 'pixel@sape.test';
update public.perfiles set rol = 'empresa_admin', empresa_id = '20000000-0000-4000-8000-000000000002' where email = 'coop@sape.test';

create temp table resultados (n serial, resultado text, prueba text, detalle text);

-- Ejecuta p_sql como el usuario indicado (rol authenticated) y registra si el
-- resultado coincide con lo esperado. p_esperado: 'ok' | 'error' | número de filas.
create function pg_temp.probar(p_prueba text, p_usuario text, p_esperado text, p_sql text) returns void
language plpgsql as $$
declare
  v_filas bigint;
  v_ok boolean;
  v_detalle text;
begin
  perform set_config('request.jwt.claim.sub', 'a0000000-0000-4000-8000-00000000000' || p_usuario, true);
  set local role authenticated;
  begin
    if p_esperado ~ '^[0-9]+$' then
      execute p_sql into v_filas;
      v_ok := v_filas = p_esperado::bigint;
      v_detalle := 'filas: ' || v_filas;
    else
      execute p_sql;
      v_ok := p_esperado = 'ok';
      v_detalle := 'sin error';
    end if;
  exception when others then
    v_ok := p_esperado = 'error';
    v_detalle := sqlerrm;
  end;
  reset role;
  insert into resultados (resultado, prueba, detalle)
  values (case when v_ok then 'OK' else 'FALLA' end, p_prueba, v_detalle);
end $$;

-- Usuarios: 1 Río Claro · 2 Los Aromos · 3 Pixel Andino · 4 Coop Norte · 5 sin organización
select pg_temp.probar('Río Claro ve solo sus 4 alumnos',                 '1', '4', 'select count(*) from alumnos');
select pg_temp.probar('Río Claro ve el directorio de 3 empresas',        '1', '3', 'select count(*) from empresas');
select pg_temp.probar('Río Claro ve solo sus 2 convenios',               '1', '2', 'select count(*) from convenios');
select pg_temp.probar('Los Aromos no ve alumnos de Río Claro',           '2', '0', $q$select count(*) from alumnos where escuela_id = '10000000-0000-4000-8000-000000000001'$q$);
select pg_temp.probar('Pixel ve el directorio de 2 escuelas',            '3', '2', 'select count(*) from escuelas');
select pg_temp.probar('Pixel ve solo los 2 alumnos con inscripción enviada', '3', '2', 'select count(*) from alumnos');
select pg_temp.probar('Pixel no ve la inscripción en borrador', '3', '0', $q$select count(*) from inscripciones where estado = 'borrador'$q$);
select pg_temp.probar('Escuela no puede iniciar un convenio',            '1', 'error',
  $q$insert into convenios (empresa_id, escuela_id, ciclo_lectivo, cupos) values ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 2027, 1)$q$);
select pg_temp.probar('Empresa se postula a una escuela',                '3', 'ok',
  $q$insert into convenios (empresa_id, escuela_id, ciclo_lectivo, cupos) values ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 2027, 2)$q$);
select pg_temp.probar('Empresa no se postula dos veces el mismo ciclo',  '3', 'error',
  $q$insert into convenios (empresa_id, escuela_id, ciclo_lectivo, cupos) values ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 2027, 1)$q$);
select pg_temp.probar('Empresa no puede aceptar su propia postulación',  '3', 'error',
  $q$update convenios set estado = 'aceptado' where ciclo_lectivo = 2027$q$);
select pg_temp.probar('Escuela acepta la postulación',                   '2', 'ok',
  $q$update convenios set estado = 'aceptado' where ciclo_lectivo = 2027$q$);
select pg_temp.probar('No se agregan requisitos a un convenio activo',   '3', 'error',
  $q$insert into requisitos (convenio_id, nombre) values ('40000000-0000-4000-8000-000000000001', 'Foto')$q$);
select pg_temp.probar('Se agregan requisitos a un convenio aceptado',    '3', 'ok',
  $q$insert into requisitos (convenio_id, nombre, tipo) values ('40000000-0000-4000-8000-000000000003', 'CV', 'archivo')$q$);
select pg_temp.probar('No se inscribe en convenio que no está activo',   '2', 'error',
  $q$insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000203')$q$);
select pg_temp.probar('No se inscribe un alumno de otra escuela',        '1', 'error',
  $q$insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000201')$q$);
select pg_temp.probar('Escuela inscribe a su alumno en convenio activo', '1', 'ok',
  $q$insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000104')$q$);
select pg_temp.probar('No se envía con requisitos obligatorios faltantes','1', 'error',
  $q$update inscripciones set estado = 'enviada' where id = '60000000-0000-4000-8000-000000000003'$q$);
select pg_temp.probar('Valida el tipo de dato del requisito (fecha)',    '1', 'error',
  $q$insert into datos_inscripcion (inscripcion_id, requisito_id, valor) values ('60000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000104', '31/02/2026')$q$);
select pg_temp.probar('La escuela no acepta inscripciones',              '1', 'error',
  $q$update inscripciones set estado = 'aceptada' where id = '60000000-0000-4000-8000-000000000002'$q$);
select pg_temp.probar('La empresa acepta la inscripción enviada',        '3', 'ok',
  $q$update inscripciones set estado = 'aceptada' where id = '60000000-0000-4000-8000-000000000002'$q$);
select pg_temp.probar('Empresa no puede inscribir alumnos',              '3', 'error',
  $q$insert into inscripciones (convenio_id, alumno_id) values ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000103')$q$);
select pg_temp.probar('Usuario no puede cambiarse el rol',               '1', 'error',
  $q$update perfiles set rol = 'empresa_admin' where id = auth.uid()$q$);
select pg_temp.probar('Seguimiento solo sobre pasantía en curso',        '3', 'error',
  $q$insert into seguimientos (inscripcion_id, progreso, observaciones) values ('60000000-0000-4000-8000-000000000002', 10, 'x')$q$);
select pg_temp.probar('Usuario libre registra su escuela',               '5', 'ok',
  $q$select registrar_organizacion('escuela', '{"nombre":"Escuela Nueva","cue":"999999999","localidad":"Salta","provincia":"Salta"}')$q$);
select pg_temp.probar('No puede registrar una segunda organización',     '5', 'error',
  $q$select registrar_organizacion('empresa', '{"razon_social":"X","cuit":"30999999999","localidad":"a","provincia":"b"}')$q$);

select resultado, prueba, detalle from resultados order by n;
