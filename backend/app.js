// ─── app.js ───────────────────────────────────────────────────────────────────
// Punto de entrada del servidor Express.
// Configura middleware global, monta las rutas y arranca en el puerto 3000.

const express     = require('express');
const cors        = require('cors');
const rutasTareas = require('./rutas/tareas');

const app  = express();
const PORT = 3000;

// ─── Middleware ───────────────────────────────────────────────────────────────

// Habilitar CORS para todas las origenes (necesario para el simulador de iOS)
app.use(cors());

// Parsear cuerpos JSON en las peticiones entrantes
app.use(express.json());

// ─── Rutas ────────────────────────────────────────────────────────────────────

// Montar todas las rutas del recurso "tareas" bajo /tareas
app.use('/tareas', rutasTareas);

// ─── Arranque del servidor ────────────────────────────────────────────────────

app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
