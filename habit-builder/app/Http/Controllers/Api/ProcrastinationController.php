<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ProcrastinationDetectionService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ProcrastinationController extends Controller
{
    protected ProcrastinationDetectionService $service;

    public function __construct(ProcrastinationDetectionService $service)
    {
        $this->service = $service;
    }

    /**
     * Quét và phát hiện trì hoãn cho user hiện tại
     * GET /api/procrastination/detect
     */
    public function detect(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            $alerts = $this->service->detectProcrastinationForUser($user);

            return response()->json([
                'success' => true,
                'message' => 'Phát hiện trì hoãn thành công',
                'data' => [
                    'alerts' => $alerts,
                    'count' => $alerts->count(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Lấy các thông báo chưa đọc
     * GET /api/procrastination/alerts
     */
    public function getAlerts(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            $alerts = $this->service->getUnreadAlerts($user);

            return response()->json([
                'success' => true,
                'data' => [
                    'alerts' => $alerts,
                    'count' => $alerts->count(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Lấy phân tích tổng quan
     * GET /api/procrastination/analysis
     */
    public function getAnalysis(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            $analysis = $this->service->getUserAnalysis($user);

            return response()->json([
                'success' => true,
                'data' => $analysis,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Đánh dấu alert đã đọc
     * POST /api/procrastination/alerts/{id}/read
     */
    public function markAsRead(Request $request, int $id): JsonResponse
    {
        try {
            $result = $this->service->markAlertAsRead($id);

            if ($result) {
                return response()->json([
                    'success' => true,
                    'message' => 'Đã đánh dấu đã đọc',
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Không tìm thấy thông báo',
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function getUnreadAlerts(Request $request): JsonResponse
{
    try {
        $user = $request->user();
        $alerts = $this->service->getUnreadAlerts($user);

        return response()->json([
            'success' => true,
            'data' => [
                'alerts' => $alerts,
                'count' => $alerts->count(),
            ],
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
        ], 500);
    }
}


    /**
     * Đánh dấu tất cả alerts đã đọc
     * POST /api/procrastination/alerts/read-all
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            $updated = \App\Models\ProcrastinationAlert::where('user_id', $user->id)
                ->where('is_read', false)
                ->update(['is_read' => true]);

            return response()->json([
                'success' => true,
                'message' => "Đã đánh dấu {$updated} thông báo là đã đọc",
                'count' => $updated,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Lấy lịch sử patterns của một habit
     * GET /api/procrastination/habits/{habitId}/pattern
     */
    public function getHabitPattern(Request $request, int $habitId): JsonResponse
    {
        try {
            $user = $request->user();
            $pattern = \App\Models\ProcrastinationPattern::where('user_id', $user->id)
                ->where('habit_id', $habitId)
                ->with('habit')
                ->first();

            if (!$pattern) {
                return response()->json([
                    'success' => true,
                    'message' => 'Chưa có dữ liệu phân tích cho thói quen này',
                    'data' => null,
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'pattern' => $pattern,
                    'analysis_message' => $pattern->getAnalysisMessage(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Có lỗi xảy ra: ' . $e->getMessage(),
            ], 500);
        }
    }
}