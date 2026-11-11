// Lógica compartida del módulo Alumnos (listado y detalle)
import { actualizarAlumno, crearAlumno, darDeBajaAlumno, eliminarAlumno, reactivarAlumno } from '../../services/alumnosService'
import { limpiarVacios } from '../../utils/validaciones'

const CAMPOS = ['nombre', 'apellido', 'dni', 'fecha_nacimiento', 'curso', 'division', 'especialidad', 'email', 'telefono', 'responsable_nombre', 'responsable_telefono']

export const formularioVacio = () => Object.fromEntries(CAMPOS.map((c) => [c, '']))
export const aFormulario = (alumno) => Object.fromEntries(CAMPOS.map((c) => [c, alumno?.[c] ?? '']))
export const nombreCompleto = (a) => `${a.apellido}, ${a.nombre}`
export const cantidadInscripciones = (a) => a.inscripciones?.[0]?.count ?? 0

function aRegistro(formulario) {
  const datos = limpiarVacios(formulario)
  datos.curso = datos.curso ? Number(datos.curso) : null
  return datos
}

// Alta o modificación. op: useOperacion(). Devuelve el alumno guardado o undefined.
export function guardarAlumno(op, { id = null, escuelaId, formulario }) {
  const datos = aRegistro(formulario)
  const nombre = nombreCompleto(datos)
  return id
    ? op.ejecutar(() => actualizarAlumno(id, datos), `Se modificaron los datos de ${nombre}.`)
    : op.ejecutar(() => crearAlumno({ ...datos, escuela_id: escuelaId }), `${nombre} se agregó a la escuela.`)
}

// Con inscripciones: baja lógica (conserva el historial). Sin inscripciones: eliminación definitiva.
// Siempre pide confirmación. Devuelve 'baja' | 'eliminado' | null (cancelado o error).
export async function quitarAlumno(op, alumno, inscripciones) {
  const nombre = nombreCompleto(alumno)
  if (inscripciones > 0) {
    if (!window.confirm(`${nombre} tiene ${inscripciones} inscripción(es). Se va a dar de baja: queda en el historial y se puede reactivar. ¿Continuar?`)) return null
    return (await op.ejecutar(() => darDeBajaAlumno(alumno.id), `${nombre} quedó dado de baja.`)) ? 'baja' : null
  }
  if (!window.confirm(`¿Eliminar definitivamente a ${nombre}? Esta acción no se puede deshacer.`)) return null
  return (await op.ejecutar(() => eliminarAlumno(alumno.id).then(() => true), `${nombre} se eliminó.`)) ? 'eliminado' : null
}

export function reactivar(op, alumno) {
  return op.ejecutar(() => reactivarAlumno(alumno.id), `${nombreCompleto(alumno)} volvió a estar activo.`)
}
