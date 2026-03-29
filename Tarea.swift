// MARK: - Tarea.swift
// Modelo principal que representa una tarea de la API REST.
// Compatible con JSONPlaceholder: https://jsonplaceholder.typicode.com/todos

import Foundation

// MARK: - Modelo Tarea

/// Representa una tarea individual tal como la define la API.
struct Tarea: Codable, Identifiable, Equatable {

    // MARK: Propiedades

    /// Identificador único de la tarea (generado por la API).
    let id: Int

    /// Identificador del usuario dueño de la tarea.
    let idUsuario: Int

    /// Título descriptivo de la tarea.
    var titulo: String

    /// Indica si la tarea ha sido completada.
    var completada: Bool

    // MARK: - CodingKeys

    /// Mapeo entre las propiedades Swift (español) y las claves JSON de la API (inglés).
    enum CodingKeys: String, CodingKey {
        case id
        case idUsuario  = "userId"
        case titulo     = "title"
        case completada = "completed"
    }
}

// MARK: - Tarea + Helpers

extension Tarea {

    /// Devuelve una tarea vacía lista para usarse en formularios de creación.
    static var nueva: Tarea {
        Tarea(id: 0, idUsuario: 1, titulo: "", completada: false)
    }

    /// Devuelve una copia de la tarea con el título y estado actualizados.
    func actualizando(titulo nuevoTitulo: String, completada nuevaCompletada: Bool) -> Tarea {
        Tarea(id: id, idUsuario: idUsuario, titulo: nuevoTitulo, completada: nuevaCompletada)
    }
}

// MARK: - Datos de prueba (Preview / Testing)

#if DEBUG
extension Tarea {
    static let ejemplo = Tarea(id: 1, idUsuario: 1, titulo: "Comprar leche", completada: false)
    static let ejemploCompletada = Tarea(id: 2, idUsuario: 1, titulo: "Hacer ejercicio", completada: true)

    static let listaDePrueba: [Tarea] = [
        Tarea(id: 1, idUsuario: 1, titulo: "Comprar leche", completada: false),
        Tarea(id: 2, idUsuario: 1, titulo: "Hacer ejercicio", completada: true),
        Tarea(id: 3, idUsuario: 1, titulo: "Leer un libro", completada: false),
        Tarea(id: 4, idUsuario: 1, titulo: "Llamar al médico", completada: false),
        Tarea(id: 5, idUsuario: 1, titulo: "Preparar presentación", completada: true)
    ]
}
#endif
