<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CitaController;
use App\Http\Controllers\BitacoraController;
use App\Http\Controllers\RecetaController;
use App\Http\Controllers\PerfilController;

// Rutas públicas
Route::post('/login', [AuthController::class, 'login']);

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
});
