<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DocumentoMedico extends Model
{
    use HasFactory;

    protected $table = 'documentos_medicos';

    protected $fillable = [
        'paciente_id',           // Usuario al que pertenece
        'subido_por',            // Quien subió el documento (doctor, admin, alumno)
        'tipo_documento',        // 'laboratorio', 'rayos_x', 'receta_externa', 'historial', 'otro'
        'nombre_archivo',        // Nombre original
        'ruta_archivo',          // Ruta en storage
        'mime_type',             // application/pdf, application/msword, etc.
        'tamano_bytes',          // Tamaño del archivo
        'texto_extraido',        // Texto extraído del PDF/Word para análisis
        'estatus_procesamiento', // 'pendiente', 'procesando', 'completado', 'error'
        'datos_extraidos',       // JSON con datos estructurados (presión, glucosa, etc.)
    ];

    protected $casts = [
        'datos_extraidos' => 'array',
        'tamano_bytes' => 'integer',
    ];

    public function paciente()
    {
        return $this->belongsTo(User::class, 'paciente_id');
    }

    public function subidoPor()
    {
        return $this->belongsTo(User::class, 'subido_por');
    }

    public function analisisIa()
    {
        return $this->hasOne(AnalisisDocumentoIA::class, 'documento_id');
    }

    public function scopePorPaciente($query, $pacienteId)
    {
        return $query->where('paciente_id', $pacienteId);
    }

    public function scopePorTipo($query, $tipo)
    {
        return $query->where('tipo_documento', $tipo);
    }

    public function scopeProcesados($query)
    {
        return $query->where('estatus_procesamiento', 'completado');
    }

    public function scopePendientes($query)
    {
        return $query->where('estatus_procesamiento', 'pendiente');
    }

    // Helper para obtener URL del archivo
    public function getUrlAttribute()
    {
        return asset('storage/' . $this->ruta_archivo);
    }

    // Helper para tamaño legible
    public function getTamanoLegibleAttribute()
    {
        $bytes = $this->tamano_bytes;
        $units = ['B', 'KB', 'MB', 'GB'];
        $unitIndex = 0;

        while ($bytes >= 1024 && $unitIndex < count($units) - 1) {
            $bytes /= 1024;
            $unitIndex++;
        }

        return round($bytes, 2) . ' ' . $units[$unitIndex];
    }
}
