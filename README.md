# DaataPersistence — To-Do List App

Aplicación iOS construida con **SwiftUI** y arquitectura **MVVM** que implementa un CRUD completo conectado a la API REST de [JSONPlaceholder](https://jsonplaceholder.typicode.com/todos).

---

## Arquitectura

```
DaataPersistence/
├── Modelos/
│   └── Tarea.swift                    ← Struct Codable + CodingKeys + helpers
├── Servicios/
│   ├── ProtocoloServicioTareas.swift  ← Contrato del servicio (para mocking)
│   ├── ClienteHTTP.swift              ← HTTP genérico con URLSession
│   ├── ServicioTareas.swift           ← CRUD real (GET/POST/PUT/DELETE)
│   └── ServicioMockTareas.swift       ← Implementación falsa para tests/Previews
├── ViewModels/
│   └── TareasViewModel.swift          ← Lógica de negocio + estados UI
├── Vistas/
│   ├── VistaTareas.swift              ← Lista principal
│   └── VistaFormularioTarea.swift     ← Formulario crear / editar
├── Utilidades/
│   └── ErrorRed.swift                 ← Errores tipados y localizados
└── DaataPersistenceApp.swift          ← Entry point @main

DaataPersistenciaTests/
├── TareaModeloTests.swift             ← 7 casos
├── ClienteHTTPTests.swift             ← 6 casos
├── ServicioTareasTests.swift          ← 8 casos
├── TareasViewModelTests.swift         ← 12 casos
├── ErrorRedTests.swift                ← 9 casos
└── SesionMockHTTP.swift               ← Mock inyectable de URLSession
```

---

## API

| Operación  | Verbo  | Endpoint                      |
|------------|--------|-------------------------------|
| Listar     | GET    | /todos?userId=1&_limit=10     |
| Detalle    | GET    | /todos/{id}                   |
| Crear      | POST   | /todos                        |
| Actualizar | PUT    | /todos/{id}                   |
| Eliminar   | DELETE | /todos/{id}                   |

---

## Testing — 42 casos en 5 suites

```bash
# Xcode
Cmd + U

# Terminal
xcodebuild test -scheme DaataPersistence \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Flujo de Git

```bash
# Subir la rama al remoto
git push origin feature/todo-crud-api

# Crear Pull Request hacia main en GitHub/GitLab
```

---

## Requisitos

- Xcode 16+ / iOS 17+ / Swift 5.9+
