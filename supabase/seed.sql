-- =====================================================================
-- SAPE · Datos ficticios de prueba
-- Ejecutar en el SQL Editor después de schema.sql.
-- Todos los nombres, CUE, CUIT y DNI son inventados.
-- Las organizaciones se marcan con datos_prueba = true: la app muestra la
-- etiqueta "Datos de prueba" en ellas y en todo lo que les pertenece.
--
-- IDs fijos para poder seguir las relaciones a mano:
--   escuelas       1000…0001  Escuela Técnica Río Claro
--                  1000…0002  Instituto Secundario Los Aromos
--   empresas       2000…0001  Pixel Andino S.R.L.
--                  2000…0002  Cooperativa Norte Ltda.
--                  2000…0003  Grupo Delta S.A.
--   alumnos        3000…01xx  Río Claro  |  3000…02xx  Los Aromos
--   convenios      4000…000x
--   requisitos     5000…0xyy  (x = convenio)
--   inscripciones  6000…000x
-- =====================================================================

insert into public.escuelas (id, nombre, cue, modalidad, especialidades, descripcion, direccion, localidad, provincia, email, telefono, datos_prueba) values
  ('10000000-0000-4000-8000-000000000001', 'Escuela Técnica Río Claro', '060000101', 'Técnica',
   '{"Programación","Electrónica"}', 'Escuela técnica de gestión pública con orientación en informática.',
   'Av. Siempre Viva 1200', 'Lanús', 'Buenos Aires', 'contacto@rioclaro.edu.test', '11 4000-0001', true),
  ('10000000-0000-4000-8000-000000000002', 'Instituto Secundario Los Aromos', '140000202', 'Orientada',
   '{"Economía y Administración","Comunicación"}', 'Secundaria orientada de gestión privada.',
   'Calle Falsa 456', 'Córdoba', 'Córdoba', 'secretaria@losaromos.edu.test', '351 400-0002', true);

insert into public.empresas (id, razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion, localidad, provincia, email, telefono, sitio_web, datos_prueba) values
  ('20000000-0000-4000-8000-000000000001', 'Pixel Andino S.R.L.', 'Pixel Andino', '30700000011', 'Software',
   'Estudio de desarrollo web y diseño UX.', 'Av. Corrientes 1000', 'CABA', 'Buenos Aires',
   'rrhh@pixelandino.test', '11 5000-0001', 'https://pixelandino.test', true),
  ('20000000-0000-4000-8000-000000000002', 'Cooperativa Norte Ltda.', 'Coop. Norte', '30700000022', 'Servicios IT',
   'Cooperativa de soporte técnico y redes.', 'Bv. Oroño 300', 'Rosario', 'Santa Fe',
   'pasantias@coopnorte.test', '341 500-0002', null, true),
  ('20000000-0000-4000-8000-000000000003', 'Grupo Delta S.A.', 'Delta', '30700000033', 'Contabilidad',
   'Estudio contable y administrativo.', 'San Martín 50', 'Mendoza', 'Mendoza',
   'info@grupodelta.test', '261 500-0003', null, true);

insert into public.alumnos (id, escuela_id, nombre, apellido, dni, fecha_nacimiento, curso, division, especialidad, email, responsable_nombre, responsable_telefono) values
  -- Escuela Técnica Río Claro
  ('30000000-0000-4000-8000-000000000101', '10000000-0000-4000-8000-000000000001', 'Sofía',    'Martínez',  '45000101', '2008-03-14', 6, 'A', 'Programación', 'sofia.m@alumnos.test',  'Laura Martínez',  '11 6000-0101'),
  ('30000000-0000-4000-8000-000000000102', '10000000-0000-4000-8000-000000000001', 'Tomás',    'Ríos',      '45000102', '2008-07-02', 6, 'A', 'Programación', 'tomas.r@alumnos.test',  'Jorge Ríos',      '11 6000-0102'),
  ('30000000-0000-4000-8000-000000000103', '10000000-0000-4000-8000-000000000001', 'Lucía',    'Fernández', '45000103', '2008-11-20', 6, 'B', 'Electrónica',  'lucia.f@alumnos.test',  'Marta Fernández', '11 6000-0103'),
  ('30000000-0000-4000-8000-000000000104', '10000000-0000-4000-8000-000000000001', 'Marcos',   'Díaz',      '45000104', '2009-01-30', 5, 'A', 'Programación', null,                    'Pedro Díaz',      '11 6000-0104'),
  -- Instituto Secundario Los Aromos
  ('30000000-0000-4000-8000-000000000201', '10000000-0000-4000-8000-000000000002', 'Valentina','Paz',       '45000201', '2008-05-05', 5, 'U', 'Comunicación', 'vale.p@alumnos.test',   'Ana Paz',         '351 600-0201'),
  ('30000000-0000-4000-8000-000000000202', '10000000-0000-4000-8000-000000000002', 'Nicolás',  'Acosta',    '45000202', '2008-09-17', 5, 'U', 'Economía y Administración', 'nico.a@alumnos.test', 'Raúl Acosta', '351 600-0202'),
  ('30000000-0000-4000-8000-000000000203', '10000000-0000-4000-8000-000000000002', 'Camila',   'Suárez',    '45000203', '2008-12-01', 5, 'U', 'Comunicación', null,                    'Silvia Suárez',   '351 600-0203'),
  -- Mismo DNI que un alumno de la otra escuela: permitido (unique es por escuela)
  ('30000000-0000-4000-8000-000000000204', '10000000-0000-4000-8000-000000000002', 'Joaquín',  'Ledesma',   '45000101', '2009-04-22', 4, 'U', 'Economía y Administración', null, 'Inés Ledesma', '351 600-0204');

-- Convenios: cubren todos los estados del flujo
insert into public.convenios (id, empresa_id, escuela_id, ciclo_lectivo, area, descripcion, cupos, fecha_inicio, fecha_fin, estado, respondido_en) values
  -- Pixel Andino → Río Claro: activo, con alumnos inscriptos
  ('40000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   2026, 'Desarrollo web', 'Pasantía en el equipo de frontend.', 3, '2026-08-01', '2026-11-30', 'activo', '2026-06-10'),
  -- Cooperativa Norte → Río Claro: recién postulado, la escuela todavía no respondió
  ('40000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
   2026, 'Soporte técnico', 'Mesa de ayuda y armado de equipos.', 2, '2026-09-01', '2026-12-15', 'postulado', null),
  -- Pixel Andino → Los Aromos: aceptado, configurando requisitos
  ('40000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002',
   2026, 'Diseño UX', 'Investigación con usuarios y prototipado.', 2, '2026-10-01', '2026-12-15', 'aceptado', '2026-09-15'),
  -- Grupo Delta → Los Aromos: rechazado
  ('40000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002',
   2026, 'Administración contable', 'Carga de comprobantes.', 1, null, null, 'rechazado', '2026-07-20'),
  -- Cooperativa Norte → Los Aromos: activo, con alumnos inscriptos
  ('40000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002',
   2026, 'Comunicación institucional', 'Redes sociales y newsletter de la cooperativa.', 2, '2026-08-15', '2026-11-30', 'activo', '2026-07-01');

insert into public.requisitos (id, convenio_id, nombre, descripcion, tipo, obligatorio, orden) values
  -- Convenio 1 (Pixel Andino ↔ Río Claro)
  ('50000000-0000-4000-8000-000000000101', '40000000-0000-4000-8000-000000000001', 'DNI escaneado',               'Frente y dorso en un PDF',           'archivo', true,  1),
  ('50000000-0000-4000-8000-000000000102', '40000000-0000-4000-8000-000000000001', 'Certificado médico',          'Apto físico vigente',                 'archivo', true,  2),
  ('50000000-0000-4000-8000-000000000103', '40000000-0000-4000-8000-000000000001', 'Autorización del responsable','Firmada por madre, padre o tutor',    'si_no',   true,  3),
  ('50000000-0000-4000-8000-000000000104', '40000000-0000-4000-8000-000000000001', 'Alta en seguro escolar',      'Fecha de alta',                       'fecha',   true,  4),
  ('50000000-0000-4000-8000-000000000105', '40000000-0000-4000-8000-000000000001', 'Conocimientos previos',       'Lenguajes o herramientas que maneja', 'texto',   false, 5),
  -- Convenio 3 (Pixel Andino ↔ Los Aromos), todavía en configuración
  ('50000000-0000-4000-8000-000000000301', '40000000-0000-4000-8000-000000000003', 'Portfolio',                   'Enlace o PDF con trabajos',           'texto',   false, 1),
  -- Convenio 5 (Cooperativa Norte ↔ Los Aromos)
  ('50000000-0000-4000-8000-000000000501', '40000000-0000-4000-8000-000000000005', 'Autorización del responsable','Firmada por madre, padre o tutor',    'si_no',   true,  1),
  ('50000000-0000-4000-8000-000000000502', '40000000-0000-4000-8000-000000000005', 'Horas disponibles por semana', null,                                'numero',  true,  2);

-- escuela_id se completa solo (trigger) a partir del convenio
insert into public.inscripciones (id, convenio_id, alumno_id, estado, fecha_inicio, fecha_fin, horas_totales, observaciones) values
  ('60000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000101', 'en_curso', '2026-08-01', '2026-11-30', 120, null),
  ('60000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000102', 'enviada',  null, null, null, 'Esperando respuesta de la empresa'),
  ('60000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000103', 'borrador', null, null, null, 'Falta certificado médico'),
  ('60000000-0000-4000-8000-000000000004', '40000000-0000-4000-8000-000000000005', '30000000-0000-4000-8000-000000000201', 'en_curso', '2026-08-15', '2026-11-30', 90, null),
  ('60000000-0000-4000-8000-000000000005', '40000000-0000-4000-8000-000000000005', '30000000-0000-4000-8000-000000000202', 'aceptada', '2026-11-01', '2026-11-30', 40, null);

-- convenio_id se completa solo (trigger) a partir de la inscripción
insert into public.datos_inscripcion (inscripcion_id, requisito_id, valor, archivo_ruta) values
  -- Sofía (en curso): completo
  ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000101', null, '40000000-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000001/dni.pdf'),
  ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000102', null, '40000000-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000001/certificado.pdf'),
  ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000103', 'si', null),
  ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000104', '2026-07-25', null),
  ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000105', 'HTML, CSS, JavaScript', null),
  -- Tomás (enviada): obligatorios completos
  ('60000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000101', null, '40000000-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000002/dni.pdf'),
  ('60000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000102', null, '40000000-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000002/certificado.pdf'),
  ('60000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000103', 'si', null),
  ('60000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000104', '2026-09-30', null),
  -- Lucía (borrador): incompleto a propósito
  ('60000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000101', null, '40000000-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000003/dni.pdf'),
  -- Valentina (en curso)
  ('60000000-0000-4000-8000-000000000004', '50000000-0000-4000-8000-000000000501', 'si', null),
  ('60000000-0000-4000-8000-000000000004', '50000000-0000-4000-8000-000000000502', '12', null),
  -- Nicolás (aceptada)
  ('60000000-0000-4000-8000-000000000005', '50000000-0000-4000-8000-000000000501', 'si', null),
  ('60000000-0000-4000-8000-000000000005', '50000000-0000-4000-8000-000000000502', '10', null);

insert into public.seguimientos (inscripcion_id, fecha, progreso, observaciones, proxima_fecha) values
  ('60000000-0000-4000-8000-000000000001', '2026-08-29', 25, 'Se integró al equipo. Completó la inducción.',          '2026-09-26'),
  ('60000000-0000-4000-8000-000000000001', '2026-09-26', 50, 'Maqueta la landing del cliente con supervisión.',       '2026-10-24'),
  ('60000000-0000-4000-8000-000000000001', '2026-10-17', 75, 'Trabaja de forma autónoma en componentes simples.',     '2026-11-14'),
  ('60000000-0000-4000-8000-000000000004', '2026-09-12', 40, 'Publica contenidos semanales con revisión del tutor.',  '2026-10-10'),
  ('60000000-0000-4000-8000-000000000004', '2026-10-10', 70, 'Propuso un calendario editorial que se aprobó.',        '2026-11-07');

-- ---------------------------------------------------------------------
-- Vincular usuarios de prueba (crearlos antes desde la app o desde
-- Authentication → Users). Descomentar y ajustar los emails.
-- ---------------------------------------------------------------------
-- update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000001' where email = 'rioclaro@test.com';
-- update public.perfiles set rol = 'escuela_admin', escuela_id = '10000000-0000-4000-8000-000000000002' where email = 'losaromos@test.com';
-- update public.perfiles set rol = 'empresa_admin', empresa_id = '20000000-0000-4000-8000-000000000001' where email = 'pixel@test.com';
-- update public.perfiles set rol = 'empresa_admin', empresa_id = '20000000-0000-4000-8000-000000000002' where email = 'coopnorte@test.com';
