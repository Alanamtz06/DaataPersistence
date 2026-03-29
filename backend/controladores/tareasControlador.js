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

module.exports = { obtenerTareas };
