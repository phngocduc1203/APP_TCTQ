<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;


class PlantController extends Controller
{
    // Lấy XP và trạng thái cây
  public function getXp()
{
    $user = \App\Models\User::find(Auth::id());

    $xp = (int) ($user->plant_xp ?? 0);
    $status = $user->plant_status ?? 'healthy';

    // ✅ Kiểm tra thời gian không hoạt động
    if ($user->plant_last_update) {
        $daysSinceUpdate = now()->diffInDays($user->plant_last_update);

        if ($daysSinceUpdate >= 3) {
            // Cây chết sau 3 ngày không làm
            $status = 'dead';
        } elseif ($daysSinceUpdate >= 1) {
            // Cây héo sau 1–2 ngày
            $status = 'wilting';
        } else {
            $status = 'healthy';
        }
    }

    // ✅ Nếu trạng thái thay đổi thì lưu lại
    if ($user->plant_status !== $status) {
        $user->update(['plant_status' => $status]);
    }

    // ✅ Xác định giai đoạn dựa vào XP
    $stage = 'seed';
    if ($xp >= 200) $stage = 'fruit';
    elseif ($xp >= 150) $stage = 'flower';
    elseif ($xp >= 100) $stage = 'mature';
    elseif ($xp >= 50) $stage = 'young';
    elseif ($xp >= 10) $stage = 'sprout';

    return response()->json([
        'xp' => $xp,
        'status' => $status,  // healthy, wilting, dead
        'stage' => $stage,    // seed, sprout, young, mature, flower, fruit
        'last_update' => $user->plant_last_update,
    ]);
}

    // ✅ SỬA: SET XP TỔNG thay vì CỘNG THÊM
   public function updateXp(Request $request)
{
    /** @var \App\Models\User $user */
    $user = Auth::user();
    $totalXp = (int) $request->input('xp', 0); // ← Đổi tên biến

    // ✅ QUAN TRỌNG: SET TỔNG, KHÔNG CỘNG THÊM
    $user->update([
        'plant_xp' => $totalXp, // ← SET trực tiếp
        'plant_status' => 'healthy',
        'plant_last_update' => now(),
    ]);

    return response()->json([
        'success' => true, 
        'xp' => $user->plant_xp,
        'last_update' => $user->plant_last_update->toIso8601String(), // ✅ Thêm
    ]);
}

    // Reset cây (trồng lại)
   public function reset()
{
    /** @var \App\Models\User $user */
    $user = Auth::user();
    
    $user->update([
        'plant_xp' => 0,
        'plant_status' => 'healthy',
        'plant_last_update' => now(),
        'consecutive_days' => 0,        // ✅ THÊM: Reset streak
        'last_completed_date' => null,  // ✅ THÊM: Reset date
    ]);

    return response()->json([
        'success' => true, 
        'xp' => 0,
        'status' => 'healthy',
        'last_update' => $user->plant_last_update,
        'consecutive_days' => 0, // ✅ THÊM
    ]);
}
}