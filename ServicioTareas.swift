// MARK: - ServicioTareas.swift
// Implementación concreta del CRUD de tareas usando el backend Node.js/Postgres.
// Transforma el modelo Tarea en los DTOs que espera cada endpoint.

import Foundation

// MARK: - Servicio de Tareas

/// Implementa `ProtocoloServicioTareas` usando `ClienteHTTP`.
/// Es el único punto de la app que conoce los endpoints concretos del backend.
final class ServicioTareas: ProtocoloServicioTareas {

    // MARK: - Dependencias

    private let clienteHTTP: ClienteHTTP

    // MARK: - Inicializador

    init(clienteHTTP: ClienteHTTP = ClienteHTTP()) {
        self.clienteHTTP = clienteHTTP
    }

    // MARK: - ProtocoloServicioTareas

    /// GET /tareas
    /// Obtiene todas las tareas almacenadas en la base de datos.
    func obtenerTareas() async throws -> [Tarea] {
        return try await clienteHTTP.solicitar(ruta: ConfiguracionAPI.rutaTareas)
    }

    /// POST /tareas
    /// Crea una nueva tarea. Envía solo el título; el servidor asigna id y fecha_creacion.
    func crearTarea(_ tarea: Tarea) async throws -> Tarea {
        let dto = CrearTareaDTO(titulo: tarea.titulo)
        return try await clienteHTTP.solicitar(
            ruta: ConfiguracionAPI.rutaTareas,
            metodo: .crear,
            cuerpo: dto
        )
    }

    /// PUT /tareas/:id
    /// Actualiza título y estado de completado de una tarea existente.
    func actualizarTarea(_ tarea: Tarea) async throws -> Tarea {
        let ruta = "\(ConfiguracionAPI.rutaTareas)/\(tarea.id)"
        let dto  = ActualizarTareaDTO(titulo: tarea.titulo, estaCompletada: tarea.estaCompletada)
        return try await clienteHTTP.solicitar(
            ruta: ruta,
            metodo: .actualizar,
            cuerpo: dto
        )
    }

    /// DELETE /tareas/:id
    /// Elimina una tarea por su identificador.
    func eliminarTarea(id: Int) async throws {
        let ruta = "\(ConfiguracionAPI.rutaTareas)/\(id)"
        try await clienteHTTP.solicitarSinRespuesta(ruta: ruta, metodo: .eliminar)
    }
}
