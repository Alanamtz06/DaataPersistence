// ─── controladores/tareasControlador.js ──────────────────────────────────────
// Capa de lógica de negocio para el recurso "tareas".
// Lee y escribe en datos/tareas.json como almacenamiento persistente.

const fs   = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Ruta absoluta al archivo de almacenamiento (independiente del CWD)
const rutaArchivo = path.join(__dirname, '../datos/tareas.json');

// ─── Helpers privados ─────────────────────────────────────────────────────────

/**
 * Lee el archivo JSON y devuelve el arreglo de tareas.
 * Si el archivo no existe o su contenido no es válido, retorna un arreglo vacío.
 * @returns {Array} Lista de tareas almacenadas.
 */
const leerTareas = () => {
    try {
        const contenido = fs.readFileSync(rutaArchivo, 'utf-8');
        return JSON.parse(contenido);
    } catch (error) {
        return [];
    }
};

/**
 * Escribe el arreglo de tareas en el archivo JSON con formato legible.
 * @param {Array} tareas - Arreglo de tareas a persistir.
 */
const guardarTareas = (tareas) => {
    fs.writeFileSync(rutaArchivo, JSON.stringify(tareas, null, 2), 'utf-8');
};

// ─── Controladores exportados ─────────────────────────────────────────────────

/**
 * GET /tareas
 * Devuelve todas las tareas almacenadas.
 * Responde 200 con el arreglo (puede ser vacío).
 */
const obtenerTareas = (req, res) => {
    try {
        const tareas = leerTareas();
        return res.status(200).json(tareas);
    } catch (error) {
        return res.status(500).json({ error: 'Error interno al obtener las tareas.' });
    }
};

/**
 * POST /tareas
 * Crea una nueva tarea con los datos del cuerpo de la petición.
 * Campo requerido: titulo (string no vacío).
 * Responde 201 con la tarea creada.
 */
const crearTarea = (req, res) => {
    try {
        const { titulo } = req.body;

        // Validar que el titulo esté presente y no sea vacío
        if (!titulo || typeof titulo !== 'string' || titulo.trim() === '') {
            return res.status(400).json({
                error: 'El campo "titulo" es obligatorio y no puede estar vacío.'
            });
        }

        const nuevaTarea = {
            id:             uuidv4(),
            titulo:         titulo.trim(),
            estaCompletada: false,
            fechaCreacion:  new Date().toISOString()
        };

        const tareas = leerTareas();
        tareas.push(nuevaTarea);
        guardarTareas(tareas);

        return res.status(201).json(nuevaTarea);
    } catch (error) {
        return res.status(500).json({ error: 'Error interno al crear la tarea.' });
    }
};

/**
 * PUT /tareas/:id
 * Actualiza el titulo y/o estaCompletada de una tarea existente.
 * Al menos uno de los dos campos debe estar presente en el cuerpo.
 * Responde 200 con la tarea actualizada, o 404 si el id no existe.
 */
const actualizarTarea = (req, res) => {
    try {
        const { id }                     = req.params;
        const { titulo, estaCompletada } = req.body;

        // Validar que se envíe al menos un campo actualizable
        if (titulo === undefined && estaCompletada === undefined) {
            return res.status(400).json({
                error: 'Se debe enviar al menos "titulo" o "estaCompletada" para actualizar.'
            });
        }

        // Validar tipo de titulo si está presente
        if (titulo !== undefined && (typeof titulo !== 'string' || titulo.trim() === '')) {
            return res.status(400).json({
                error: 'El campo "titulo" debe ser un texto no vacío.'
            });
        }

        // Validar tipo de estaCompletada si está presente
        if (estaCompletada !== undefined && typeof estaCompletada !== 'boolean') {
            return res.status(400).json({
                error: 'El campo "estaCompletada" debe ser un valor booleano (true o false).'
            });
        }

        const tareas = leerTareas();
        const indice = tareas.findIndex(tarea => tarea.id === id);

        if (indice === -1) {
            return res.status(404).json({
                error: `No se encontró ninguna tarea con id "${id}".`
            });
        }

        // Aplicar solo los campos enviados (actualización parcial)
        if (titulo !== undefined)         tareas[indice].titulo         = titulo.trim();
        if (estaCompletada !== undefined) tareas[indice].estaCompletada = estaCompletada;

        guardarTareas(tareas);

        return res.status(200).json(tareas[indice]);
    } catch (error) {
        return res.status(500).json({ error: 'Error interno al actualizar la tarea.' });
    }
};

module.exports = { obtenerTareas, crearTarea, actualizarTarea };
