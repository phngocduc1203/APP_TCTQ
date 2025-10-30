<?php

namespace App\Http\Controllers\Api;

use App\Models\Habit;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class HabitController extends Controller
{
    // 🟩 Đánh dấu hoàn thành thói quen
    public function complete(Request $request, $id)
{
    try {
        $habit = Habit::where('id', $id)
                      ->where('user_id', Auth::id())
                      ->firstOrFail();

        $today = Carbon::now()->toDateString();

        // Kiểm tra xem đã hoàn thành hôm nay chưa
        if ($habit->completed_date && Carbon::parse($habit->completed_date)->toDateString() === $today) {
            Log::info('Habit already completed today', [
                'habit_id' => $habit->id,
                'user_id' => Auth::id(),
                'completed_date' => $habit->completed_date,
            ]);
            return response()->json([
                'success' => true,
                'already_completed' => true,
                'message' => 'Bạn đã hoàn thành thói quen này hôm nay rồi!',
                'habit' => $habit
            ], 200);
        }

        // ✅ BẮT ĐẦU LOGIC STREAK & XP
        /** @var \App\Models\User $user */
        $user = Auth::user();
        
        // 1. Cập nhật streak
        $lastCompletedDate = $user->last_completed_date;
        $consecutiveDays = $user->consecutive_days ?? 0;
        
        if ($lastCompletedDate) {
            $lastDate = Carbon::parse($lastCompletedDate);
            $todayDate = Carbon::parse($today);
            $diffDays = $lastDate->diffInDays($todayDate);
            
            if ($diffDays == 1) {
                // Ngày kế tiếp → tăng streak
                $consecutiveDays += 1;
            } elseif ($diffDays > 1) {
                // Bỏ qua ngày → reset streak
                $consecutiveDays = 1;
            }
            // Nếu diffDays == 0 (cùng ngày) → giữ nguyên streak
        } else {
            // Lần đầu tiên
            $consecutiveDays = 1;
        }
        
        // 2. Tính XP
        $xpPerHabit = 5; // XP cố định mỗi habit
        $maxXp = 1200;
        $dailyLimit = 50; // Giới hạn XP mỗi ngày
        
        // Lấy daily XP (tổng XP đã nhận hôm nay)
        $dailyXpKey = 'daily_xp_' . $today;
        $dailyXp = cache()->get($dailyXpKey . '_' . $user->id, 0);
        
        // Kiểm tra daily limit
        if ($dailyXp >= $dailyLimit) {
            return response()->json([
                'success' => false,
                'message' => "Đã đạt giới hạn XP hôm nay ($dailyLimit XP)",
                'daily_xp' => $dailyXp,
                'daily_limit' => $dailyLimit,
            ], 200);
        }
        
        // Tính XP thực tế nhận được (không vượt daily limit)
        $actualXp = min($xpPerHabit, $dailyLimit - $dailyXp);
        $newDailyXp = $dailyXp + $actualXp;
        
        // 3. Kiểm tra streak bonus (mỗi 7 ngày)
        $bonusXp = 0;
        if ($consecutiveDays > 0 && $consecutiveDays % 7 == 0) {
            $bonusXp = 10;
        }
        
        // 4. Cập nhật plant_xp
        $currentPlantXp = $user->plant_xp ?? 0;
        $totalXpGain = $actualXp + $bonusXp;
        $newPlantXp = min($currentPlantXp + $totalXpGain, $maxXp);
        
        // 5. Lưu vào database
        $user->update([
            'plant_xp' => $newPlantXp,
            'plant_status' => 'healthy',
            'plant_last_update' => now(),
            'consecutive_days' => $consecutiveDays,
            'last_completed_date' => $today,
        ]);
        
        // 6. Lưu daily XP vào cache (reset sau 24h)
        cache()->put(
            $dailyXpKey . '_' . $user->id, 
            $newDailyXp, 
            now()->endOfDay()
        );

        // 7. Cập nhật habit
        $habit->completed_days = ($habit->completed_days ?? 0) + 1;
        $habit->completed_date = $today;

        if ($habit->duration_days && $habit->completed_days >= $habit->duration_days) {
            $habit->completed = true;
        }

        $habit->save();

        // 8. Tạo message
        $message = "Hoàn thành thành công! +{$actualXp} XP";
        if ($bonusXp > 0) {
            $message .= " + {$bonusXp} XP Bonus (Streak {$consecutiveDays} ngày)! 🔥";
        }

        Log::info('Habit completed successfully', [
            'habit_id' => $habit->id,
            'user_id' => Auth::id(),
            'xp_gained' => $totalXpGain,
            'consecutive_days' => $consecutiveDays,
        ]);

        return response()->json([
            'success' => true,
            'message' => $message,
            'habit' => $habit,
            'completed_days' => $habit->completed_days,
            'total_days' => $habit->duration_days,
            // ✅ Thông tin cây
            'plant' => [
                'xp' => $newPlantXp,
                'xp_gained' => $actualXp,
                'bonus_xp' => $bonusXp,
                'total_xp_gained' => $totalXpGain,
                'status' => 'healthy',
                'last_update' => now()->toISOString(),
                'consecutive_days' => $consecutiveDays,
                'daily_xp' => $newDailyXp,
                'daily_limit' => $dailyLimit,
            ]
        ], 200);
        
    } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
        Log::warning('Habit not found', ['habit_id' => $id, 'user_id' => Auth::id()]);
        return response()->json([
            'success' => false,
            'message' => 'Không tìm thấy thói quen'
        ], 404);
        
    } catch (\Throwable $e) {
        Log::error('Error completing habit', [
            'habit_id' => $id,
            'user_id' => Auth::id(),
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        
        return response()->json([
            'success' => false,
            'message' => 'Có lỗi xảy ra: ' . $e->getMessage()
        ], 500);
    }
}
    // 🟩 Lấy danh sách thói quen
    public function index()
    {
        $habits = Habit::where('user_id', Auth::id())->get();

        // Tự động tách repeat_data thành tuần này & tuần sau
        $habits->transform(function ($habit) {
            $repeatData = $habit->repeat_data;
            $currentWeek = [];
            $nextWeek = [];

            if ($repeatData && str_contains($repeatData, '|next:')) {
                [$cur, $next] = explode('|next:', $repeatData);
                $currentWeek = array_map('intval', array_filter(explode(',', trim($cur))));
                $nextWeek = array_map('intval', array_filter(explode(',', trim($next))));
            } elseif ($repeatData) {
                $currentWeek = array_map('intval', array_filter(explode(',', $repeatData)));
            }

            // Thêm vào JSON trả về
            $habit->repeat_data_current = $currentWeek;
            $habit->repeat_data_next = $nextWeek;

            return $habit;
        });

        return response()->json(['habits' => $habits], 200);
    }

    // 🟩 Tạo thói quen mới
    public function store(Request $request)
    {
        $request->validate([
            'ten_thoi_quen' => 'required|string',
            'mo_ta' => 'nullable|string',
            'diem' => 'required|integer',
            'repeat_type' => 'required|in:daily,weekly,monthly',
            'repeat_data' => 'nullable|string',
            'duration_days' => 'nullable|integer|min:1',
            'total_xp' => 'nullable|integer|min:0',
            'is_challenge' => 'nullable|boolean',
        ]);

        $habit = $request->user()->habits()->create([
            'ten_thoi_quen' => $request->ten_thoi_quen,
            'mo_ta' => $request->mo_ta,
            'diem' => $request->diem,
            'repeat_type' => $request->repeat_type,
            'repeat_data' => $this->normalizeRepeatData($request->repeat_data),
            'duration_days' => $request->duration_days ?? 1,
            'completed_days' => 0,
            'total_xp' => $request->total_xp ?? 0,
            'start_date' => now(),
            'is_challenge' => $request->is_challenge ?? false,
            'completed' => false,
            'completed_date' => null,
        ]);

        return response()->json(['habit' => $habit], 201);
    }

    // 🟩 Cập nhật thói quen
    public function update(Request $request, $id)
    {
        try {
            $habit = Habit::where('id', $id)
                          ->where('user_id', Auth::id())
                          ->firstOrFail();

            $data = $request->only([
                'ten_thoi_quen',
                'mo_ta',
                'diem',
                'repeat_type',
                'repeat_data',
                'duration_days',
                'is_challenge',
                'start_date',
            ]);

            if (isset($data['is_challenge'])) {
                $data['is_challenge'] = intval($data['is_challenge']);
            }

            if (isset($data['repeat_data'])) {
                $data['repeat_data'] = $this->normalizeRepeatData($data['repeat_data']);
            }

            $habit->fill($data);

            if (!$habit->start_date && $request->has('duration_days')) {
                $habit->start_date = Carbon::now();
            }

            $habit->save();

            return response()->json([
                'message' => 'Cập nhật thành công',
                'habit' => $habit
            ], 200);
            
        } catch (\Throwable $e) {
            Log::error('Error updating habit', [
                'habit_id' => $id,
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'message' => 'Cập nhật thất bại: ' . $e->getMessage()
            ], 500);
        }
    }

    // 🟩 Xóa thói quen
    public function destroy($id)
    {
        try {
            $habit = Habit::where('id', $id)
                          ->where('user_id', Auth::id())
                          ->firstOrFail();

            $habit->delete();
            
            Log::info('Habit deleted', ['habit_id' => $id, 'user_id' => Auth::id()]);
            
            return response()->json([
                'success' => true,
                'message' => 'Xóa thói quen thành công'
            ], 200);
            
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Không tìm thấy thói quen'
            ], 404);
            
        } catch (\Throwable $e) {
            Log::error('Error deleting habit', [
                'habit_id' => $id,
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Xóa thất bại'
            ], 500);
        }
    }

    // 🟩 Hàm xử lý repeat_data có dạng "4,5|next:1,2,3"
    private function normalizeRepeatData($data)
    {
        if (!$data) return null;

        // Nếu không chứa "|next:" thì trả nguyên
        if (!str_contains($data, '|next:')) {
            return $data;
        }

        [$current, $next] = explode('|next:', $data);
        $current = trim($current, ',');
        $next = trim($next, ',');

        // Trả lại chuỗi chuẩn hóa
        return "{$current}|next:{$next}";
    }
}
