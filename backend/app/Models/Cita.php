<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cita extends Model
{
    use HasFactory;

    protected $fillable = [
        'clave_cita',
        'alumno_id',
        'doctor_id',
        'fecha_cita',
        'hora_cita',
        'motivo',
        'estatus',
        'fecha_hora_atencion',
        'notas',
    ];

    protected $casts = [
        'fecha_cita' => 'date:Y-m-d',
        'hora_cita' => 'string',
        'fecha_hora_atencion' => 'datetime',
    ];

    // Relaciones
    public function alumno()
    {
        return $this->belongsTo(User::class, 'alumno_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function bitacora()
    {
        return $this->hasOne(Bitacora::class);
    }

    public function receta()
    {
        return $this->hasOne(Receta::class);
    }

    // Helper para generar clave única
    public static function generarClaveCita()
    {
        do {
            $clave = 'CITA-' . date('Ymd') . '-' . strtoupper(substr(md5(time() . rand()), 0, 6));
        } while (self::where('clave_cita', $clave)->exists());

        return $clave;
    }
}
