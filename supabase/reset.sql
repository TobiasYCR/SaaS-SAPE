-- =====================================================================
-- SAPE · Reset: borra toda la estructura de la app (DATOS INCLUIDOS).
-- Orden para reconstruir: reset.sql → schema.sql → seed.sql
-- No borra usuarios de Supabase Auth.
-- =====================================================================

drop trigger if exists al_crear_usuario on auth.users;

drop policy if exists "admin sube logo de su organizacion"    on storage.objects;
drop policy if exists "admin elimina logo de su organizacion" on storage.objects;
drop policy if exists "partes ven documentos del convenio"    on storage.objects;
drop policy if exists "escuela sube documentos"               on storage.objects;
drop policy if exists "escuela elimina documentos"            on storage.objects;

drop table if exists
  public.seguimientos, public.datos_inscripcion, public.inscripciones, public.requisitos,
  public.convenios, public.alumnos, public.perfiles, public.empresas, public.escuelas
cascade;

drop function if exists
  public.mi_rol(), public.mi_escuela(), public.mi_empresa(), public.es_admin(),
  public.es_parte_convenio(uuid), public.puede_ver_inscripcion(uuid),
  public.tocar_actualizado_en(), public.crear_perfil_nuevo_usuario(),
  public.validar_convenio(), public.validar_requisito(), public.validar_inscripcion(),
  public.validar_dato_inscripcion(), public.validar_seguimiento(),
  public.registrar_organizacion(text, jsonb), public.asignar_miembro(text, public.rol_usuario)
cascade;

drop type if exists
  public.rol_usuario, public.estado_convenio, public.tipo_requisito, public.estado_inscripcion
cascade;

notify pgrst, 'reload schema';
