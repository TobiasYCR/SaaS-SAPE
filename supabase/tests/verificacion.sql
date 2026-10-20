-- =====================================================================
-- SAPE · Verificación de relaciones (solo lectura)
-- Ejecutar cada consulta por separado en el SQL Editor después de seed.sql.
-- =====================================================================

-- 1. Cantidad de registros por organización
select e.nombre as escuela,
       (select count(*) from public.alumnos a       where a.escuela_id = e.id) as alumnos,
       (select count(*) from public.convenios c     where c.escuela_id = e.id) as convenios,
       (select count(*) from public.inscripciones i where i.escuela_id = e.id) as inscripciones
from public.escuelas e
order by e.nombre;

-- 2. Convenios: qué empresa eligió a qué escuela y en qué estado está
select em.razon_social as empresa, es.nombre as escuela, c.ciclo_lectivo, c.area, c.cupos, c.estado
from public.convenios c
join public.empresas em on em.id = c.empresa_id
join public.escuelas es on es.id = c.escuela_id
order by es.nombre, c.estado;

-- 3. Alumnos inscriptos: el alumno y el convenio siempre son de la misma escuela
select es.nombre as escuela, a.apellido || ', ' || a.nombre as alumno,
       em.razon_social as empresa, i.estado
from public.inscripciones i
join public.alumnos   a  on a.id  = i.alumno_id
join public.convenios c  on c.id  = i.convenio_id
join public.escuelas  es on es.id = i.escuela_id
join public.empresas  em on em.id = c.empresa_id
order by es.nombre, alumno;

-- 4. Requisitos de cada convenio y cuántos cargó cada inscripción
select c.area, r.nombre as requisito, r.tipo, r.obligatorio,
       count(d.id) as inscripciones_con_dato
from public.requisitos r
join public.convenios c on c.id = r.convenio_id
left join public.datos_inscripcion d on d.requisito_id = r.id
group by c.area, r.nombre, r.tipo, r.obligatorio, r.orden
order by c.area, r.orden;

-- 5. Último progreso registrado por pasantía en curso
select a.apellido || ', ' || a.nombre as alumno, s.fecha, s.progreso, s.proxima_fecha
from public.seguimientos s
join public.inscripciones i on i.id = s.inscripcion_id
join public.alumnos a on a.id = i.alumno_id
where s.fecha = (select max(fecha) from public.seguimientos s2 where s2.inscripcion_id = s.inscripcion_id);
