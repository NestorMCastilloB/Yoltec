<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DiaEspecial extends Model
{
    protected $table = 'dias_especiales';
    protected $fillable = ['fecha', 'tipo', 'etiqueta'];
    protected $casts = ['fecha' => 'date'];
}
