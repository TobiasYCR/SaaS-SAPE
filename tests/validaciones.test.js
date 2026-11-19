import test from 'node:test'
import assert from 'node:assert/strict'
import {
  requeridos,
  textoBusqueda,
  validarAlumno,
  validarArchivo,
  esContrasenaValida,
  validarConvenio,
  validarInscripcion,
  validarSeguimiento,
  validarValorRequisito,
} from '../src/utils/validaciones.js'

test('campos obligatorios vacios muestran un error claro', () => {
  assert.deepEqual(requeridos({ nombre: '  ', dni: null }, { nombre: 'El nombre', dni: 'El DNI' }), {
    nombre: 'El nombre es obligatorio.',
    dni: 'El DNI es obligatorio.',
  })
})

test('alumno rechaza formatos y rangos invalidos', () => {
  const errores = validarAlumno({
    nombre: 'Ana', apellido: 'Prueba', dni: '12A',
    curso: 9, fecha_nacimiento: '2999-01-01', email: 'sin-arroba',
  })
  for (const campo of ['dni', 'curso', 'fecha_nacimiento', 'email']) {
    assert.ok(errores[campo], `Falta validar ${campo}`)
  }
})

test('convenio rechaza cupos y fechas invalidos', () => {
  const errores = validarConvenio({
    ciclo_lectivo: 2019, cupos: 0, area: 'Sistemas',
    fecha_inicio: '2027-04-10', fecha_fin: '2027-04-01',
  })
  for (const campo of ['ciclo_lectivo', 'cupos', 'fecha_fin']) assert.ok(errores[campo])
})

test('requisitos rechazan valores con formato incorrecto', () => {
  assert.equal(validarValorRequisito('numero', '12x'), 'Debe ser un número.')
  assert.equal(validarValorRequisito('fecha', 'fecha-invalida'), 'Fecha inválida.')
  assert.equal(validarValorRequisito('si_no', 'quizas'), 'Elegí sí o no.')
  assert.equal(validarValorRequisito('numero', '12,5'), '')
})

test('archivos limitan tipo y tamano', () => {
  assert.equal(validarArchivo({ type: 'application/zip', size: 20 }), 'Solo PDF, JPG o PNG.')
  assert.equal(validarArchivo({ type: 'application/pdf', size: 10 * 1024 * 1024 + 1 }), 'El archivo no puede superar los 10 MB.')
  assert.equal(validarArchivo({ type: 'image/png', size: 1024 }), '')
})

test('seguimientos e inscripciones validan rangos y fechas', () => {
  const seguimiento = validarSeguimiento({ fecha: '2027-05-10', progreso: 101, observaciones: '', proxima_fecha: '2027-05-01' })
  assert.ok(seguimiento.progreso)
  assert.ok(seguimiento.observaciones)
  assert.ok(seguimiento.proxima_fecha)

  const inscripcion = validarInscripcion({ fecha_inicio: '2027-05-10', fecha_fin: '2027-05-01', horas_totales: -2 })
  assert.ok(inscripcion.fecha_fin)
  assert.ok(inscripcion.horas_totales)
})

test('busqueda neutraliza caracteres de filtros PostgREST', () => {
  assert.equal(textoBusqueda('Ana,(*)%\\'), 'Ana')
})

test('contraseña exige exactamente ocho caracteres alfanuméricos', () => {
  assert.equal(esContrasenaValida('Ab12cd34'), true)
  assert.equal(esContrasenaValida('Ab12-cd3'), false)
  assert.equal(esContrasenaValida('Ab123'), false)
  assert.equal(esContrasenaValida('Ab123456'), true)
})
