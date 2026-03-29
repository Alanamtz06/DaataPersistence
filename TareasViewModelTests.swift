// MARK: - TareasViewModelTests.swift
// Suite de pruebas unitarias para TareasViewModel.
// Cubre: carga, creación, actualización, eliminación y manejo de errores.

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
        XCTAssertFalse(sut.tareas.first?.completada ?? true,
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
        await sut.actualizarTarea(tareaOriginal, nuevoTitulo: "Título actualizado", completada: true)

        // Entonces
        let tareaActualizada = sut.tareas.first(where: { $0.id == tareaOriginal.id })
        XCTAssertEqual(tareaActualizada?.titulo, "Título actualizado")
        XCTAssertTrue(tareaActualizada?.completada ?? false)
        XCTAssertNil(sut.errorActual)
    }

    func test_alternarCompletado_invertaEstado() async {
        // Dado: tarea inicialmente no completada
        await sut.cargarTareas()
        guard let tareaInicial = sut.tareas.first(where: { !$0.completada }) else {
            XCTFail("Debe existir una tarea no completada en los datos de prueba")
            return
        }
        let estadoOriginal = tareaInicial.completada

        // Cuando
        await sut.alternarCompletado(de: tareaInicial)

        // Entonces
        let tareaModificada = sut.tareas.first(where: { $0.id == tareaInicial.id })
        XCTAssertEqual(tareaModificada?.completada, !estadoOriginal,
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
}
