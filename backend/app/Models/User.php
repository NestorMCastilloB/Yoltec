<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'numero_control',
        'nip',                      // NIP para alumnos
        'username',
        'nombre',
        'apellido',
        'email',
        'password',
        'tipo',
        'es_admin',        // Nuevo campo para rol administrador
        'telefono',
        'fecha_nacimiento',
        'fcm_token',
        'tipo_sangre',
        'alergias',
        'enfermedades_cronicas',
        'foto_perfil',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'nip',        // NIP en texto plano — nunca debe exponerse en respuestas JSON
        'fcm_token',  // Token interno de Firebase — no relevante para el cliente
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'fecha_nacimiento' => 'date',
        'es_admin' => 'boolean',
    ];

    // Relaciones
    public function citasComoAlumno()
    {
        return $this->hasMany(Cita::class, 'alumno_id');
    }

    public function citasComoDoctor()
    {
        return $this->hasMany(Cita::class, 'doctor_id');
    }

    public function bitacorasComoAlumno()
    {
        return $this->hasMany(Bitacora::class, 'alumno_id');
    }

    public function bitacorasComoDoctor()
    {
        return $this->hasMany(Bitacora::class, 'doctor_id');
    }

    public function recetasComoAlumno()
    {
        return $this->hasMany(Receta::class, 'alumno_id');
    }

    public function recetasComoDoctor()
    {
        return $this->hasMany(Receta::class, 'doctor_id');
    }

    // Helper methods
    public function esAlumno()
    {
        return $this->tipo === 'alumno';
    }

    public function esDoctor()
    {
        return $this->tipo === 'doctor';
    }

    public function esAdmin()
    {
        return $this->es_admin === true;
    }

    public function tieneAccesoAdmin()
    {
        return $this->esAdmin() || $this->esDoctor();
    }

    public function puedeValidarDiagnosticos()
    {
        return $this->esAdmin() || $this->esDoctor();
    }

    public function getRolLegibleAttribute()
    {
        if ($this->esAdmin()) return 'Administrador';
        if ($this->esDoctor()) return 'Doctor';
        if ($this->esAlumno()) return 'Paciente';
        return 'Usuario';
    }
}
