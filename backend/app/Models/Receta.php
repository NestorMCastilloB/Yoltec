<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Receta extends Model
{
    use HasFactory;

    protected $fillable = [
        'cita_id',
        'alumno_id',
        'doctor_id',
        'medicamentos',
        'indicaciones',
        'fecha_emision',
    ];

    protected $casts = [
        'fecha_emision' => 'date:Y-m-d',
    ];

    // Relaciones
    public function cita()
    {
        return $this->belongsTo(Cita::class);
    }

    public function alumno()
    {
        return $this->belongsTo(User::class, 'alumno_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }
}
