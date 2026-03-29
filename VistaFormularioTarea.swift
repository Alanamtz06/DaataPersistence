// MARK: - VistaFormularioTarea.swift
// Formulario reutilizable para crear una nueva tarea o editar una existente.
// El modo se determina automáticamente según `viewModel.tareaParaEditar`.

import SwiftUI

// MARK: - Formulario de Tarea

struct VistaFormularioTarea: View {

    // MARK: - Dependencias

    @ObservedObject var viewModel: TareasViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Estado local del formulario

    @State private var titulo: String = ""
    @State private var completada: Bool = false
    @FocusState private var campoActivo: Bool

    // MARK: - Estado computado

    private var esEdicion: Bool { viewModel.tareaParaEditar != nil }
    private var tituloNavegacion: String { esEdicion ? "Editar Tarea" : "Nueva Tarea" }
    private var formularioValido: Bool { !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // MARK: - Cuerpo de la vista

    var body: some View {
        NavigationStack {
            Form {
                seccionTitulo
                if esEdicion { seccionEstado }
            }
            .navigationTitle(tituloNavegacion)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { barraFormulario }
            .onAppear { cargarDatosIniciales() }
            .disabled(viewModel.estaCargando)
            .overlay {
                if viewModel.estaCargando {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                    ProgressView("Guardando…")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Secciones del formulario

    private var seccionTitulo: some View {
        Section {
            TextField("Escribe el título de la tarea", text: $titulo, axis: .vertical)
                .lineLimit(3...6)
                .focused($campoActivo)
                .submitLabel(.done)
        } header: {
            Text("Título")
        } footer: {
            if titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && campoActivo {
                Text("El título no puede estar vacío.")
                    .foregroundStyle(.red)
            }
        }
    }

    private var seccionEstado: some View {
        Section("Estado") {
            Toggle("Completada", isOn: $completada)
                .tint(.green)
        }
    }

    // MARK: - Barra de herramientas

    private var barraFormulario: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    viewModel.cerrarFormulario()
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await guardar() }
                }
                .disabled(!formularioValido)
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Lógica del formulario

    /// Rellena los campos si estamos en modo edición.
    private func cargarDatosIniciales() {
        if let tarea = viewModel.tareaParaEditar {
            titulo     = tarea.titulo
            completada = tarea.completada
        }
        campoActivo = true
    }

    /// Llama al ViewModel para crear o actualizar según el modo activo.
    private func guardar() async {
        if let tarea = viewModel.tareaParaEditar {
            await viewModel.actualizarTarea(tarea, nuevoTitulo: titulo, completada: completada)
        } else {
            await viewModel.crearTarea(titulo: titulo)
        }
        // Solo cerramos si no hubo error
        if viewModel.errorActual == nil {
            viewModel.cerrarFormulario()
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Formulario - Crear") {
    VistaFormularioTarea(viewModel: TareasViewModel(servicio: ServicioMockTareas()))
}

#Preview("Formulario - Editar") {
    let vm = TareasViewModel(servicio: ServicioMockTareas())
    vm.tareaParaEditar = Tarea.ejemplo
    return VistaFormularioTarea(viewModel: vm)
}
