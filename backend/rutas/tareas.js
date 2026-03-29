// ─── rutas/tareas.js ──────────────────────────────────────────────────────────
// Define los endpoints REST para el recurso "tareas".
// No contiene lógica de negocio; delega en el controlador.

const express           = require('express');
const router            = express.Router();
const tareasControlador = require('../controladores/tareasControlador');

// GET    /tareas        → obtener todas las tareas
router.get('/', tareasControlador.obtenerTareas);

// POST   /tareas        → crear una nueva tarea
router.post('/', tareasControlador.crearTarea);

// PUT    /tareas/:id    → actualizar titulo y/o estaCompletada de una tarea existente
router.put('/:id', tareasControlador.actualizarTarea);

module.exports = router;
