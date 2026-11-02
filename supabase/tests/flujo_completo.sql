-- =====================================================================
-- SAPE · Prueba del recorrido completo de la versión 1
-- Reproduce, con usuarios nuevos, las mismas operaciones que hacen las
-- pantallas (src/services/). Devuelve una tabla OK / FALLA.
-- Ejecutar en el SQL Editor después de schema.sql (con o sin seed.sql).
-- Crea usuarios @flujo.test y organizaciones nuevas; al inicio borra las
-- de una corrida anterior.
-- =====================================================================

delete from public.inscripciones where escuela_id in (select id from public.escuelas where cue = '111111111');
delete from auth.users where email like '%@flujo.test';
delete from public.escuelas where cue = '111111111';
delete from public.empresas where cuit = '30111111111';

insert into auth.users (id, email, raw_user_meta_data) values
  ('b0000000-0000-4000-8000-000000000001', 'escuela@flujo.test', '{"full_name":"Directora Flujo"}'),
  ('b0000000-0000-4000-8000-000000000002', 'empresa@flujo.test', '{"full_name":"RRHH Flujo"}'),
  ('b0000000-0000-4000-8000-000000000003', 'tutor@flujo.test',   '{"full_name":"Tutor Flujo"}');

create temp table resultados (n serial, resultado text, prueba text, detalle text);
create temp table ids (clave text primary key, valor uuid);
grant all on resultados, ids to authenticated;
grant usage on sequence resultados_n_seq to authenticated;

-- p_esperado: 'ok' | 'error' | número de filas. p_guardar: guarda el uuid devuelto en ids.
create function pg_temp.paso(p_prueba text, p_usuario text, p_esperado text, p_sql text, p_guardar text default null) returns void
language plpgsql as $$
declare
  v_res text;
  v_ok boolean;
  v_detalle text;
begin
  perform set_config('request.jwt.claim.sub', 'b0000000-0000-4000-8000-00000000000' || p_usuario, true);
  set local role authenticated;
  begin
    execute p_sql into v_res;
    if p_esperado ~ '^[0-9]+$' then
      v_ok := v_res = p_esperado;
      v_detalle := 'filas: ' || coalesce(v_res, 'null');
    else
      v_ok := p_esperado = 'ok';
      v_detalle := 'sin error';
    end if;
    if p_guardar is not null then
      insert into ids values (p_guardar, v_res::uuid) on conflict (clave) do update set valor = excluded.valor;
    end if;
  exception when others then
    v_ok := p_esperado = 'error';
    v_detalle := sqlerrm;
  end;
  reset role;
  insert into resultados (resultado, prueba, detalle) values (case when v_ok then 'OK' else 'FALLA' end, p_prueba, v_detalle);
end $$;

create function pg_temp.id(p_clave text) returns text language sql as $$ select valor::text from ids where clave = p_clave $$;

-- Usuarios: 1 escuela · 2 empresa · 3 tutor (se suma a la empresa)

-- Registro de organizaciones (RegistroOrganizacionView)
select pg_temp.paso('Escuela registra su organización', '1', 'ok',
  $q$select registrar_organizacion('escuela', '{"nombre":"Escuela Flujo","cue":"111111111","localidad":"Quilmes","provincia":"Buenos Aires","especialidades":["Programación"]}')$q$, 'escuela');
select pg_temp.paso('Empresa registra su organización', '2', 'ok',
  $q$select registrar_organizacion('empresa', '{"razon_social":"Empresa Flujo SA","cuit":"30111111111","localidad":"CABA","provincia":"CABA"}')$q$, 'empresa');
select pg_temp.paso('La escuela nueva no es de prueba', '1', '0',
  $q$select count(*) from escuelas where cue = '111111111' and datos_prueba$q$);
select pg_temp.paso('Empresa no puede editar datos de una escuela', '2', '0',
  $q$with u as (update escuelas set nombre = 'X' where cue = '111111111' returning 1) select count(*) from u$q$);

-- Miembros (OrganizacionView)
select pg_temp.paso('Empresa suma un tutor por email', '2', 'ok', $q$select asignar_miembro('tutor@flujo.test', 'empresa_tutor')$q$);
select pg_temp.paso('Empresa no puede sumar un rol de escuela', '2', 'error', $q$select asignar_miembro('tutor@flujo.test', 'escuela_tutor')$q$);
select pg_temp.paso('Admin ve los 2 miembros de su empresa', '2', '2', $q$select count(*) from perfiles where rol is not null$q$);

-- Alumnos (AlumnosView)
select pg_temp.paso('Escuela crea alumno A', '1', 'ok',
  format($q$with a as (insert into alumnos (escuela_id, nombre, apellido, dni, curso) values (%L, 'Ana', 'Alvarez', '46000001', 6) returning id) select id from a$q$, pg_temp.id('escuela')), 'alumnoA');
select pg_temp.paso('Escuela crea alumno B', '1', 'ok',
  format($q$with a as (insert into alumnos (escuela_id, nombre, apellido, dni, curso) values (%L, 'Bruno', 'Benitez', '46000002', 6) returning id) select id from a$q$, pg_temp.id('escuela')), 'alumnoB');
select pg_temp.paso('DNI repetido en la misma escuela', '1', 'error',
  format($q$insert into alumnos (escuela_id, nombre, apellido, dni) values (%L, 'X', 'Y', '46000001')$q$, pg_temp.id('escuela')));
select pg_temp.paso('Curso fuera de rango', '1', 'error',
  format($q$insert into alumnos (escuela_id, nombre, apellido, dni, curso) values (%L, 'X', 'Y', '46000009', 9)$q$, pg_temp.id('escuela')));
select pg_temp.paso('Escuela edita alumno', '1', '1',
  format($q$with u as (update alumnos set especialidad = 'Programación' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('alumnoA')));
select pg_temp.paso('Empresa no ve alumnos sin inscripción', '2', '0', $q$select count(*) from alumnos$q$);

-- Postulación (EscuelasView) y respuesta (ConvenioDetalleView)
select pg_temp.paso('Empresa ve la escuela en el directorio', '2', '1', $q$select count(*) from escuelas where cue = '111111111'$q$);
select pg_temp.paso('Empresa se postula', '2', 'ok',
  format($q$with c as (insert into convenios (empresa_id, escuela_id, ciclo_lectivo, cupos, area) values (%L, %L, 2027, 1, 'Soporte') returning id) select id from c$q$,
         pg_temp.id('empresa'), pg_temp.id('escuela')), 'convenio');
select pg_temp.paso('Empresa edita su propuesta', '2', '1',
  format($q$with u as (update convenios set descripcion = 'Mesa de ayuda', cupos = 1 where id = %L returning 1) select count(*) from u$q$, pg_temp.id('convenio')));
select pg_temp.paso('Escuela no puede editar la propuesta', '1', 'error',
  format($q$update convenios set cupos = 5 where id = %L$q$, pg_temp.id('convenio')));
select pg_temp.paso('Escuela acepta la postulación', '1', '1',
  format($q$with u as (update convenios set estado = 'aceptado' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('convenio')));

-- Requisitos (ConvenioDetalleView)
select pg_temp.paso('Empresa agrega requisito archivo', '2', 'ok',
  format($q$with r as (insert into requisitos (convenio_id, nombre, tipo, obligatorio, orden) values (%L, 'DNI escaneado', 'archivo', true, 1) returning id) select id from r$q$, pg_temp.id('convenio')), 'reqArchivo');
select pg_temp.paso('Escuela agrega requisito si/no', '1', 'ok',
  format($q$with r as (insert into requisitos (convenio_id, nombre, tipo, obligatorio, orden) values (%L, 'Autorización', 'si_no', true, 2) returning id) select id from r$q$, pg_temp.id('convenio')), 'reqSiNo');
select pg_temp.paso('Escuela agrega requisito opcional', '1', 'ok',
  format($q$with r as (insert into requisitos (convenio_id, nombre, tipo, obligatorio, orden) values (%L, 'Comentario', 'texto', false, 3) returning id) select id from r$q$, pg_temp.id('convenio')), 'reqTexto');
select pg_temp.paso('Edita un requisito', '2', '1',
  format($q$with u as (update requisitos set descripcion = 'Frente y dorso' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('reqArchivo')));
select pg_temp.paso('Tutor no puede crear requisitos', '3', 'error',
  format($q$insert into requisitos (convenio_id, nombre) values (%L, 'X')$q$, pg_temp.id('convenio')));
select pg_temp.paso('Escuela activa el convenio', '1', '1',
  format($q$with u as (update convenios set estado = 'activo' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('convenio')));
select pg_temp.paso('Requisitos quedan fijos al activar', '2', 'error',
  format($q$delete from requisitos where id = %L$q$, pg_temp.id('reqTexto')));

-- Inscripción y datos (InscripcionDetalleView)
select pg_temp.paso('Escuela inscribe al alumno A', '1', 'ok',
  format($q$with i as (insert into inscripciones (convenio_id, alumno_id) values (%L, %L) returning id) select id from i$q$, pg_temp.id('convenio'), pg_temp.id('alumnoA')), 'inscA');
select pg_temp.paso('Escuela inscribe al alumno B', '1', 'ok',
  format($q$with i as (insert into inscripciones (convenio_id, alumno_id) values (%L, %L) returning id) select id from i$q$, pg_temp.id('convenio'), pg_temp.id('alumnoB')), 'inscB');
select pg_temp.paso('Carga dato (upsert)', '1', 'ok',
  format($q$insert into datos_inscripcion (inscripcion_id, requisito_id, valor) values (%L, %L, 'no') on conflict (inscripcion_id, requisito_id) do update set valor = excluded.valor, archivo_ruta = excluded.archivo_ruta returning 1$q$, pg_temp.id('inscA'), pg_temp.id('reqSiNo')));
select pg_temp.paso('Modifica dato (upsert)', '1', 'ok',
  format($q$insert into datos_inscripcion (inscripcion_id, requisito_id, valor) values (%L, %L, 'si') on conflict (inscripcion_id, requisito_id) do update set valor = excluded.valor, archivo_ruta = excluded.archivo_ruta returning 1$q$, pg_temp.id('inscA'), pg_temp.id('reqSiNo')));
select pg_temp.paso('Upsert dejó un solo valor', '1', '1',
  format($q$select count(*) from datos_inscripcion where inscripcion_id = %L and valor = 'si'$q$, pg_temp.id('inscA')));
select pg_temp.paso('No envía sin el archivo obligatorio', '1', 'error',
  format($q$update inscripciones set estado = 'enviada' where id = %L$q$, pg_temp.id('inscA')));
select pg_temp.paso('Carga archivo', '1', 'ok',
  format($q$insert into datos_inscripcion (inscripcion_id, requisito_id, archivo_ruta) values (%L, %L, 'c/i/dni.pdf') on conflict (inscripcion_id, requisito_id) do update set valor = excluded.valor, archivo_ruta = excluded.archivo_ruta returning 1$q$, pg_temp.id('inscA'), pg_temp.id('reqArchivo')));
select pg_temp.paso('Envía la inscripción completa', '1', '1',
  format($q$with u as (update inscripciones set estado = 'enviada' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('inscA')));
select pg_temp.paso('Datos quedan fijos al enviar', '1', '0',
  format($q$with u as (update datos_inscripcion set valor = 'no' where inscripcion_id = %L returning 1) select count(*) from u$q$, pg_temp.id('inscA')));
select pg_temp.paso('Empresa no ve inscripciones en borrador', '2', '1',
  format($q$select count(*) from inscripciones where convenio_id = %L$q$, pg_temp.id('convenio')));
select pg_temp.paso('Empresa ve solo al alumno enviado (no al borrador)', '2', '1', $q$select count(*) from alumnos$q$);
select pg_temp.paso('Tutor no puede aceptar inscripciones', '3', '0',
  format($q$with u as (update inscripciones set estado = 'aceptada' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('inscA')));
select pg_temp.paso('Empresa acepta la inscripción', '2', '1',
  format($q$with u as (update inscripciones set estado = 'aceptada' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('inscA')));
select pg_temp.paso('Empresa inicia la pasantía', '2', '1',
  format($q$with u as (update inscripciones set estado = 'en_curso', fecha_inicio = '2027-03-01', horas_totales = 80 where id = %L returning 1) select count(*) from u$q$, pg_temp.id('inscA')));

-- Seguimientos (InscripcionDetalleView / SeguimientosView)
select pg_temp.paso('Tutor de empresa registra seguimiento', '3', 'ok',
  format($q$with s as (insert into seguimientos (inscripcion_id, fecha, progreso, observaciones, proxima_fecha) values (%L, '2027-03-15', 20, 'Buen inicio', '2027-04-15') returning id) select id from s$q$, pg_temp.id('inscA')), 'seg');
select pg_temp.paso('Escuela ve el seguimiento de la empresa', '1', '1',
  format($q$select count(*) from seguimientos where inscripcion_id = %L$q$, pg_temp.id('inscA')));
select pg_temp.paso('Escuela no borra seguimiento ajeno', '1', '0',
  format($q$with d as (delete from seguimientos where id = %L returning 1) select count(*) from d$q$, pg_temp.id('seg')));
select pg_temp.paso('Progreso fuera de rango', '3', 'error',
  format($q$insert into seguimientos (inscripcion_id, progreso, observaciones) values (%L, 150, 'x')$q$, pg_temp.id('inscA')));

-- Historial: bajas en lugar de borrados
select pg_temp.paso('No se borra un alumno con inscripciones', '1', 'error',
  format($q$delete from alumnos where id = %L$q$, pg_temp.id('alumnoA')));
select pg_temp.paso('Se da de baja (activo = false)', '1', '1',
  format($q$with u as (update alumnos set activo = false where id = %L returning 1) select count(*) from u$q$, pg_temp.id('alumnoA')));
select pg_temp.paso('Elimina un borrador', '1', '1',
  format($q$with d as (delete from inscripciones where id = %L returning 1) select count(*) from d$q$, pg_temp.id('inscB')));
select pg_temp.paso('Borra un alumno sin inscripciones', '1', '1',
  format($q$with d as (delete from alumnos where id = %L returning 1) select count(*) from d$q$, pg_temp.id('alumnoB')));
select pg_temp.paso('Finaliza la pasantía', '1', '1',
  format($q$with u as (update inscripciones set estado = 'finalizada' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('inscA')));
select pg_temp.paso('Finaliza el convenio', '2', '1',
  format($q$with u as (update convenios set estado = 'finalizado' where id = %L returning 1) select count(*) from u$q$, pg_temp.id('convenio')));
select pg_temp.paso('Historial conservado (inscripción + seguimiento)', '1', '1',
  format($q$select count(*) from inscripciones i join seguimientos s on s.inscripcion_id = i.id where i.id = %L$q$, pg_temp.id('inscA')));

select resultado, prueba, detalle from resultados order by n;
