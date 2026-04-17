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
use App\Http\Controllers\EstadisticasController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\PasswordResetController;
use App\Http\Controllers\CalendarioAdminController;
use App\Http\Controllers\ConsultaController;
use App\Http\Controllers\PerfilMedicoController;

// Rutas públicas
Route::middleware('throttle:5,1')->post('/login', [AuthController::class, 'login']); // Fix hallazgo #2: máx 5 intentos/min
Route::middleware('throttle:5,10')->post('/forgot-password', [PasswordResetController::class, 'forgotPassword']);
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword']);
Route::post('/verify-2fa', [AuthController::class, 'verifyTwoFactor']);
Route::post('/resend-2fa', [AuthController::class, 'resendTwoFactor']);

// Rutas protegidas (requieren autenticación)
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/fcm-token', function (Request $request) {
        $request->validate(['fcm_token' => 'required|string']);
        $request->user()->update(['fcm_token' => $request->fcm_token]);
        return response()->json(['message' => 'Token FCM registrado.']);
    });

    // Perfil
    Route::get('/perfil', [PerfilController::class, 'show']);
    Route::put('/perfil', [PerfilController::class, 'update']);
    Route::post('/perfil/foto', [PerfilController::class, 'subirFoto']);
    Route::post('/perfil/cambiar-password', [PerfilController::class, 'cambiarPassword']);

    // Citas
    Route::get('/citas', [CitaController::class, 'index']);
    Route::get('/citas/disponibilidad', [CitaController::class, 'availability']);
    Route::post('/citas', [CitaController::class, 'store']);
    Route::get('/citas/{id}', [CitaController::class, 'show']);
    Route::post('/citas/{id}/cancelar', [CitaController::class, 'cancelar']);
    Route::put('/citas/{id}/reprogramar', [CitaController::class, 'reprogramar']);  // Solo doctor
    Route::post('/citas/{id}/atender', [CitaController::class, 'atender']);       // Solo doctor
    Route::post('/citas/{id}/no-asistio', [CitaController::class, 'noAsistio']); // Solo doctor
    Route::post('/citas/{id}/consulta', [ConsultaController::class, 'store']);   // Solo doctor
    Route::get('/citas/{id}/consulta', [ConsultaController::class, 'show']);

    // Perfil médico e historial
    Route::get('/perfil-medico', [PerfilMedicoController::class, 'show']);
    Route::put('/perfil-medico', [PerfilMedicoController::class, 'update']);
    Route::get('/perfil-medico/historial', [PerfilMedicoController::class, 'historial']);
    Route::get('/perfil-medico/alumno/{id}', [PerfilMedicoController::class, 'show']);         // Doctor ve perfil de alumno
    Route::get('/perfil-medico/alumno/{id}/historial', [PerfilMedicoController::class, 'historial']); // Doctor ve historial de alumno

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

    // Pre-evaluaciones IA
    Route::post('/pre-evaluacion/chat', [PreEvaluacionIAController::class, 'chat']);
    Route::get('/pre-evaluacion/preguntas', [PreEvaluacionIAController::class, 'getPreguntas']);
    Route::get('/pre-evaluacion/pendientes', [PreEvaluacionIAController::class, 'pendientes']);
    Route::get('/pre-evaluacion', [PreEvaluacionIAController::class, 'index']);
    Route::post('/pre-evaluacion', [PreEvaluacionIAController::class, 'store']);
    Route::get('/pre-evaluacion/{id}', [PreEvaluacionIAController::class, 'show']);
    Route::post('/pre-evaluacion/{id}/validar', [PreEvaluacionIAController::class, 'validar']);

    // Estadísticas (solo doctores)
    Route::get('/estadisticas', [EstadisticasController::class, 'index']);

    // Admin - CRUD alumnos y doctores
    Route::prefix('admin')->group(function () {
        Route::get('/calendario',        [CalendarioAdminController::class, 'index']);
        Route::post('/calendario',       [CalendarioAdminController::class, 'store']);
        Route::delete('/calendario/{id}', [CalendarioAdminController::class, 'destroy']);
        Route::get('/alumnos',           [AdminController::class, 'indexAlumnos']);
        Route::post('/alumnos',          [AdminController::class, 'storeAlumno']);
        Route::put('/alumnos/{id}',      [AdminController::class, 'updateAlumno']);
        Route::delete('/alumnos/{id}',   [AdminController::class, 'destroyAlumno']);
        Route::get('/doctores',          [AdminController::class, 'indexDoctores']);
        Route::post('/doctores',         [AdminController::class, 'storeDoctor']);
        Route::put('/doctores/{id}',     [AdminController::class, 'updateDoctor']);
        Route::delete('/doctores/{id}',  [AdminController::class, 'destroyDoctor']);
    });

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

