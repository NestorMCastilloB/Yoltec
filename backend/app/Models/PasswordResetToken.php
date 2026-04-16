<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PasswordResetToken extends Model
{
    protected $fillable = ['user_id', 'token', 'expires_at', 'used'];
    protected $casts = ['expires_at' => 'datetime', 'used' => 'boolean'];
}
