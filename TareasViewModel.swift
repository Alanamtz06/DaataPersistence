// MARK: - TareasViewModel.swift
// Capa ViewModel del patrón MVVM.
// Coordina la UI con el servicio de red, gestiona estados de carga
// y expone datos listos para ser consumidos por las vistas SwiftUI.

import Foundation
import Combine

// MARK: - TareasViewModel

/// Gestiona el estado de la pantalla principal de tareas.
/// Es `@MainActor` para garantizar que todas las actualizaciones de UI
/// ocurran en el hilo principal sin necesidad de `DispatchQueue.main`.
@MainActor
final class TareasViewModel: ObservableObject {

    // MARK: - Estado publicado (observado por las Vistas)

    /// Lista de tareas cargadas desde la API.
    @Published private(set) var tareas: [Tarea] = []

    /// Indica si hay una operación de red en curso.
    @Published private(set) var estaCargando: Bool = false

    /// Error actual para mostrar en la alerta de la UI (nil = sin error).
    @Published var errorActual: ErrorRed?

    /// Controla la visibilidad del formulario de crear/editar tarea.
    @Published var mostrarFormulario: Bool = false

    /// Tarea seleccionada para edición (nil = modo creación).
    @Published var tareaParaEditar: Tarea?

    // MARK: - Dependencias

    private let servicio: ProtocoloServicioTareas

    // MARK: - Inicializador

    /// - Parameter servicio: Inyección del servicio (permite pasar un Mock en tests).
    init(servicio: ProtocoloServicioTareas = ServicioTareas()) {
        self.servicio = servicio
    }

    // MARK: - Intenciones públicas (llamadas desde la Vista)

    /// Carga todas las tareas del usuario 1 desde la API.
    func cargarTareas() async {
        iniciarCarga()
        do {
            tareas = try await servicio.obtenerTareas(idUsuario: 1)
        } catch {
            manejarError(error)
        }
        finalizarCarga()
    }

    /// Crea una nueva tarea y la añade al principio de la lista.
    func crearTarea(titulo: String) async {
        guard !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        iniciarCarga()
        do {
            var nueva = Tarea.nueva
            nueva = Tarea(id: 0, idUsuario: 1, titulo: titulo.trimmingCharacters(in: .whitespaces), completada: false)
            let creada = try await servicio.crearTarea(nueva)
            // JSONPlaceholder devuelve id: 201 para todos los POSTs;
            // en una API real se usaría `creada` directamente.
            tareas.insert(creada, at: 0)
        } catch {
            manejarError(error)
        }
        finalizarCarga()
    }

    /// Actualiza el título y/o estado de completado de una tarea existente.
    func actualizarTarea(_ tarea: Tarea, nuevoTitulo: String, completada: Bool) async {
        iniciarCarga()
        do {
            let tareaActualizada = tarea.actualizando(titulo: nuevoTitulo, completada: completada)
            let confirmacion = try await servicio.actualizarTarea(tareaActualizada)
            reemplazar(tarea: confirmacion)
        } catch {
            manejarError(error)
        }
        finalizarCarga()
    }

    /// Alterna el estado de completado de una tarea (toggle rápido desde la lista).
    func alternarCompletado(de tarea: Tarea) async {
        await actualizarTarea(tarea, nuevoTitulo: tarea.titulo, completada: !tarea.completada)
    }

    /// Elimina una o varias tareas (usada por el gesto de swipe en la lista).
    func eliminarTareas(en indices: IndexSet) async {
        // Capturamos las tareas a eliminar antes de modificar el arreglo.
        let tareasAEliminar = indices.compactMap { tareas[safe: $0] }
        iniciarCarga()
        for tarea in tareasAEliminar {
            do {
                try await servicio.eliminarTarea(id: tarea.id)
            } catch {
                manejarError(error)
            }
        }
        // Actualizamos la lista local independientemente de la respuesta
        // (JSONPlaceholder siempre responde 200 al DELETE).
        tareas.remove(atOffsets: indices)
        finalizarCarga()
    }

    /// Prepara el formulario para editar una tarea existente.
    func seleccionarParaEditar(_ tarea: Tarea) {
        tareaParaEditar  = tarea
        mostrarFormulario = true
    }

    /// Prepara el formulario en modo creación.
    func mostrarFormularioCreacion() {
        tareaParaEditar  = nil
        mostrarFormulario = true
    }

    /// Cierra el formulario y limpia el estado de edición.
    func cerrarFormulario() {
        mostrarFormulario = false
        tareaParaEditar  = nil
    }

    /// Limpia el error actual (llamado tras descartar la alerta).
    func limpiarError() {
        errorActual = nil
    }

    // MARK: - Métodos privados de estado

    private func iniciarCarga() {
        estaCargando = true
        errorActual  = nil
    }

    private func finalizarCarga() {
        estaCargando = false
    }

    private func manejarError(_ error: Error) {
        errorActual = ErrorRed.desde(error)
    }

    /// Reemplaza una tarea en el arreglo local por su versión actualizada.
    private func reemplazar(tarea actualizada: Tarea) {
        guard let indice = tareas.firstIndex(where: { $0.id == actualizada.id }) else { return }
        tareas[indice] = actualizada
    }
}

// MARK: - Extensión de Array para acceso seguro por índice

private extension Array {
    subscript(safe indice: Int) -> Element? {
        indices.contains(indice) ? self[indice] : nil
    }
}
