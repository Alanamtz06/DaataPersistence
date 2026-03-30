// MARK: - ProtocoloServicioTareas.swift
// Contrato que deben cumplir tanto el servicio real (ServicioTareas)
// como el simulado (ServicioMockTareas). Permite inyección de dependencias
// y pruebas unitarias sin red real.

import Foundation

// MARK: - Protocolo

/// Define las operaciones CRUD disponibles para el recurso "tareas".
/// Todos los métodos son async throws para operaciones asíncronas y con manejo de errores.
protocol ProtocoloServicioTareas {

    /// Obtiene la lista completa de tareas desde el backend.
    func obtenerTareas() async throws -> [Tarea]

    /// Crea una nueva tarea en el servidor.
    /// - Parameter tarea: Objeto con los datos iniciales (el servidor asigna id y fecha).
    /// - Returns: La tarea creada con el id y fecha_creacion asignados por el servidor.
    func crearTarea(_ tarea: Tarea) async throws -> Tarea

    /// Actualiza el título y/o estado de completado de una tarea existente.
    /// - Parameter tarea: Tarea con los valores actualizados.
    /// - Returns: La tarea tal como quedó confirmada por el servidor.
    func actualizarTarea(_ tarea: Tarea) async throws -> Tarea

    /// Elimina una tarea por su identificador.
    /// - Parameter id: El id Int (SERIAL de Postgres) de la tarea a eliminar.
    func eliminarTarea(id: Int) async throws
}
