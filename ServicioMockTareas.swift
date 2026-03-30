// MARK: - ServicioMockTareas.swift
// Implementación simulada de ProtocoloServicioTareas para:
//   1. Pruebas unitarias (sin red real).
//   2. Previews de SwiftUI (sin esperas).

import Foundation

// MARK: - Mock del Servicio de Tareas

/// Simula el comportamiento del servicio real con datos en memoria.
/// Configurable para simular éxitos y fallos específicos.
final class ServicioMockTareas: ProtocoloServicioTareas {

    // MARK: - Configuración

    /// Tareas que devolverá el mock en las llamadas GET.
    var tareas: [Tarea]

    /// Si se asigna, todas las operaciones lanzarán este error.
    var errorSimulado: ErrorRed?

    /// Retardo artificial en segundos (útil para probar estados de carga).
    var retardoSimulado: TimeInterval

    // MARK: - Inicializador

    init(
        tareas: [Tarea] = Tarea.listaDePrueba,
        errorSimulado: ErrorRed? = nil,
        retardoSimulado: TimeInterval = 0
    ) {
        self.tareas          = tareas
        self.errorSimulado   = errorSimulado
        self.retardoSimulado = retardoSimulado
    }

    // MARK: - ProtocoloServicioTareas

    func obtenerTareas() async throws -> [Tarea] {
        try await simularLatencia()
        try lanzarErrorSiNecesario()
        return tareas
    }

    func crearTarea(_ tarea: Tarea) async throws -> Tarea {
        try await simularLatencia()
        try lanzarErrorSiNecesario()
        let nueva = Tarea(
            id:             idSiguiente(),
            titulo:         tarea.titulo,
            estaCompletada: false,
            fechaCreacion:  Date()
        )
        tareas.append(nueva)
        return nueva
    }

    func actualizarTarea(_ tarea: Tarea) async throws -> Tarea {
        try await simularLatencia()
        try lanzarErrorSiNecesario()
        guard let indice = tareas.firstIndex(where: { $0.id == tarea.id }) else {
            throw ErrorRed.recursoNoEncontrado
        }
        tareas[indice] = tarea
        return tarea
    }

    func eliminarTarea(id: Int) async throws {
        try await simularLatencia()
        try lanzarErrorSiNecesario()
        tareas.removeAll { $0.id == id }
    }

    // MARK: - Helpers privados

    private func simularLatencia() async throws {
        guard retardoSimulado > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(retardoSimulado * 1_000_000_000))
    }

    private func lanzarErrorSiNecesario() throws {
        if let error = errorSimulado { throw error }
    }

    private func idSiguiente() -> Int {
        (tareas.map(\.id).max() ?? 0) + 1
    }
}
