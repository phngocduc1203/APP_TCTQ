<?php

namespace App\Services;

use App\Models\Habit;
use App\Models\User;
use App\Models\ProcrastinationAlert;
use App\Models\ProcrastinationPattern;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Collection;

class ProcrastinationDetectionService
{
    /**
     * Quét tất cả thói quen của user để phát hiện trì hoãn
     */
    public function detectProcrastinationForUser(User $user): Collection
    {
        $alerts = collect();
        $habits = $user->habits()->where('completed', false)->get();

        Log::info("🔍 Scanning habits for user {$user->id}", [
            'total_habits' => $habits->count()
        ]);

        foreach ($habits as $habit) {
            $daysDelayed = $this->calculateDaysDelayed($habit);
            
            Log::info("📋 Habit: {$habit->ten_thoi_quen}", [
                'habit_id' => $habit->id,
                'repeat_type' => $habit->repeat_type,
                'completed_date' => $habit->completed_date,
                'days_delayed' => $daysDelayed,
            ]);
            
            if ($daysDelayed > 0) {
                $shouldAlert = $this->shouldAlert($habit, $daysDelayed);
                
                Log::info("⚠️ Should alert?", [
                    'habit_id' => $habit->id,
                    'days_delayed' => $daysDelayed,
                    
                ]);
                
                if ($daysDelayed > 0 && $this->shouldAlert($habit, $daysDelayed)) {
    $alert = $this->createAlert($user, $habit, $daysDelayed);
    $alerts->push($alert);
    $this->updatePattern($user, $habit, $daysDelayed);
    
    Log::info("✅ Alert created", ['alert_id' => $alert->id]);
}
            }
        }

        return $alerts;
    }

    /**
 * Tính số ngày trì hoãn dựa trên completed_date
 */
private function calculateDaysDelayed(Habit $habit): int
{
    if (!$habit->completed_date) {
        // Nếu chưa từng hoàn thành, tính từ start_date hoặc created_at
        $startDate = $habit->start_date ?? $habit->created_at;
        return now()->startOfDay()->diffInDays(Carbon::parse($startDate)->startOfDay());
    }

    // Tính số ngày từ lần hoàn thành cuối (hôm nay - completed_date)
    $lastCompletedDate = Carbon::parse($habit->completed_date)->startOfDay();
    $today = now()->startOfDay();
    
    // Nếu completed_date là hôm nay hoặc tương lai → không trì hoãn
    if ($lastCompletedDate->gte($today)) {
        return 0;
    }
    
    // Tính số ngày đã trôi qua
   return $lastCompletedDate->diffInDays($today);  // Đổi thứ tự
   }

    /**
     * Kiểm tra xem có nên cảnh báo dựa trên repeat_type
     */
    private function shouldAlert(Habit $habit, int $daysDelayed): bool
    {
        if ($daysDelayed === 0) {
            return false;
        }

        switch ($habit->repeat_type) {
            case 'daily':
                return $daysDelayed >= 1;
                
            case 'weekly':
                if ($habit->repeat_data) {
                    // Parse repeat_data - có thể là JSON hoặc string
                    $days = $this->parseRepeatData($habit->repeat_data);
                    
                    if (!empty($days) && is_array($days)) {
                        $currentDay = now()->dayOfWeek;
                        // Laravel: 0=Sunday, 1=Monday... 6=Saturday
                        // Chỉ cảnh báo nếu hôm nay là ngày cần làm
                        return in_array($currentDay, $days) && $daysDelayed >= 1;
                    }
                }
                // Nếu không có repeat_data hoặc parse lỗi, cảnh báo sau 7 ngày
                return $daysDelayed >= 7;
                
            case 'monthly':
                if ($habit->repeat_data) {
                    $dates = $this->parseRepeatData($habit->repeat_data);
                    
                    if (!empty($dates) && is_array($dates)) {
                        $currentDate = now()->day;
                        return in_array($currentDate, $dates) && $daysDelayed >= 1;
                    }
                }
                // Nếu không có repeat_data, cảnh báo sau 30 ngày
                return $daysDelayed >= 30;
                
            default:
                return $daysDelayed >= 1;
        }
    }
    
    /**
     * Parse repeat_data từ nhiều format khác nhau
     */
    private function parseRepeatData($data): ?array
    {
        if (empty($data)) {
            return null;
        }
        
        // Nếu đã là array
        if (is_array($data)) {
            return array_map('intval', $data);
        }
        
        // Nếu là JSON string
        if (is_string($data)) {
            // Thử parse JSON
            $decoded = json_decode($data, true);
            if (is_array($decoded)) {
                return array_map('intval', $decoded);
            }
            
            // Thử parse dạng "1,2,3,4"
            if (strpos($data, ',') !== false) {
                return array_map('intval', explode(',', $data));
            }
            
            // Thử parse dạng single number
            if (is_numeric($data)) {
                return [(int)$data];
            }
        }
        
        return null;
    }

    /**
     * Tạo alert mới
     */
    private function createAlert(User $user, Habit $habit, int $daysDelayed): ProcrastinationAlert
    {
        // Kiểm tra xem đã có alert cho habit này trong ngày hôm nay chưa
        $existingAlert = ProcrastinationAlert::where('user_id', $user->id)
            ->where('habit_id', $habit->id)
            ->whereDate('sent_at', now())
            ->first();

        if ($existingAlert) {
            return $existingAlert;
        }

        $message = ProcrastinationAlert::generateMessage($daysDelayed, $habit->ten_thoi_quen);
        $severity = ProcrastinationAlert::getSeverity($daysDelayed);

        return ProcrastinationAlert::create([
            'user_id' => $user->id,
            'habit_id' => $habit->id,
            'days_delayed' => $daysDelayed,
            'severity' => $severity,
            'message' => $message,
            'is_read' => false,
            'sent_at' => now(),
        ]);
    }

    /**
     * Cập nhật pattern phát hiện trì hoãn
     */
    private function updatePattern(User $user, Habit $habit, int $daysDelayed): void
    {
        $pattern = ProcrastinationPattern::firstOrCreate(
            [
                'user_id' => $user->id,
                'habit_id' => $habit->id,
            ],
            [
                'total_delays' => 0,
                'max_delay_days' => 0,
                'avg_delay_days' => 0,
                'completion_rate' => 100,
                'pattern_type' => 'good',
            ]
        );

        $pattern->updatePattern($daysDelayed);
    }

    /**
     * Lấy phân tích tổng quan cho user
     */
    public function getUserAnalysis(User $user): array
    {
        $patterns = ProcrastinationPattern::where('user_id', $user->id)->get();
        
        if ($patterns->isEmpty()) {
            return [
                'overall_status' => 'good',
                'message' => '🟢 Tuyệt vời! Bạn chưa có dấu hiệu trì hoãn.',
                'total_habits' => 0,
                'danger_habits' => 0,
                'warning_habits' => 0,
            ];
        }

        $dangerCount = $patterns->where('pattern_type', 'danger')->count();
        $warningCount = $patterns->where('pattern_type', 'warning')->count();
        $totalCount = $patterns->count();

        $avgDelay = $patterns->avg('avg_delay_days');

        if ($avgDelay > 5 || $dangerCount > 0) {
            $status = 'danger';
            $message = "🔴 Nguy hiểm! Bạn có xu hướng trì hoãn nặng. Hãy chia nhỏ công việc và bắt đầu với bước đơn giản nhất.";
        } elseif ($avgDelay > 2 || $warningCount > 0) {
            $status = 'warning';
            $message = "🟡 Cảnh báo! Bạn đang có dấu hiệu trì hoãn. Hãy cam kết làm việc 15 phút mỗi ngày.";
        } else {
            $status = 'good';
            $message = "🟢 Tốt lắm! Bạn đang theo dõi công việc đều đặn. Tiếp tục duy trì!";
        }

        return [
            'overall_status' => $status,
            'message' => $message,
            'total_habits' => $totalCount,
            'danger_habits' => $dangerCount,
            'warning_habits' => $warningCount,
            'avg_delay_days' => round($avgDelay, 1),
        ];
    }

    /**
     * Lấy tất cả alerts chưa đọc của user
     */
    public function getUnreadAlerts(User $user): Collection
    {
        return ProcrastinationAlert::with('habit')
            ->where('user_id', $user->id)
            ->where('is_read', false)
            ->orderBy('severity', 'desc')
            ->orderBy('days_delayed', 'desc')
            ->get();
    }

    /**
     * Đánh dấu alert đã đọc
     */
    public function markAlertAsRead(int $alertId): bool
    {
        $alert = ProcrastinationAlert::find($alertId);
        if ($alert) {
            $alert->is_read = true;
            return $alert->save();
        }
        return false;
    }
}