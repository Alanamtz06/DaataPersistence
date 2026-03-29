// MARK: - Tarea.swift
// Modelo principal que representa una tarea de la API REST.
// Adaptado para el backend Node.js/Express con PostgreSQL.
// Los campos de la DB usan snake_case; los mapea a camelCase mediante CodingKeys.

import Foundation

// MARK: - Modelo Tarea

/// Representa una tarea individual tal como la devuelve la base de datos.
struct Tarea: Codable, Identifiable, Equatable {

    // MARK: Propiedades

    /// Identificador único asignado por PostgreSQL (tipo SERIAL → Int).
    let id: Int

    /// Título descriptivo de la tarea.
    var titulo: String

    /// Indica si la tarea ha sido completada.
    /// Mapeado desde el campo `esta_completada` de Postgres.
    var estaCompletada: Bool

    /// Fecha y hora de creación registrada por el servidor.
    /// Mapeado desde el campo `fecha_creacion` de Postgres (Timestamp ISO 8601).
    var fechaCreacion: Date

    // MARK: - CodingKeys

    /// Mapeo entre propiedades Swift (camelCase) y columnas de la DB (snake_case).
    enum CodingKeys: String, CodingKey {
        case id
        case titulo
        case estaCompletada = "esta_completada"
        case fechaCreacion  = "fecha_creacion"
    }
}

// MARK: - DTOs para peticiones al backend

/// Cuerpo de la petición POST /tareas.
/// Solo envía el título; el resto lo asigna el servidor.
struct CrearTareaDTO: Encodable {
    let titulo: String
}

/// Cuerpo de la petición PUT /tareas/:id.
/// Permite actualizar título y/o estado de completado.
struct ActualizarTareaDTO: Encodable {
    let titulo: String
    let estaCompletada: Bool

    enum CodingKeys: String, CodingKey {
        case titulo
        case estaCompletada = "esta_completada"
    }
}

// MARK: - Tarea + Helpers

extension Tarea {

    /// Devuelve una tarea vacía lista para usarse en formularios de creación.
    static var nueva: Tarea {
        Tarea(id: 0, titulo: "", estaCompletada: false, fechaCreacion: Date())
    }

    /// Devuelve una copia de la tarea con el título y estado de completado actualizados.
    func actualizando(titulo nuevoTitulo: String, estaCompletada nuevoEstado: Bool) -> Tarea {
        Tarea(id: id, titulo: nuevoTitulo, estaCompletada: nuevoEstado, fechaCreacion: fechaCreacion)
    }
}

// MARK: - Datos de prueba (Preview / Testing)

#if DEBUG
extension Tarea {
    static let ejemplo = Tarea(
        id: 1,
        titulo: "Comprar leche",
        estaCompletada: false,
        fechaCreacion: Date()
    )
    static let ejemploCompletada = Tarea(
        id: 2,
        titulo: "Hacer ejercicio",
        estaCompletada: true,
        fechaCreacion: Date()
    )

    static let listaDePrueba: [Tarea] = [
        Tarea(id: 1, titulo: "Comprar leche",          estaCompletada: false, fechaCreacion: Date()),
        Tarea(id: 2, titulo: "Hacer ejercicio",         estaCompletada: true,  fechaCreacion: Date()),
        Tarea(id: 3, titulo: "Leer un libro",           estaCompletada: false, fechaCreacion: Date()),
        Tarea(id: 4, titulo: "Llamar al médico",        estaCompletada: false, fechaCreacion: Date()),
        Tarea(id: 5, titulo: "Preparar presentación",   estaCompletada: true,  fechaCreacion: Date())
    ]
}
#endif
