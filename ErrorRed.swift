// MARK: - ErrorRed.swift
// Enumeración de errores de red usada en toda la capa de servicios y ViewModel.
// Implementa LocalizedError para mostrar mensajes en la UI y Equatable para los tests.

import Foundation

// MARK: - ErrorRed

/// Errores que puede producir el cliente HTTP o el servicio de tareas.
enum ErrorRed: Error, LocalizedError, Equatable {

    /// La URL construida no es válida.
    case urlInvalida

    /// El servidor respondió con un código HTTP fuera del rango 200–299.
    case respuestaInvalida(codigoHTTP: Int)

    /// El servidor devolvió un 404 (recurso inexistente).
    case recursoNoEncontrado

    /// No se pudo codificar el cuerpo de la petición a JSON.
    case codificacionFallida

    /// No se pudo decodificar la respuesta JSON al tipo esperado.
    case decodificacionFallida

    /// Error no tipificado (p. ej. fallo de red del sistema operativo).
    case errorDesconocido

    // MARK: - Fábrica

    /// Convierte cualquier `Error` en un `ErrorRed`.
    /// Si ya es un `ErrorRed`, lo retorna tal cual; de lo contrario devuelve `.errorDesconocido`.
    static func desde(_ error: Error) -> ErrorRed {
        guard let errorRed = error as? ErrorRed else { return .errorDesconocido }
        return errorRed
    }

    // MARK: - Mensajes localizados para la UI

    var errorDescription: String? {
        switch self {
        case .urlInvalida:
            return "La URL de la petición no es válida."
        case .respuestaInvalida(let codigo):
            return "El servidor respondió con un error (código \(codigo))."
        case .recursoNoEncontrado:
            return "El recurso solicitado no existe en el servidor."
        case .codificacionFallida:
            return "No se pudieron codificar los datos de la petición."
        case .decodificacionFallida:
            return "No se pudieron leer los datos recibidos del servidor."
        case .errorDesconocido:
            return "Ocurrió un error desconocido. Inténtalo de nuevo."
        }
    }
}
