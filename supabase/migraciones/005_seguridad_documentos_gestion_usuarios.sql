-- =====================================================================
-- SAPE - Migracion 005: documentos privados y gestion de miembros
-- =====================================================================

-- Solo las organizaciones que participan del convenio pueden leer sus
-- archivos privados. Conocer el UUID o la ruta ya no concede acceso.
drop policy if exists "partes ven documentos del convenio" on storage.objects;
create policy "partes ven documentos del convenio" on storage.objects
  for select to authenticated using (
    bucket_id = 'documentos'
    and exists (
      select 1 from public.convenios c
      where c.id::text = (storage.foldername(name))[1]
        and (c.escuela_id = (select public.mi_escuela()) or c.empresa_id = (select public.mi_empresa()))
    )
  );

-- El administrador puede cambiar el rol o revocar/restablecer el acceso de
-- otro miembro de su organizacion. La cuenta propia queda protegida.
create or replace function public.actualizar_miembro(
  p_usuario uuid,
  p_rol public.rol_usuario,
  p_activo boolean
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_rol public.rol_usuario := public.mi_rol();
begin
  if auth.uid() is null then raise exception 'Sesion requerida'; end if;
  if p_usuario = auth.uid() then raise exception 'No podes modificar tu propia cuenta'; end if;

  if v_rol = 'escuela_admin' and p_rol in ('escuela_admin', 'escuela_tutor') then
    update public.perfiles
       set rol = p_rol, activo = p_activo
     where id = p_usuario
       and escuela_id = public.mi_escuela()
       and empresa_id is null;
  elsif v_rol = 'empresa_admin' and p_rol in ('empresa_admin', 'empresa_tutor') then
    update public.perfiles
       set rol = p_rol, activo = p_activo
     where id = p_usuario
       and empresa_id = public.mi_empresa()
       and escuela_id is null;
  else
    raise exception 'No tenes permiso para asignar el rol %', p_rol;
  end if;

  if not found then
    raise exception 'El usuario no pertenece a tu organizacion';
  end if;
end $$;

revoke all on function public.actualizar_miembro(uuid, public.rol_usuario, boolean) from public, anon;
grant execute on function public.actualizar_miembro(uuid, public.rol_usuario, boolean) to authenticated;

notify pgrst, 'reload schema';
