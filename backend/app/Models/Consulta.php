<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Consulta extends Model
{
    protected $fillable = [
        'cita_id',
        'doctor_id',
        'alumno_id',
        'diagnostico',
        'tratamiento',
        'observaciones',
    ];

    public function cita()
    {
        return $this->belongsTo(Cita::class);
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function alumno()
    {
        return $this->belongsTo(User::class, 'alumno_id');
    }
}
