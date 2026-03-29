// MARK: - ClienteHTTPTests.swift
// Pruebas unitarias del ClienteHTTP usando SesionMockHTTP.
// Valida: construcción de requests, decodificación JSON con campos de Postgres
// (snake_case), mapeo de fechas ISO 8601 y manejo de errores HTTP.

import XCTest
@testable import DaataPersistence

// MARK: - Suite del ClienteHTTP

final class ClienteHTTPTests: XCTestCase {

    // MARK: - Setup / Teardown

    private var sesionMock: SesionMockHTTP!
    private var sut: ClienteHTTP!

    override func setUp() {
        super.setUp()
        sesionMock = SesionMockHTTP()
        sut = ClienteHTTP(sesion: sesionMock)
    }

    override func tearDown() {
        sut = nil
        sesionMock = nil
        super.tearDown()
    }

    // MARK: - Tests: solicitar<T> con modelo Postgres

    func test_solicitar_decodificaArregloCorrectamente_conDatosValidos() async throws {
        // Dado: JSON con campos snake_case tal como devuelve el backend de Postgres
        let json = """
        [
            {
                "id": 1,
                "titulo": "Comprar leche",
                "esta_completada": false,
                "fecha_creacion": "2024-06-01T10:00:00.000Z"
            },
            {
                "id": 2,
                "titulo": "Hacer ejercicio",
                "esta_completada": true,
                "fecha_creacion": "2024-06-02T09:00:00Z"
            }
        ]
        """.data(using: .utf8)!
        sesionMock = SesionMockHTTP(datosRespuesta: json, codigoEstadoHTTP: 200)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando
        let tareasObtenidas: [Tarea] = try await sut.solicitar(ruta: ConfiguracionAPI.rutaTareas)

        // Entonces
        XCTAssertEqual(tareasObtenidas.count, 2)
        XCTAssertEqual(tareasObtenidas[0].id, 1)
        XCTAssertFalse(tareasObtenidas[0].estaCompletada,
                       "esta_completada: false debe mapearse a estaCompletada = false")
        XCTAssertTrue(tareasObtenidas[1].estaCompletada,
                      "esta_completada: true debe mapearse a estaCompletada = true")
    }

    func test_solicitar_decodificaTareaIndividual_conDatosValidos() async throws {
        // Dado
        let json = """
        {
            "id": 10,
            "titulo": "Leer un libro",
            "esta_completada": false,
            "fecha_creacion": "2024-05-20T14:30:00.000Z"
        }
        """.data(using: .utf8)!
        sesionMock = SesionMockHTTP(datosRespuesta: json, codigoEstadoHTTP: 200)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando
        let tarea: Tarea = try await sut.solicitar(ruta: "\(ConfiguracionAPI.rutaTareas)/10")

        // Entonces
        XCTAssertEqual(tarea.id, 10, "El id debe ser Int 10 (SERIAL de Postgres)")
        XCTAssertEqual(tarea.titulo, "Leer un libro")
        XCTAssertNotNil(tarea.fechaCreacion, "fecha_creacion debe decodificarse a Date")
    }

    // MARK: - Tests: mapeo de fecha ISO 8601 de Postgres

    func test_solicitar_decodificaFechaConMilisegundos_correctamente() async throws {
        // Postgres devuelve timestamps con milisegundos ("2024-06-15T12:00:00.000Z")
        let json = """
        [{
            "id": 1,
            "titulo": "Tarea con ms",
            "esta_completada": false,
            "fecha_creacion": "2024-06-15T12:00:00.000Z"
        }]
        """.data(using: .utf8)!
        sesionMock = SesionMockHTTP(datosRespuesta: json, codigoEstadoHTTP: 200)
        sut = ClienteHTTP(sesion: sesionMock)

        let tareas: [Tarea] = try await sut.solicitar(ruta: ConfiguracionAPI.rutaTareas)

        XCTAssertNotNil(tareas.first?.fechaCreacion,
                        "Debe decodificar ISO 8601 con milisegundos (formato de Postgres)")
    }

    func test_solicitar_decodificaFechaSinMilisegundos_correctamente() async throws {
        // También debe aceptar timestamps sin milisegundos
        let json = """
        [{
            "id": 2,
            "titulo": "Tarea sin ms",
            "esta_completada": true,
            "fecha_creacion": "2024-06-15T12:00:00Z"
        }]
        """.data(using: .utf8)!
        sesionMock = SesionMockHTTP(datosRespuesta: json, codigoEstadoHTTP: 200)
        sut = ClienteHTTP(sesion: sesionMock)

        let tareas: [Tarea] = try await sut.solicitar(ruta: ConfiguracionAPI.rutaTareas)

        XCTAssertNotNil(tareas.first?.fechaCreacion,
                        "Debe decodificar ISO 8601 sin milisegundos")
    }

    // MARK: - Tests: errores HTTP

    func test_solicitar_lanzaRespuestaInvalida_conCodigo500() async throws {
        // Dado
        sesionMock = SesionMockHTTP(datosRespuesta: Data(), codigoEstadoHTTP: 500)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        await assertLanzaError(.respuestaInvalida(codigoHTTP: 500)) {
            let _: [Tarea] = try await sut.solicitar(ruta: ConfiguracionAPI.rutaTareas)
        }
    }

    func test_solicitar_lanzaRecursoNoEncontrado_conCodigo404() async throws {
        // Dado
        sesionMock = SesionMockHTTP(datosRespuesta: Data(), codigoEstadoHTTP: 404)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        await assertLanzaError(.recursoNoEncontrado) {
            let _: Tarea = try await sut.solicitar(ruta: "\(ConfiguracionAPI.rutaTareas)/99999")
        }
    }

    func test_solicitar_lanzaDecodificacionFallida_conJSONInvalido() async throws {
        // Dado: JSON que no corresponde a Tarea
        let jsonInvalido = """
        { "campo_inexistente": "valor" }
        """.data(using: .utf8)!
        sesionMock = SesionMockHTTP(datosRespuesta: jsonInvalido, codigoEstadoHTTP: 200)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        await assertLanzaError(.decodificacionFallida) {
            let _: [Tarea] = try await sut.solicitar(ruta: ConfiguracionAPI.rutaTareas)
        }
    }

    func test_solicitar_propagaErrorDeRed_cuandoSesionFalla() async {
        // Dado: simular fallo de conexión
        let errorConexion = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        sesionMock = SesionMockHTTP(errorSimulado: errorConexion)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        do {
            let _: [Tarea] = try await sut.solicitar(ruta: ConfiguracionAPI.rutaTareas)
            XCTFail("Debería haber lanzado un error")
        } catch let error as ErrorRed {
            if case .errorDesconocido = error {
                // ✅ Error correcto
            } else {
                XCTFail("Se esperaba .errorDesconocido, se obtuvo: \(error)")
            }
        } catch {
            XCTFail("Se esperaba ErrorRed, no: \(error)")
        }
    }

    // MARK: - Tests: solicitarSinRespuesta (DELETE)

    func test_solicitarSinRespuesta_completaSinError_conCodigo200() async {
        // Dado
        sesionMock = SesionMockHTTP(datosRespuesta: "{}".data(using: .utf8)!, codigoEstadoHTTP: 200)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces: no debe lanzar
        do {
            try await sut.solicitarSinRespuesta(ruta: "\(ConfiguracionAPI.rutaTareas)/1", metodo: .eliminar)
        } catch {
            XCTFail("No debería lanzar error: \(error)")
        }
    }

    // MARK: - Helpers de Testing

    /// Aserta que el bloque async lanza exactamente el `ErrorRed` esperado.
    private func assertLanzaError<T>(
        _ errorEsperado: ErrorRed,
        archivo: StaticString = #filePath,
        linea: UInt = #line,
        operacion: () async throws -> T
    ) async {
        do {
            _ = try await operacion()
            XCTFail("Se esperaba lanzar \(errorEsperado) pero no hubo error",
                    file: archivo, line: linea)
        } catch let errorRed as ErrorRed {
            XCTAssertEqual(errorRed, errorEsperado,
                           "Error esperado: \(errorEsperado), obtenido: \(errorRed)",
                           file: archivo, line: linea)
        } catch {
            XCTFail("Se esperaba ErrorRed, se obtuvo: \(error)",
                    file: archivo, line: linea)
        }
    }
}

// MARK: - SesionMockHTTP

/// Implementación simulada de `ProtocoloSesionHTTP` para pruebas unitarias.
/// Devuelve datos y códigos HTTP predefinidos sin realizar peticiones de red reales.
final class SesionMockHTTP: ProtocoloSesionHTTP {

    private let datosRespuesta: Data
    private let codigoEstadoHTTP: Int
    private let errorSimulado: Error?

    // Inicializador general
    init(datosRespuesta: Data = Data(), codigoEstadoHTTP: Int = 200, errorSimulado: Error? = nil) {
        self.datosRespuesta   = datosRespuesta
        self.codigoEstadoHTTP = codigoEstadoHTTP
        self.errorSimulado    = errorSimulado
    }

    // Inicializador para simular fallos de red
    convenience init(errorSimulado: Error) {
        self.init(datosRespuesta: Data(), codigoEstadoHTTP: 0, errorSimulado: errorSimulado)
    }

    // MARK: - Fábricas con codificación ISO 8601 para fechas

    /// Crea un mock que devuelve un arreglo de tareas codificado en JSON.
    static func con(tareas: [Tarea]) throws -> SesionMockHTTP {
        let datos = try Self.codificadorParaTests().encode(tareas)
        return SesionMockHTTP(datosRespuesta: datos, codigoEstadoHTTP: 200)
    }

    /// Crea un mock que devuelve una tarea individual codificada en JSON.
    static func con(tarea: Tarea) throws -> SesionMockHTTP {
        let datos = try Self.codificadorParaTests().encode(tarea)
        return SesionMockHTTP(datosRespuesta: datos, codigoEstadoHTTP: 200)
    }

    // MARK: - ProtocoloSesionHTTP

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = errorSimulado { throw error }
        let respuesta = HTTPURLResponse(
            url: request.url!,
            statusCode: codigoEstadoHTTP,
            httpVersion: nil,
            headerFields: nil
        )!
        return (datosRespuesta, respuesta)
    }

    // MARK: - Helper privado

    /// Codificador con estrategia ISO 8601 para que las fechas sean
    /// decodificables por el ClienteHTTP (que espera strings ISO 8601).
    private static func codificadorParaTests() -> JSONEncoder {
        let codificador = JSONEncoder()
        codificador.dateEncodingStrategy = .iso8601
        return codificador
    }
}
