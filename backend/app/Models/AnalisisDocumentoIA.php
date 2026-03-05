<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AnalisisDocumentoIA extends Model
{
    use HasFactory;

    protected $table = 'analisis_documentos_ia';

    protected $fillable = [
        'documento_id',
        'estatus',                    // 'pendiente', 'completado', 'error'
        'datos_detectados',           // JSON con datos médicos encontrados
        'diagnostico_sugerido',       // Diagnóstico propuesto por IA
        'descripcion_analisis',     // Explicación del análisis
        'nivel_confianza',          // 0.0 - 1.0 (probabilidad de acierto)
        'palabras_clave_detectadas', // Array de términos médicos encontrados
        'validado_por',             // ID del doctor que validó
        'estatus_validacion',       // 'pendiente', 'aprobado', 'rechazado', 'corregido'
        'comentario_doctor',        // Feedback del doctor
        'diagnostico_final',        // Diagnóstico corregido por doctor
        'fecha_validacion',
    ];

    protected $casts = [
        'datos_detectados' => 'array',
        'palabras_clave_detectadas' => 'array',
        'nivel_confianza' => 'float',
        'fecha_validacion' => 'datetime',
    ];

    public function documento()
    {
        return $this->belongsTo(DocumentoMedico::class, 'documento_id');
    }

    public function doctorValidador()
    {
        return $this->belongsTo(User::class, 'validado_por');
    }

    public function scopePendientesValidacion($query)
    {
        return $query->where('estatus_validacion', 'pendiente');
    }

    public function scopeValidados($query)
    {
        return $query->whereIn('estatus_validacion', ['aprobado', 'corregido']);
    }

    public function scopeRechazados($query)
    {
        return $query->where('estatus_validacion', 'rechazado');
    }

    public function scopePorConfianza($query, $minimo = 0.7)
    {
        return $query->where('nivel_confianza', '>=', $minimo);
    }

    // Helper para mostrar nivel de confianza
    public function getConfianzaLegibleAttribute()
    {
        $confianza = $this->nivel_confianza * 100;
        
        if ($confianza >= 90) return ['alta', 'bg-green-100 text-green-800'];
        if ($confianza >= 70) return ['media', 'bg-yellow-100 text-yellow-800'];
        if ($confianza >= 50) return ['baja', 'bg-orange-100 text-orange-800'];
        return ['muy baja', 'bg-red-100 text-red-800'];
    }

    // Helper para badge de estatus
    public function getBadgeValidacionAttribute()
    {
        $badges = [
            'pendiente' => ['Pendiente', 'bg-gray-100 text-gray-800'],
            'aprobado' => ['Aprobado', 'bg-green-100 text-green-800'],
            'rechazado' => ['Rechazado', 'bg-red-100 text-red-800'],
            'corregido' => ['Corregido', 'bg-blue-100 text-blue-800'],
        ];
        
        return $badges[$this->estatus_validacion] ?? ['Desconocido', 'bg-gray-100'];
    }
}
