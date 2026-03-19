<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PreEvaluacionIA extends Model
{
    use HasFactory;

    protected $table = 'pre_evaluaciones_ia';

    protected $fillable = [
        'cita_id',
        'alumno_id',
        'respuestas',
        'diagnostico_sugerido',
        'confianza',
        'sintomas_detectados',
        'estatus_validacion',
        'validado_por',
        'comentario_doctor',
        'fecha_validacion',
    ];

    protected $casts = [
        'respuestas' => 'array',
        'sintomas_detectados' => 'array',
        'confianza' => 'decimal:2',
        'fecha_validacion' => 'datetime',
    ];

    public function cita()
    {
        return $this->belongsTo(Cita::class, 'cita_id');
    }

    public function alumno()
    {
        return $this->belongsTo(User::class, 'alumno_id');
    }

    public function doctorValidador()
    {
        return $this->belongsTo(User::class, 'validado_por');
    }

    public function scopePendientes($query)
    {
        return $query->where('estatus_validacion', 'pendiente');
    }

    public function scopeValidadas($query)
    {
        return $query->where('estatus_validacion', 'validado');
    }

    public function scopeDescartadas($query)
    {
        return $query->where('estatus_validacion', 'descartado');
    }

    public function getBadgeClassAttribute()
    {
        return match($this->estatus_validacion) {
            'validado' => 'bg-green-100 text-green-800',
            'descartado' => 'bg-red-100 text-red-800',
            default => 'bg-yellow-100 text-yellow-800',
        };
    }

    public function getNivelConfianzaLegibleAttribute()
    {
        $confianza = $this->confianza * 100;
        
        return match(true) {
            $confianza >= 80 => ['Muy Alta', 'bg-green-100 text-green-800'],
            $confianza >= 60 => ['Alta', 'bg-blue-100 text-blue-800'],
            $confianza >= 40 => ['Media', 'bg-yellow-100 text-yellow-800'],
            $confianza >= 20 => ['Baja', 'bg-orange-100 text-orange-800'],
            default => ['Muy Baja', 'bg-red-100 text-red-800'],
        };
    }
}
