<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Habit extends Model
{
    protected $table = 'habits';

    protected $fillable = [
        'user_id',
        'ten_thoi_quen',
        'mo_ta',
        'diem',
        'repeat_type',
        'repeat_data',
        'duration_days',
        'completed_days',
        'completed',
        'completedDate',
        'start_date',
        'is_challenge',
    ];

    protected $casts = [
        'completed' => 'boolean',
        'is_challenge' => 'boolean',
        'completed_days' => 'integer',
        'duration_days' => 'integer',
        'completedDate' => 'datetime',
        'start_date' => 'datetime',
    ];
}
