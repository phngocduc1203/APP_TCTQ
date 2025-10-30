<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProcrastinationPattern extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'habit_id',
        'total_delays',
        'max_delay_days',
        'avg_delay_days',
        'completion_rate',
        'pattern_type',
    ];

    protected $casts = [
        'avg_delay_days' => 'float',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function habit(): BelongsTo
    {
        return $this->belongsTo(Habit::class);
    }

    public function updatePattern(int $daysDelayed): void
    {
        $this->total_delays++;
        $this->max_delay_days = max($this->max_delay_days, $daysDelayed);
        
        // Tính lại average
        $this->avg_delay_days = (
            ($this->avg_delay_days * ($this->total_delays - 1)) + $daysDelayed
        ) / $this->total_delays;
        
        // Cập nhật pattern type
        $this->pattern_type = $this->determinePatternType();
        $this->save();
    }

    private function determinePatternType(): string
    {
        if ($this->avg_delay_days > 3 || $this->max_delay_days > 5) {
            return 'danger';
        } elseif ($this->avg_delay_days > 1.5 || $this->max_delay_days > 3) {
            return 'warning';
        }
        return 'good';
    }

    public function getAnalysisMessage(): string
    {
        return match($this->pattern_type) {
            'danger' => "🔴 Nguy hiểm! Bạn có xu hướng trì hoãn nặng với thói quen này. Trung bình trì hoãn {$this->avg_delay_days} ngày. Hãy chia nhỏ công việc!",
            'warning' => "🟡 Cảnh báo! Có dấu hiệu trì hoãn. Trung bình trì hoãn {$this->avg_delay_days} ngày. Cam kết làm 15 phút mỗi ngày!",
            'good' => "🟢 Tốt lắm! Bạn đang duy trì thói quen tốt. Tiếp tục phát huy!",
            default => "Đang phân tích..."
        };
    }
}