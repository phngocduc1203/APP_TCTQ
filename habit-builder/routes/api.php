<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\HabitController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\StreakController;
use App\Http\Controllers\Api\PlantController;
use App\Http\Controllers\Api\ProcrastinationController;

// Nhóm route với tiền tố /api/v1
Route::prefix('v1')->group(function () {

    // Đăng ký và đăng nhập
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);

    // Route không cần xác thực
    Route::get('/time', function () {
        return response()->json(['time' => now()]);
    });

    // Route cần xác thực bằng token
    Route::middleware('auth:api')->group(function () {

        // Lấy thông tin người dùng hiện tại
        Route::get('/me', [AuthController::class, 'me']);

        // Cập nhật thông tin người dùng (tên, avatar, mật khẩu)
        Route::put('/me', [UserController::class, 'update']);
        
        // Upload avatar riêng - THÊM DÒNG NÀY
        Route::post('/me/avatar', [UserController::class, 'uploadAvatar']);

        // Logout
        Route::post('/logout', [AuthController::class, 'logout']);

        // Quản lý thói quen
        Route::get('/habits', [HabitController::class, 'index']);
        Route::post('/habits', [HabitController::class, 'store']);
        Route::put('/habits/{id}', [HabitController::class, 'update']);
        Route::delete('/habits/{id}', [HabitController::class, 'destroy']);
        Route::put('/habits/{id}/complete', [HabitController::class, 'complete']);
        Route::get('/habits/date', [HabitController::class, 'getHabitsForDate']);
        Route::post('/habits/{id}/complete', [HabitController::class, 'complete']);
        Route::get('/habits/{id}/history', [HabitController::class, 'completionHistory']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    // Habit completion
    // Route::put('/habits/{id}/complete', [HabitController::class, 'complete']);
    // Route::get('/habits/{id}/history', [HabitController::class, 'completionHistory']);
    
    Route::get('/streak', [StreakController::class, 'getStreakInfo']);
    Route::post('/streak/update', [StreakController::class, 'updateStreak']);
    Route::post('/streak/freeze', [StreakController::class, 'useStreakFreeze']);
     Route::get('/streak/warning', [StreakController::class, 'checkStreakWarning']);
});

// ✅ ĐÚNG (dùng passport)
Route::prefix('v1')->middleware('auth:api')->group(function () {
    Route::get('/plant/xp', [PlantController::class, 'getXp']);
    Route::post('/plant/update-xp', [PlantController::class, 'updateXp']);
    Route::post('/plant/reset', [PlantController::class, 'reset']);
});


Route::prefix('v1')->middleware('auth:api')->group(function () {

    // Procrastination Detection Routes (API v1)
    Route::prefix('procrastination')->group(function () {
        // Phát hiện trì hoãn
        Route::match(['get', 'post'], '/detect', [ProcrastinationController::class, 'detect']);


        // Lấy danh sách cảnh báo chưa đọc
        Route::get('/alerts/unread', [ProcrastinationController::class, 'getUnreadAlerts']);


        // Lấy danh sách alerts
        Route::get('/alerts', [ProcrastinationController::class, 'getAlerts']);

        // Lấy phân tích tổng quan
        Route::get('/analysis', [ProcrastinationController::class, 'getAnalysis']);

        // Đánh dấu alert đã đọc
        Route::post('/alerts/{id}/read', [ProcrastinationController::class, 'markAsRead']);

        // Đánh dấu tất cả đã đọc
        Route::post('/alerts/read-all', [ProcrastinationController::class, 'markAllAsRead']);

        // Lấy pattern của một habit
        Route::get('/habits/{habitId}/pattern', [ProcrastinationController::class, 'getHabitPattern']);
    });

});