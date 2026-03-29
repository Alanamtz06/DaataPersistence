// MARK: - ClienteHTTPTests.swift
// Pruebas unitarias del ClienteHTTP usando SesionMockHTTP.
// Valida: construcción de requests, decodificación JSON y manejo de errores HTTP.

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

    // MARK: - Tests: solicitar<T>

    func test_solicitar_decodificaArregloCorrectamente_conDatosValidos() async throws {
        // Dado
        let tareasEsperadas = [Tarea.ejemplo, Tarea.ejemploCompletada]
        sesionMock = try SesionMockHTTP.con(tareas: tareasEsperadas)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando
        let tareasObtenidas: [Tarea] = try await sut.solicitar(ruta: "/todos")

        // Entonces
        XCTAssertEqual(tareasObtenidas.count, 2)
        XCTAssertEqual(tareasObtenidas[0].id, 1)
        XCTAssertEqual(tareasObtenidas[1].completada, true)
    }

    func test_solicitar_decodificaTareaIndividual_conDatosValidos() async throws {
        // Dado
        sesionMock = try SesionMockHTTP.con(tarea: Tarea.ejemplo)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando
        let tarea: Tarea = try await sut.solicitar(ruta: "/todos/1")

        // Entonces
        XCTAssertEqual(tarea.id, Tarea.ejemplo.id)
        XCTAssertEqual(tarea.titulo, Tarea.ejemplo.titulo)
    }

    // MARK: - Tests: errores HTTP

    func test_solicitar_lanzaRespuestaInvalida_conCodigo500() async throws {
        // Dado
        sesionMock = SesionMockHTTP(datosRespuesta: Data(), codigoEstadoHTTP: 500)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        await assertLanzaError(.respuestaInvalida(codigoHTTP: 500)) {
            let _: [Tarea] = try await sut.solicitar(ruta: "/todos")
        }
    }

    func test_solicitar_lanzaRecursoNoEncontrado_conCodigo404() async throws {
        // Dado
        sesionMock = SesionMockHTTP(datosRespuesta: Data(), codigoEstadoHTTP: 404)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        await assertLanzaError(.recursoNoEncontrado) {
            let _: Tarea = try await sut.solicitar(ruta: "/todos/99999")
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
            let _: [Tarea] = try await sut.solicitar(ruta: "/todos")
        }
    }

    func test_solicitar_propagaErrorDeRed_cuandoSesionFalla() async {
        // Dado: simular fallo de conexión
        let errorConexion = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        sesionMock = SesionMockHTTP(errorSimulado: errorConexion)
        sut = ClienteHTTP(sesion: sesionMock)

        // Cuando / Entonces
        do {
            let _: [Tarea] = try await sut.solicitar(ruta: "/todos")
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
            try await sut.solicitarSinRespuesta(ruta: "/todos/1", metodo: .eliminar)
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
