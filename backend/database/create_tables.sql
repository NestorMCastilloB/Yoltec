-- Crear tabla users
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero_control VARCHAR(255) NULL UNIQUE,
    username VARCHAR(255) NULL,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    tipo VARCHAR(255) DEFAULT 'alumno',
    telefono VARCHAR(255) NULL,
    fecha_nacimiento DATE NULL,
    nip VARCHAR(6) NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

-- Crear tabla citas
CREATE TABLE IF NOT EXISTS citas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    doctor_id INTEGER NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado VARCHAR(255) DEFAULT 'pendiente',
    notas TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

-- Crear tabla bitacoras
CREATE TABLE IF NOT EXISTS bitacoras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cita_id INTEGER NOT NULL,
    diagnostico TEXT NULL,
    presion_arterial VARCHAR(255) NULL,
    glucosa INTEGER NULL,
    temperatura DECIMAL(4,2) NULL,
    peso DECIMAL(5,2) NULL,
    altura DECIMAL(4,2) NULL,
    imc DECIMAL(5,2) NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

-- Crear tabla recetas
CREATE TABLE IF NOT EXISTS recetas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bitacora_id INTEGER NOT NULL,
    medicamentos TEXT NOT NULL,
    indicaciones TEXT NOT NULL,
    fecha_emision DATE NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

-- Crear tabla pre_evaluaciones_ia
CREATE TABLE IF NOT EXISTS pre_evaluaciones_ia (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cita_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    diagnostico_sugerido VARCHAR(255) NULL,
    nivel_confianza DECIMAL(5,2) NULL,
    sintomas TEXT NULL,
    respuestas TEXT NULL,
    estatus VARCHAR(255) DEFAULT 'pendiente',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
