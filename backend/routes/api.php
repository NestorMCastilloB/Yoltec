<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CitaController;
use App\Http\Controllers\BitacoraController;
use App\Http\Controllers\RecetaController;
use App\Http\Controllers\PerfilController;
use App\Http\Controllers\PreEvaluacionIAController;
use App\Http\Controllers\IAPriorityController;
use App\Http\Controllers\IASymptomController;

// Rutas públicas
Route::post('/login', [AuthController::class, 'login']);
Route::post('/verify-2fa', [AuthController::class, 'verifyTwoFactor']);
Route::post('/resend-2fa', [AuthController::class, 'resendTwoFactor']);

// Rutas protegidas (requieren autenticación)
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Perfil
    Route::get('/perfil', [PerfilController::class, 'show']);
    Route::put('/perfil', [PerfilController::class, 'update']);
    Route::post('/perfil/cambiar-password', [PerfilController::class, 'cambiarPassword']);

    // Citas
    Route::get('/citas', [CitaController::class, 'index']);
    Route::get('/citas/disponibilidad', [CitaController::class, 'availability']);
    Route::post('/citas', [CitaController::class, 'store']);
    Route::get('/citas/{id}', [CitaController::class, 'show']);
    Route::post('/citas/{id}/cancelar', [CitaController::class, 'cancelar']);
    Route::post('/citas/{id}/atender', [CitaController::class, 'atender']); // Solo doctor

    // Bitácoras
    Route::get('/bitacoras', [BitacoraController::class, 'index']);
    Route::post('/bitacoras', [BitacoraController::class, 'store']); // Solo doctor
    Route::get('/bitacoras/{id}', [BitacoraController::class, 'show']);
    Route::put('/bitacoras/{id}', [BitacoraController::class, 'update']); // Solo doctor

    // Recetas
    Route::get('/recetas', [RecetaController::class, 'index']);
    Route::post('/recetas', [RecetaController::class, 'store']); // Solo doctor
    Route::get('/recetas/{id}', [RecetaController::class, 'show']);
    Route::put('/recetas/{id}', [RecetaController::class, 'update']); // Solo doctor

    // Pre-evaluaciones IA (sistema anterior - mantener compatibilidad)
    Route::get('/pre-evaluacion/preguntas', [PreEvaluacionIAController::class, 'getPreguntas']);
    Route::get('/pre-evaluacion/pendientes', [PreEvaluacionIAController::class, 'pendientes']);
    Route::get('/pre-evaluacion', [PreEvaluacionIAController::class, 'index']);
    Route::post('/pre-evaluacion', [PreEvaluacionIAController::class, 'store']);
    Route::get('/pre-evaluacion/{id}', [PreEvaluacionIAController::class, 'show']);
    Route::post('/pre-evaluacion/{id}/validar', [PreEvaluacionIAController::class, 'validar']);

    // ===== IA 1: Clasificador de Prioridad (solo doctores) =====
    Route::prefix('ia/priority')->group(function () {
        Route::get('/info', [IAPriorityController::class, 'infoModelos']);
        Route::get('/pendientes', [IAPriorityController::class, 'listarPendientesPorPrioridad']);
        Route::post('/clasificar/{citaId}', [IAPriorityController::class, 'clasificar']);
    });

    // ===== IA 2: Pre-evaluación de Síntomas (alumnos y doctores) =====
    Route::prefix('ia/symptoms')->group(function () {
        Route::get('/listado', [IASymptomController::class, 'listado']); // Solo doctores
        Route::post('/iniciar/{citaId}', [IASymptomController::class, 'iniciar']);
        Route::post('/evaluar/{citaId}', [IASymptomController::class, 'evaluar']);
        Route::get('/resultado/{citaId}', [IASymptomController::class, 'obtenerResultado']);
        Route::post('/validar/{preEvaluacionId}', [IASymptomController::class, 'validar']); // Solo doctores
        Route::delete('/{citaId}', [IASymptomController::class, 'cancelar']);
    });
});

