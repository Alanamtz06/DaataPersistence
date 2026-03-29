// MARK: - ServicioTareas.swift
// Implementación concreta del CRUD de tareas usando la API REST.
// Conecta con: https://jsonplaceholder.typicode.com/todos

import Foundation

// MARK: - Servicio de Tareas

/// Implementa `ProtocoloServicioTareas` usando `ClienteHTTP`.
/// Es el único punto de la app que conoce los endpoints concretos de la API.
final class ServicioTareas: ProtocoloServicioTareas {

    // MARK: - Dependencias

    private let clienteHTTP: ClienteHTTP

    // MARK: - Inicializador

    init(clienteHTTP: ClienteHTTP = ClienteHTTP()) {
        self.clienteHTTP = clienteHTTP
    }

    // MARK: - ProtocoloServicioTareas

    /// GET /todos?userId={idUsuario}
    /// Obtiene todas las tareas del usuario. Limita a 10 para no saturar la UI.
    func obtenerTareas(idUsuario: Int = 1) async throws -> [Tarea] {
        let ruta = "\(ConfiguracionAPI.rutaTareas)?userId=\(idUsuario)&_limit=10"
        return try await clienteHTTP.solicitar(ruta: ruta)
    }

    /// GET /todos/{id}
    /// Obtiene una tarea individual por su identificador.
    func obtenerTarea(id: Int) async throws -> Tarea {
        let ruta = "\(ConfiguracionAPI.rutaTareas)/\(id)"
        return try await clienteHTTP.solicitar(ruta: ruta)
    }

    /// POST /todos
    /// Crea una nueva tarea y retorna el objeto con el ID asignado por el servidor.
    func crearTarea(_ tarea: Tarea) async throws -> Tarea {
        return try await clienteHTTP.solicitar(
            ruta: ConfiguracionAPI.rutaTareas,
            metodo: .crear,
            cuerpo: tarea
        )
    }

    /// PUT /todos/{id}
    /// Actualiza completamente una tarea existente.
    func actualizarTarea(_ tarea: Tarea) async throws -> Tarea {
        let ruta = "\(ConfiguracionAPI.rutaTareas)/\(tarea.id)"
        return try await clienteHTTP.solicitar(
            ruta: ruta,
            metodo: .actualizar,
            cuerpo: tarea
        )
    }

    /// DELETE /todos/{id}
    /// Elimina una tarea del servidor.
    func eliminarTarea(id: Int) async throws {
        let ruta = "\(ConfiguracionAPI.rutaTareas)/\(id)"
        try await clienteHTTP.solicitarSinRespuesta(ruta: ruta, metodo: .eliminar)
    }
}
