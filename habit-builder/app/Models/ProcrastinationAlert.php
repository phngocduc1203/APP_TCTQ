<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProcrastinationAlert extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'habit_id',
        'days_delayed',
        'severity',
        'message',
        'is_read',
        'sent_at',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'sent_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function habit(): BelongsTo
    {
        return $this->belongsTo(Habit::class);
    }

    public static function generateMessage(int $daysDelayed, string $habitName): string
    {
        if ($daysDelayed === 1) {
            return "🤔 Hôm nay bạn chưa hoàn thành '{$habitName}'. Có lẽ bạn đang trì hoãn?";
        } elseif ($daysDelayed === 2) {
            return "⚠️ Đã 2 ngày rồi! Bạn đang trì hoãn '{$habitName}' rõ ràng. Hãy bắt đầu ngay bây giờ!";
        } elseif ($daysDelayed === 3) {
            return "🚨 3 ngày không làm '{$habitName}'! Đây là dấu hiệu nghiêm trọng của thói quen trì hoãn.";
        } else {
            return "🔥 {$daysDelayed} ngày trôi qua mà chưa làm '{$habitName}'! Trì hoãn đang kiểm soát bạn. Hành động NGAY!";
        }
    }

    public static function getSeverity(int $daysDelayed): string
    {
        if ($daysDelayed >= 3) {
            return 'critical';
        } elseif ($daysDelayed >= 2) {
            return 'warning';
        }
        return 'info';
    }
}