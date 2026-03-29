// MARK: - TareasViewModelTests.swift
// Suite de pruebas unitarias para TareasViewModel.
// Cubre: carga, creación, actualización, eliminación, manejo de errores
// y mapeo de JSON con los campos de Postgres (snake_case ↔ camelCase).

import XCTest
@testable import DaataPersistence

// MARK: - Suite Principal

@MainActor
final class TareasViewModelTests: XCTestCase {

    // MARK: - Propiedades

    private var mockServicio: ServicioMockTareas!
    private var sut: TareasViewModel!  // System Under Test

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockServicio = ServicioMockTareas(tareas: Tarea.listaDePrueba)
        sut = TareasViewModel(servicio: mockServicio)
    }

    override func tearDown() async throws {
        sut = nil
        mockServicio = nil
        try await super.tearDown()
    }

    // MARK: - Tests: cargarTareas()

    func test_cargarTareas_cargaCorrectamente_cuandoServicioExitoso() async {
        // Cuando
        await sut.cargarTareas()

        // Entonces
        XCTAssertEqual(sut.tareas.count, Tarea.listaDePrueba.count,
                       "Debería cargar el mismo número de tareas que el mock")
        XCTAssertFalse(sut.estaCargando, "estaCargando debería ser false al terminar")
        XCTAssertNil(sut.errorActual, "No debería haber error con servicio exitoso")
    }

    func test_cargarTareas_establaceError_cuandoServicioFalla() async {
        // Dado
        mockServicio.errorSimulado = .urlInvalida

        // Cuando
        await sut.cargarTareas()

        // Entonces
        XCTAssertNotNil(sut.errorActual, "Debería establecer un error al fallar la carga")
        XCTAssertEqual(sut.errorActual, .urlInvalida, "El error debería ser urlInvalida")
        XCTAssertTrue(sut.tareas.isEmpty, "Las tareas deberían permanecer vacías al haber error")
        XCTAssertFalse(sut.estaCargando, "estaCargando debería ser false tras el error")
    }

    func test_cargarTareas_restablaceErrorPrevio_alReintentarConExito() async {
        // Dado: primer intento falla
        mockServicio.errorSimulado = .urlInvalida
        await sut.cargarTareas()
        XCTAssertNotNil(sut.errorActual)

        // Cuando: segundo intento con éxito
        mockServicio.errorSimulado = nil
        await sut.cargarTareas()

        // Entonces
        XCTAssertNil(sut.errorActual, "El error debería limpiarse al tener éxito")
        XCTAssertFalse(sut.tareas.isEmpty)
    }

    // MARK: - Tests: crearTarea()

    func test_crearTarea_agregaTareaAlInicio_cuandoServicioExitoso() async {
        // Dado
        await sut.cargarTareas()
        let cantidadAntes = sut.tareas.count

        // Cuando
        await sut.crearTarea(titulo: "Nueva tarea de prueba")

        // Entonces
        XCTAssertEqual(sut.tareas.count, cantidadAntes + 1,
                       "Debería haber una tarea más tras crear")
        XCTAssertEqual(sut.tareas.first?.titulo, "Nueva tarea de prueba",
                       "La nueva tarea debería estar al inicio de la lista")
        XCTAssertFalse(sut.tareas.first?.estaCompletada ?? true,
                       "La nueva tarea debería estar marcada como no completada")
    }

    func test_crearTarea_noAgregaNada_cuandoTituloEstaVacio() async {
        // Dado
        await sut.cargarTareas()
        let cantidadAntes = sut.tareas.count

        // Cuando
        await sut.crearTarea(titulo: "   ")  // Solo espacios

        // Entonces
        XCTAssertEqual(sut.tareas.count, cantidadAntes,
                       "No debería agregar tarea con título vacío")
    }

    func test_crearTarea_estableceError_cuandoServicioFalla() async {
        // Dado
        mockServicio.errorSimulado = .respuestaInvalida(codigoHTTP: 500)

        // Cuando
        await sut.crearTarea(titulo: "Tarea que fallará")

        // Entonces
        XCTAssertNotNil(sut.errorActual)
        XCTAssertEqual(sut.errorActual, .respuestaInvalida(codigoHTTP: 500))
    }

    // MARK: - Tests: actualizarTarea()

    func test_actualizarTarea_modificaTareaExistente_cuandoServicioExitoso() async {
        // Dado
        await sut.cargarTareas()
        guard let tareaOriginal = sut.tareas.first else {
            XCTFail("Debe haber al menos una tarea cargada")
            return
        }

        // Cuando
        await sut.actualizarTarea(tareaOriginal, nuevoTitulo: "Título actualizado", estaCompletada: true)

        // Entonces
        let tareaActualizada = sut.tareas.first(where: { $0.id == tareaOriginal.id })
        XCTAssertEqual(tareaActualizada?.titulo, "Título actualizado")
        XCTAssertTrue(tareaActualizada?.estaCompletada ?? false)
        XCTAssertNil(sut.errorActual)
    }

    func test_alternarCompletado_invertaEstado() async {
        // Dado: tarea inicialmente no completada
        await sut.cargarTareas()
        guard let tareaInicial = sut.tareas.first(where: { !$0.estaCompletada }) else {
            XCTFail("Debe existir una tarea no completada en los datos de prueba")
            return
        }
        let estadoOriginal = tareaInicial.estaCompletada

        // Cuando
        await sut.alternarCompletado(de: tareaInicial)

        // Entonces
        let tareaModificada = sut.tareas.first(where: { $0.id == tareaInicial.id })
        XCTAssertEqual(tareaModificada?.estaCompletada, !estadoOriginal,
                       "El estado de completado debería haberse invertido")
    }

    // MARK: - Tests: eliminarTareas()

    func test_eliminarTareas_reduceLista_cuandoServicioExitoso() async {
        // Dado
        await sut.cargarTareas()
        let cantidadAntes = sut.tareas.count

        // Cuando: eliminar la primera tarea
        await sut.eliminarTareas(en: IndexSet(integer: 0))

        // Entonces
        XCTAssertEqual(sut.tareas.count, cantidadAntes - 1,
                       "La lista debería tener una tarea menos tras eliminar")
    }

    // MARK: - Tests: Estado del formulario

    func test_mostrarFormularioCreacion_configuraModoCreacion() {
        // Cuando
        sut.mostrarFormularioCreacion()

        // Entonces
        XCTAssertTrue(sut.mostrarFormulario)
        XCTAssertNil(sut.tareaParaEditar,
                     "tareaParaEditar debe ser nil en modo creación")
    }

    func test_seleccionarParaEditar_configuraModoEdicion() {
        // Dado
        let tarea = Tarea.ejemplo

        // Cuando
        sut.seleccionarParaEditar(tarea)

        // Entonces
        XCTAssertTrue(sut.mostrarFormulario)
        XCTAssertEqual(sut.tareaParaEditar, tarea,
                       "tareaParaEditar debería ser la tarea seleccionada")
    }

    func test_cerrarFormulario_limpiaEstadoDeEdicion() {
        // Dado
        sut.seleccionarParaEditar(Tarea.ejemplo)

        // Cuando
        sut.cerrarFormulario()

        // Entonces
        XCTAssertFalse(sut.mostrarFormulario)
        XCTAssertNil(sut.tareaParaEditar)
    }

    func test_limpiarError_remueveerrorActual() async {
        // Dado: forzar un error
        mockServicio.errorSimulado = .decodificacionFallida
        await sut.cargarTareas()
        XCTAssertNotNil(sut.errorActual)

        // Cuando
        sut.limpiarError()

        // Entonces
        XCTAssertNil(sut.errorActual)
    }

    // MARK: - Tests: Mapeo JSON ↔ Postgres (snake_case)

    func test_tarea_decodificaCorrectamente_desdeJSONDePostgres() throws {
        // Verifica que el JSON con snake_case de Postgres se mapee
        // correctamente a las propiedades camelCase de Swift.
        let json = """
        {
            "id": 42,
            "titulo": "Estudiar Swift",
            "esta_completada": true,
            "fecha_creacion": "2024-06-15T12:00:00.000Z"
        }
        """.data(using: .utf8)!

        // Cuando
        let tarea = try decodificadorDeRed().decode(Tarea.self, from: json)

        // Entonces
        XCTAssertEqual(tarea.id, 42,            "El id debe decodificarse como Int (SERIAL de Postgres)")
        XCTAssertEqual(tarea.titulo, "Estudiar Swift")
        XCTAssertTrue(tarea.estaCompletada,     "esta_completada debe mapearse a estaCompletada")
        XCTAssertNotNil(tarea.fechaCreacion,    "fecha_creacion debe mapearse a fechaCreacion")
    }

    func test_tarea_idEsEntero_noUUID() throws {
        // Garantiza que el id sea Int (Postgres SERIAL), no String ni UUID.
        let json = """
        {
            "id": 7,
            "titulo": "Tarea de prueba",
            "esta_completada": false,
            "fecha_creacion": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let tarea = try decodificadorDeRed().decode(Tarea.self, from: json)

        // El tipo Int se verifica en compilación; confirmamos el valor
        let idComoEntero: Int = tarea.id
        XCTAssertEqual(idComoEntero, 7, "El id debe ser Int 7")
    }

    func test_tarea_estaCompletadaFalse_cuandoJsonEnviaFalse() throws {
        let json = """
        {
            "id": 1,
            "titulo": "Tarea pendiente",
            "esta_completada": false,
            "fecha_creacion": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let tarea = try decodificadorDeRed().decode(Tarea.self, from: json)

        XCTAssertFalse(tarea.estaCompletada,
                       "estaCompletada debe ser false cuando esta_completada es false en JSON")
    }

    func test_arregloTareas_decodificaDesdeJSONDePostgres() throws {
        // Simula la respuesta real del GET /tareas con múltiples tareas.
        let json = """
        [
            {
                "id": 1,
                "titulo": "Primera tarea",
                "esta_completada": false,
                "fecha_creacion": "2024-06-01T08:00:00.000Z"
            },
            {
                "id": 2,
                "titulo": "Segunda tarea",
                "esta_completada": true,
                "fecha_creacion": "2024-06-02T09:30:00.000Z"
            }
        ]
        """.data(using: .utf8)!

        let tareas = try decodificadorDeRed().decode([Tarea].self, from: json)

        XCTAssertEqual(tareas.count, 2)
        XCTAssertEqual(tareas[0].id, 1)
        XCTAssertFalse(tareas[0].estaCompletada)
        XCTAssertEqual(tareas[1].id, 2)
        XCTAssertTrue(tareas[1].estaCompletada)
    }

    // MARK: - Helper privado

    /// Construye un JSONDecoder con la estrategia de fechas ISO 8601
    /// idéntica a la que usa ClienteHTTP en producción.
    private func decodificadorDeRed() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom { decoder in
            let contenedor = try decoder.singleValueContainer()
            let cadena     = try contenedor.decode(String.self)
            let formato    = ISO8601DateFormatter()
            formato.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let fecha = formato.date(from: cadena) { return fecha }
            formato.formatOptions = [.withInternetDateTime]
            if let fecha = formato.date(from: cadena) { return fecha }
            throw DecodingError.dataCorruptedError(
                in: contenedor,
                debugDescription: "Formato de fecha no reconocido: \(cadena)"
            )
        }
        return dec
    }
}
