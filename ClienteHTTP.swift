// MARK: - ClienteHTTP.swift
// Abstracción de URLSession para peticiones HTTP genéricas y reutilizables.
// Centraliza la construcción de requests, validación de respuestas
// y decodificación JSON, siguiendo el principio DRY.

import Foundation

// MARK: - Protocolo de Sesión (para mocking en tests)

/// Permite reemplazar `URLSession` por una sesión simulada en pruebas unitarias.
protocol ProtocoloSesionHTTP {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - Conformancia de URLSession al protocolo

extension URLSession: ProtocoloSesionHTTP {}

// MARK: - Constantes de Red

/// Valores de configuración de la API REST centralizado en un solo lugar.
enum ConfiguracionAPI {
    static let urlBase       = "https://jsonplaceholder.typicode.com"
    static let rutaTareas    = "/todos"
    static let tiempoEspera  = 30.0
}

// MARK: - Método HTTP

/// Verbos HTTP soportados por el cliente.
enum MetodoHTTP: String {
    case obtener  = "GET"
    case crear    = "POST"
    case actualizar = "PUT"
    case eliminar  = "DELETE"
}

// MARK: - Cliente HTTP

/// Realiza peticiones HTTP genéricas usando `URLSession`.
/// Soporta codificación/decodificación automática de JSON con `Codable`.
final class ClienteHTTP {

    // MARK: - Dependencias

    private let sesion: ProtocoloSesionHTTP
    private let decodificador: JSONDecoder
    private let codificador: JSONEncoder

    // MARK: - Inicializador

    init(sesion: ProtocoloSesionHTTP = URLSession.shared) {
        self.sesion      = sesion
        self.decodificador = JSONDecoder()
        self.codificador   = JSONEncoder()
    }

    // MARK: - Petición con respuesta decodificada

    /// Ejecuta una petición y decodifica la respuesta en el tipo `T` esperado.
    func solicitar<T: Decodable>(
        ruta: String,
        metodo: MetodoHTTP = .obtener,
        cuerpo: Encodable? = nil
    ) async throws -> T {
        let datos = try await ejecutarPeticion(ruta: ruta, metodo: metodo, cuerpo: cuerpo)
        return try decodificar(T.self, desde: datos)
    }

    // MARK: - Petición sin respuesta (p. ej. DELETE)

    /// Ejecuta una petición que no retorna cuerpo de respuesta significativo.
    func solicitarSinRespuesta(
        ruta: String,
        metodo: MetodoHTTP,
        cuerpo: Encodable? = nil
    ) async throws {
        _ = try await ejecutarPeticion(ruta: ruta, metodo: metodo, cuerpo: cuerpo)
    }

    // MARK: - Métodos privados

    /// Construye y ejecuta el `URLRequest`, validando el código HTTP recibido.
    private func ejecutarPeticion(
        ruta: String,
        metodo: MetodoHTTP,
        cuerpo: Encodable?
    ) async throws -> Data {
        let solicitud = try construirSolicitud(ruta: ruta, metodo: metodo, cuerpo: cuerpo)

        let (datos, respuesta) = try await sesion.data(for: solicitud)
        try validarRespuesta(respuesta)
        return datos
    }

    /// Construye un `URLRequest` con los encabezados y cuerpo apropiados.
    private func construirSolicitud(
        ruta: String,
        metodo: MetodoHTTP,
        cuerpo: Encodable?
    ) throws -> URLRequest {
        guard let url = URL(string: ConfiguracionAPI.urlBase + ruta) else {
            throw ErrorRed.urlInvalida
        }

        var solicitud = URLRequest(url: url, timeoutInterval: ConfiguracionAPI.tiempoEspera)
        solicitud.httpMethod = metodo.rawValue
        solicitud.setValue("application/json", forHTTPHeaderField: "Content-Type")
        solicitud.setValue("application/json", forHTTPHeaderField: "Accept")

        if let cuerpo {
            solicitud.httpBody = try codificar(cuerpo)
        }

        return solicitud
    }

    /// Valida que la respuesta HTTP tenga un código de éxito (200–299).
    private func validarRespuesta(_ respuesta: URLResponse) throws {
        guard let httpRespuesta = respuesta as? HTTPURLResponse else {
            throw ErrorRed.respuestaInvalida(codigoHTTP: -1)
        }
        switch httpRespuesta.statusCode {
        case 200...299:
            return
        case 404:
            throw ErrorRed.recursoNoEncontrado
        default:
            throw ErrorRed.respuestaInvalida(codigoHTTP: httpRespuesta.statusCode)
        }
    }

    /// Codifica un `Encodable` a `Data` JSON.
    private func codificar(_ objeto: Encodable) throws -> Data {
        do {
            return try codificador.encode(objeto)
        } catch {
            throw ErrorRed.codificacionFallida
        }
    }

    /// Decodifica `Data` JSON al tipo `T`.
    private func decodificar<T: Decodable>(_ tipo: T.Type, desde datos: Data) throws -> T {
        do {
            return try decodificador.decode(tipo, from: datos)
        } catch {
            throw ErrorRed.decodificacionFallida
        }
    }
}
