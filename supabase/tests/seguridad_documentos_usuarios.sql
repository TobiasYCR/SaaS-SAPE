-- =====================================================================
-- SAPE - Seguridad de documentos y gestion de usuarios
-- Prueba RLS con dos escuelas y una empresa, y termina con ROLLBACK.
-- El objeto de Storage es solo metadata transaccional para probar la policy;
-- no se crea ni se elimina ningun archivo fisico.
-- =====================================================================

begin;

create temp table resultados_seguridad (
  n serial,
  resultado text,
  prueba text,
  detalle text
);
grant all on resultados_seguridad to authenticated;
grant usage on sequence resultados_seguridad_n_seq to authenticated;

create function pg_temp.probar_seguridad(
  p_usuario uuid,
  p_prueba text,
  p_esperado text,
  p_sql text
) returns void
language plpgsql as $$
declare
  v_resultado text;
  v_ok boolean;
  v_detalle text;
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_usuario::text, ''), true);
  perform set_config('request.jwt.claims', json_build_object('sub', p_usuario, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin
    execute p_sql into v_resultado;
    v_ok := p_esperado = 'ok' or coalesce(v_resultado, '') = p_esperado;
    v_detalle := 'obtenido=' || coalesce(v_resultado, 'null');
  exception when others then
    v_ok := p_esperado = 'error';
    v_detalle := sqlerrm;
  end;
  reset role;

  insert into resultados_seguridad(resultado, prueba, detalle)
  values (case when v_ok then 'OK' else 'FALLA' end, p_prueba, v_detalle);
end $$;

-- Organizaciones aisladas.
insert into public.escuelas(id, nombre, cue, localidad, provincia) values
  ('e1000000-0000-4000-8000-000000000001', 'Escuela Seguridad A', '911111111', 'Salta', 'Salta'),
  ('e1000000-0000-4000-8000-000000000002', 'Escuela Seguridad B', '922222222', 'Salta', 'Salta');
insert into public.empresas(id, razon_social, cuit, localidad, provincia) values
  ('e2000000-0000-4000-8000-000000000001', 'Empresa Seguridad', '30911111111', 'Salta', 'Salta');

insert into auth.users(id, email, aud, role, raw_user_meta_data) values
  ('e3000000-0000-4000-8000-000000000001', 'admin-a@seguridad.test', 'authenticated', 'authenticated', '{}'),
  ('e3000000-0000-4000-8000-000000000002', 'tutor-a@seguridad.test', 'authenticated', 'authenticated', '{}'),
  ('e3000000-0000-4000-8000-000000000003', 'admin-b@seguridad.test', 'authenticated', 'authenticated', '{}'),
  ('e3000000-0000-4000-8000-000000000004', 'empresa@seguridad.test', 'authenticated', 'authenticated', '{}');

update public.perfiles set rol = 'escuela_admin', escuela_id = 'e1000000-0000-4000-8000-000000000001'
where id = 'e3000000-0000-4000-8000-000000000001';
update public.perfiles set rol = 'escuela_tutor', escuela_id = 'e1000000-0000-4000-8000-000000000001'
where id = 'e3000000-0000-4000-8000-000000000002';
update public.perfiles set rol = 'escuela_admin', escuela_id = 'e1000000-0000-4000-8000-000000000002'
where id = 'e3000000-0000-4000-8000-000000000003';
update public.perfiles set rol = 'empresa_admin', empresa_id = 'e2000000-0000-4000-8000-000000000001'
where id = 'e3000000-0000-4000-8000-000000000004';

insert into public.convenios(id, empresa_id, escuela_id, ciclo_lectivo, area, cupos, estado, creado_por)
values (
  'e4000000-0000-4000-8000-000000000001',
  'e2000000-0000-4000-8000-000000000001',
  'e1000000-0000-4000-8000-000000000001',
  2027, 'Seguridad', 1, 'activo', 'e3000000-0000-4000-8000-000000000004'
);
insert into public.alumnos(id, escuela_id, nombre, apellido, dni)
values ('e5000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', 'Ana', 'Seguridad', '49999991');

-- Metadata temporal: permite probar SELECT/RLS de Storage sin archivo fisico.
insert into storage.objects(bucket_id, name)
values ('documentos', 'e4000000-0000-4000-8000-000000000001/prueba/documento.pdf');

-- Las dos partes y sus tutores pueden leer; una organizacion ajena no.
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000001', 'Escuela parte ve su documento', '1',
  $$select count(*) from storage.objects where name = 'e4000000-0000-4000-8000-000000000001/prueba/documento.pdf'$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000002', 'Tutor de la escuela ve el documento', '1',
  $$select count(*) from storage.objects where name = 'e4000000-0000-4000-8000-000000000001/prueba/documento.pdf'$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000004', 'Empresa parte ve el documento', '1',
  $$select count(*) from storage.objects where name = 'e4000000-0000-4000-8000-000000000001/prueba/documento.pdf'$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000003', 'Otra escuela no ve el documento', '0',
  $$select count(*) from storage.objects where name = 'e4000000-0000-4000-8000-000000000001/prueba/documento.pdf'$$
);

-- Solo el administrador de la misma organizacion gestiona miembros.
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000001', 'Admin cambia tutor a administrador', 'ok',
  $$select public.actualizar_miembro('e3000000-0000-4000-8000-000000000002', 'escuela_admin', true)$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000001', 'Rol actualizado', 'escuela_admin',
  $$select rol::text from public.perfiles where id = 'e3000000-0000-4000-8000-000000000002'$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000001', 'Admin desactiva miembro', 'ok',
  $$select public.actualizar_miembro('e3000000-0000-4000-8000-000000000002', 'escuela_tutor', false)$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000002', 'Desactivado no ve alumnos', '0',
  $$select count(*) from public.alumnos where id = 'e5000000-0000-4000-8000-000000000001'$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000001', 'Admin reactiva miembro', 'ok',
  $$select public.actualizar_miembro('e3000000-0000-4000-8000-000000000002', 'escuela_tutor', true)$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000002', 'Tutor reactivado ve alumnos', '1',
  $$select count(*) from public.alumnos where id = 'e5000000-0000-4000-8000-000000000001'$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000002', 'Tutor no gestiona usuarios', 'error',
  $$select public.actualizar_miembro('e3000000-0000-4000-8000-000000000001', 'escuela_tutor', true)$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000003', 'Admin ajeno no gestiona usuarios', 'error',
  $$select public.actualizar_miembro('e3000000-0000-4000-8000-000000000002', 'escuela_tutor', true)$$
);
select pg_temp.probar_seguridad(
  'e3000000-0000-4000-8000-000000000001', 'Admin no modifica su propia cuenta', 'error',
  $$select public.actualizar_miembro('e3000000-0000-4000-8000-000000000001', 'escuela_tutor', false)$$
);

select resultado, prueba, detalle from resultados_seguridad order by n;

rollback;
