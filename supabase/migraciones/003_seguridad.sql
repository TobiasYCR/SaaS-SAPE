-- =====================================================================
-- SAPE · Migración 003: ajustes de seguridad (avisos del Security Advisor)
-- Aplica sobre una base con schema.sql o con la migración 002.
-- =====================================================================

-- 1. search_path fijo (lint 0011 function_search_path_mutable)
alter function public.tocar_actualizado_en() set search_path = '';

-- 2. Las funciones de trigger no se exponen como RPC (lint 0029).
--    Los triggers siguen ejecutándose: el permiso EXECUTE no se verifica al dispararlos.
revoke execute on function
  public.tocar_actualizado_en(), public.crear_perfil_nuevo_usuario(),
  public.validar_convenio(), public.validar_requisito(), public.validar_inscripcion(),
  public.validar_dato_inscripcion(), public.validar_seguimiento()
from public, anon, authenticated;

-- Se mantienen ejecutables a propósito:
--   mi_rol, mi_escuela, mi_empresa, es_admin, es_parte_convenio, puede_ver_inscripcion → usadas por las políticas RLS
--   registrar_organizacion, asignar_miembro → RPC de la aplicación (validan rol internamente)

notify pgrst, 'reload schema';
