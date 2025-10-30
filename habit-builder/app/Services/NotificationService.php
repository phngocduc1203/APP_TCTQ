<?php

namespace App\Services;

use App\Models\User;
use App\Models\ProcrastinationAlert;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Gửi thông báo cho user về trì hoãn
     */
    public function sendProcrastinationNotification(User $user, ProcrastinationAlert $alert): void
    {
        try {
            // Có thể tích hợp với:
            // - Firebase Cloud Messaging (FCM) cho mobile
            // - OneSignal
            // - Pusher
            // - Email
            
            $notificationData = [
                'type' => 'procrastination_alert',
                'title' => 'Cảnh báo trì hoãn!',
                'body' => $alert->message,
                'data' => [
                    'alert_id' => $alert->id,
                    'habit_id' => $alert->habit_id,
                    'habit_name' => $alert->habit->ten_thoi_quen,
                    'days_delayed' => $alert->days_delayed,
                    'severity' => $alert->severity,
                ],
                'priority' => $this->getPriority($alert->severity),
            ];

            // Log thông báo (có thể thay bằng service thực tế)
            Log::info('Procrastination notification', [
                'user_id' => $user->id,
                'alert_id' => $alert->id,
                'notification' => $notificationData,
            ]);

            // TODO: Gửi thông báo qua FCM, OneSignal, etc.
            // $this->sendFCMNotification($user, $notificationData);
            
        } catch (\Exception $e) {
            Log::error('Failed to send procrastination notification', [
                'user_id' => $user->id,
                'alert_id' => $alert->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Xác định priority dựa trên severity
     */
    private function getPriority(string $severity): string
    {
        return match($severity) {
            'critical' => 'high',
            'warning' => 'default',
            'info' => 'low',
            default => 'default',
        };
    }

    /**
     * Gửi tóm tắt hàng ngày về trạng thái trì hoãn
     */
    public function sendDailySummary(User $user): void
    {
        $unreadCount = $user->unreadAlerts()->count();
        
        if ($unreadCount === 0) {
            return;
        }

        $severity = $user->unreadAlerts()
            ->orderBy('severity', 'desc')
            ->first()
            ->severity;

        $message = match($severity) {
            'critical' => "⚠️ Bạn có {$unreadCount} cảnh báo trì hoãn nghiêm trọng!",
            'warning' => "⚡ Bạn có {$unreadCount} cảnh báo trì hoãn.",
            default => "💡 Bạn có {$unreadCount} nhắc nhở về thói quen.",
        };

        $notificationData = [
            'type' => 'daily_summary',
            'title' => 'Tóm tắt hàng ngày',
            'body' => $message,
            'data' => [
                'unread_count' => $unreadCount,
                'highest_severity' => $severity,
            ],
        ];

        Log::info('Daily summary notification', [
            'user_id' => $user->id,
            'notification' => $notificationData,
        ]);
    }

    /**
     * Tích hợp FCM (Firebase Cloud Messaging)
     * Cần cài đặt: composer require kreait/firebase-php
     */
    private function sendFCMNotification(User $user, array $data): void
    {
        // Example implementation
        // $messaging = app('firebase.messaging');
        // $notification = Notification::create($data['title'], $data['body']);
        // $message = CloudMessage::withTarget('token', $user->fcm_token)
        //     ->withNotification($notification)
        //     ->withData($data['data']);
        // $messaging->send($message);
    }
}