-- SQL para crear tablas manualmente en SQLite
-- Ejecutar: sqlite3 database/database.sqlite < database/schema_sqlite.sql

-- Tabla two_factor_codes
CREATE TABLE IF NOT EXISTS two_factor_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    used BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    entity_id INTEGER NULL,
    old_values TEXT NULL,
    new_values TEXT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT NOT NULL,
    reason TEXT NULL,
    severity VARCHAR(255) DEFAULT 'low' CHECK(severity IN ('low', 'medium', 'high', 'critical')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla documentos_medicos
CREATE TABLE IF NOT EXISTS documentos_medicos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    paciente_id INTEGER NOT NULL,
    subido_por INTEGER NOT NULL,
    tipo_documento VARCHAR(255) DEFAULT 'otro' CHECK(tipo_documento IN ('laboratorio', 'rayos_x', 'receta_externa', 'historial', 'notas_clinicas', 'otro')),
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo VARCHAR(255) NOT NULL,
    mime_type VARCHAR(255) NOT NULL,
    tamano_bytes INTEGER NOT NULL,
    texto_extraido TEXT NULL,
    estatus_procesamiento VARCHAR(255) DEFAULT 'pendiente' CHECK(estatus_procesamiento IN ('pendiente', 'procesando', 'completado', 'error')),
    datos_extraidos TEXT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla analisis_documentos_ia
CREATE TABLE IF NOT EXISTS analisis_documentos_ia (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    documento_id INTEGER NOT NULL,
    estatus VARCHAR(255) DEFAULT 'pendiente' CHECK(estatus IN ('pendiente', 'completado', 'error')),
    datos_detectados TEXT NULL,
    diagnostico_sugerido VARCHAR(255) NULL,
    descripcion_analisis TEXT NULL,
    nivel_confianza DECIMAL(3,2) NULL,
    palabras_clave_detectadas TEXT NULL,
    validado_por INTEGER NULL,
    estatus_validacion VARCHAR(255) DEFAULT 'pendiente' CHECK(estatus_validacion IN ('pendiente', 'aprobado', 'rechazado', 'corregido')),
    comentario_doctor TEXT NULL,
    diagnostico_final VARCHAR(255) NULL,
    fecha_validacion DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Agregar columna es_admin a users si no existe
-- Nota: En SQLite no podemos usar ALTER TABLE ADD COLUMN con AFTER
-- La columna se agregará al final de la tabla
-- PRAGMA table_info(users) nos diría si la columna ya existe
