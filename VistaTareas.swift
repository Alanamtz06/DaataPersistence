// MARK: - VistaTareas.swift
// Vista principal del módulo de tareas.
// Muestra la lista, maneja estados de carga/error
// y coordina la navegación al formulario de creación/edición.

import SwiftUI

// MARK: - Vista Principal de Tareas

struct VistaTareas: View {

    // MARK: - Dependencias

    @StateObject private var viewModel = TareasViewModel()

    // MARK: - Cuerpo de la vista

    var body: some View {
        NavigationStack {
            contenidoPrincipal
                .navigationTitle("Mis Tareas")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { barraDeHerramientas }
                .sheet(isPresented: $viewModel.mostrarFormulario) {
                    VistaFormularioTarea(viewModel: viewModel)
                }
                .alert(
                    "Algo salió mal",
                    isPresented: Binding(
                        get: { viewModel.errorActual != nil },
                        set: { if !$0 { viewModel.limpiarError() } }
                    ),
                    actions: {
                        Button("Reintentar") { Task { await viewModel.cargarTareas() } }
                        Button("Cancelar", role: .cancel) { viewModel.limpiarError() }
                    },
                    message: {
                        Text(viewModel.errorActual?.localizedDescription ?? "Error desconocido.")
                    }
                )
                .task { await viewModel.cargarTareas() }
        }
    }

    // MARK: - Subvistas

    /// Decide qué mostrar según el estado actual del ViewModel.
    @ViewBuilder
    private var contenidoPrincipal: some View {
        if viewModel.estaCargando && viewModel.tareas.isEmpty {
            VistaIndicadorCarga()
        } else if viewModel.tareas.isEmpty {
            VistaListaVacia()
        } else {
            listaConTareas
        }
    }

    /// Lista principal de tareas con soporte para eliminar y refrescar.
    private var listaConTareas: some View {
        List {
            ForEach(viewModel.tareas) { tarea in
                VistaCeldaTarea(tarea: tarea) {
                    // Toggle completado al pulsar el checkbox
                    Task { await viewModel.alternarCompletado(de: tarea) }
                } alPulsarEditar: {
                    viewModel.seleccionarParaEditar(tarea)
                }
            }
            .onDelete { indices in
                Task { await viewModel.eliminarTareas(en: indices) }
            }
        }
        .listStyle(.insetGrouped)
        .overlay(alignment: .top) {
            if viewModel.estaCargando {
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .refreshable {
            await viewModel.cargarTareas()
        }
    }

    /// Botón "+" en la barra de navegación para crear nuevas tareas.
    private var barraDeHerramientas: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.mostrarFormularioCreacion()
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
            }
            .accessibilityLabel("Nueva tarea")
        }
    }
}

// MARK: - Celda de Tarea

/// Fila individual dentro de la lista de tareas.
struct VistaCeldaTarea: View {

    let tarea: Tarea
    let alPulsarCompletado: () -> Void
    let alPulsarEditar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Botón de completado (checkbox)
            Button(action: alPulsarCompletado) {
                Image(systemName: tarea.completada ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(tarea.completada ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tarea.completada ? "Marcar como pendiente" : "Marcar como completada")

            // Título de la tarea
            VStack(alignment: .leading, spacing: 2) {
                Text(tarea.titulo)
                    .font(.body)
                    .strikethrough(tarea.completada, color: .secondary)
                    .foregroundStyle(tarea.completada ? .secondary : .primary)
                    .lineLimit(2)

                Text("ID: \(tarea.id)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Botón de edición
            Button(action: alPulsarEditar) {
                Image(systemName: "pencil")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Editar tarea")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Vista de Carga Inicial

struct VistaIndicadorCarga: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando tareas…")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Vista de Lista Vacía

struct VistaListaVacia: View {
    var body: some View {
        ContentUnavailableView(
            "Sin tareas",
            systemImage: "checkmark.circle.badge.xmark",
            description: Text("Pulsa el botón + para crear tu primera tarea.")
        )
    }
}

// MARK: - Previews

#Preview("Lista con datos") {
    NavigationStack {
        // Preview usando datos de prueba del modelo
        let vm = TareasViewModel(servicio: ServicioMockTareas(tareas: Tarea.listaDePrueba))
        VistaTareas()
            .environmentObject(vm)
    }
}

#Preview("Lista vacía") {
    VistaListaVacia()
}
