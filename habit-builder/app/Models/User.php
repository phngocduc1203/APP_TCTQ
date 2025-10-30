<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Passport\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\HasMany;


class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
   protected $fillable = [
    'name',
    'email',
    'password',
    'age',        
    'gender',    
    'avatar',
    'plant_xp',
    'plant_last_update',
    'plant_status',
    'consecutive_days',        // ✅ THÊM
    'last_completed_date',    
];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
        'plant_last_update' => 'datetime',
        'email_verified_at' => 'datetime',
        'last_completed_date' => 'date',  // ✅ THÊM
        'age' => 'integer',
        'plant_xp' => 'integer',
        'consecutive_days' => 'integer',  // ✅ THÊM
        ];
    }

    /**
     * Quan hệ: Một user có nhiều habits
     */
    public function habits()
    {
        return $this->hasMany(Habit::class);
    }

public function procrastinationAlerts(): HasMany
{
    return $this->hasMany(ProcrastinationAlert::class);
}

/**
 * Relationship với procrastination patterns
 */
public function procrastinationPatterns(): HasMany
{
    return $this->hasMany(ProcrastinationPattern::class);
}

/**
 * Lấy alerts chưa đọc
 */
public function unreadAlerts(): HasMany
{
    return $this->procrastinationAlerts()
                ->where('is_read', false)
                ->orderBy('severity', 'desc')
                ->orderBy('days_delayed', 'desc');
}

/**
 * Kiểm tra xem user có đang trì hoãn không
 */
public function isProcrastinating(): bool
{
    return $this->unreadAlerts()->exists();
}

/**
 * Lấy số lượng alerts chưa đọc
 */
public function getUnreadAlertsCountAttribute(): int
{
    return $this->unreadAlerts()->count();
} 
}