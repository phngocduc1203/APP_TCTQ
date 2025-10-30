<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class StreakController extends Controller
{
    public function getStreakInfo(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today()->toDateString();
        $lastDate = $user->last_completed_date;
        
        // Kiểm tra có nguy cơ mất streak không
        $isAtRisk = false;
        $hoursRemaining = 0;
        
        if ($lastDate) {
            $yesterday = Carbon::yesterday()->toDateString();
            $dayBeforeYesterday = Carbon::yesterday()->subDay()->toDateString();
            
            // Nguy cơ mất streak nếu:
            // - Hôm qua chưa làm VÀ có streak >= 3
            if ($lastDate < $yesterday && ($user->consecutive_days ?? 0) >= 3) {
                $isAtRisk = true;
                $now = Carbon::now();
                $midnight = Carbon::tomorrow()->startOfDay();
                $hoursRemaining = $now->diffInHours($midnight);
            }
        }
        
        return response()->json([
            'consecutive_days' => $user->consecutive_days ?? 0,
            'last_completed_date' => $user->last_completed_date,
            'streak_freeze_used' => $user->streak_freeze_used ?? 0,
            'streak_freeze_month' => $user->streak_freeze_month,
            'can_use_freeze' => $this->canUseFreeze($user),
            'is_at_risk' => $isAtRisk,
            'hours_remaining' => $hoursRemaining,
        ]);
    }

    public function updateStreak(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today()->toDateString();
        $lastDate = $user->last_completed_date;

        // Nếu đã làm hôm nay rồi → không tăng streak
        if ($lastDate === $today) {
            return response()->json([
                'success' => false,
                'message' => 'Đã hoàn thành hôm nay',
                'consecutive_days' => $user->consecutive_days,
                'already_completed' => true,
            ]);
        }

        $yesterday = Carbon::yesterday()->toDateString();
        $newStreak = $user->consecutive_days ?? 0;
        $usedFreeze = false;
        $lostStreak = false;

        // Kiểm tra có bỏ lỡ ngày không
        if ($lastDate === $yesterday) {
            // Liên tiếp → Tăng streak
            $newStreak++;
        } elseif ($lastDate === null || $lastDate < $yesterday) {
            // Bỏ lỡ → Kiểm tra khôi phục
            if ($this->canUseFreeze($user) && $newStreak >= 3) {
                // Tự động khôi phục
                $this->useStreakFreeze($user);
                $newStreak++; // Vẫn tăng streak
                $usedFreeze = true;
            } else {
                // Mất streak
                $lostStreak = true;
                $newStreak = 1; // Reset về 1
            }
        } else {
            // Ngày đầu tiên
            $newStreak = 1;
        }

        $user->consecutive_days = $newStreak;
        $user->last_completed_date = $today;
        $user->save();

        $message = "Streak: $newStreak ngày";
        
        if ($usedFreeze) {
            $remaining = 3 - $user->streak_freeze_used;
            $message = "🛡️ Đã khôi phục streak! Còn $remaining lần khôi phục. Streak: $newStreak ngày";
        } elseif ($lostStreak) {
            $message = "😢 Đã mất streak do bỏ lỡ! Bắt đầu lại từ 1 ngày";
        } elseif ($newStreak >= 3) {
            $message = "🔥 Streak: $newStreak ngày liên tiếp!";
        }

        return response()->json([
            'success' => true,
            'consecutive_days' => $newStreak,
            'message' => $message,
            'used_freeze' => $usedFreeze,
            'lost_streak' => $lostStreak,
        ]);
    }

    public function useStreakFreeze(Request $request)
    {
        $user = $request->user();

        if (!$this->canUseFreeze($user)) {
            return response()->json([
                'success' => false,
                'message' => 'Đã hết lượt khôi phục tháng này',
            ], 400);
        }

        $currentMonth = Carbon::now()->format('Y-m');

        // Reset nếu sang tháng mới
        if ($user->streak_freeze_month !== $currentMonth) {
            $user->streak_freeze_used = 0;
            $user->streak_freeze_month = $currentMonth;
        }

        $user->streak_freeze_used++;
        $user->save();

        return response()->json([
            'success' => true,
            'streak_freeze_used' => $user->streak_freeze_used,
            'remaining' => 3 - $user->streak_freeze_used,
        ]);
    }

    private function canUseFreeze($user)
    {
        $currentMonth = Carbon::now()->format('Y-m');

        // Reset nếu sang tháng mới
        if ($user->streak_freeze_month !== $currentMonth) {
            return true;
        }

        return ($user->streak_freeze_used ?? 0) < 3;
    }

    // 🔔 API MỚI: Kiểm tra cần thông báo không
    public function checkStreakWarning(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today()->toDateString();
        $lastDate = $user->last_completed_date;
        $currentStreak = $user->consecutive_days ?? 0;

        // Chỉ cảnh báo nếu có streak >= 3
        if ($currentStreak < 3) {
            return response()->json([
                'should_notify' => false,
            ]);
        }

        // Nếu hôm nay chưa làm → Cần thông báo
        if ($lastDate !== $today) {
            $now = Carbon::now();
            $midnight = Carbon::tomorrow()->startOfDay();
            $hoursRemaining = $now->diffInHours($midnight);

            return response()->json([
                'should_notify' => true,
                'consecutive_days' => $currentStreak,
                'hours_remaining' => $hoursRemaining,
                'can_use_freeze' => $this->canUseFreeze($user),
                'freeze_remaining' => 3 - ($user->streak_freeze_used ?? 0),
            ]);
        }

        return response()->json([
            'should_notify' => false,
        ]);
    }
}