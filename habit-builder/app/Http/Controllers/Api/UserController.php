<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UserController extends Controller
{
    // ========== UPLOAD AVATAR RIÊNG ==========
    public function uploadAvatar(Request $request)
    {
        /** @var User $user */
        $user = Auth::user();
        
        $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpeg,png,jpg,gif', 'max:2048'],
        ]);
        
        try {
            // Xóa avatar cũ nếu có
            if ($user->avatar) {
                $oldPath = $user->avatar;
                $assetPrefix = asset('storage/');
                if (Str::startsWith($oldPath, $assetPrefix)) {
                    $oldPath = Str::replaceFirst($assetPrefix, '', $oldPath);
                }
                Storage::disk('public')->delete($oldPath);
            }

            // Upload file mới
            $file = $request->file('avatar');
            $path = $file->store('avatars', 'public');

            // Lưu tương đối vào DB
            $user->avatar = $path;
            $user->save();

            // Chuẩn bị dữ liệu trả về
            $userData = $user->toArray();
            unset($userData['password']);
            $userData['avatar'] = asset('storage/' . $user->avatar); // ✅ Trả full URL

            return response()->json([
    'message' => 'Upload thành công',
    'user' => [
        'id' => $user->id,
        'name' => $user->name,
        'avatar' => asset('storage/' . ltrim($user->avatar, '/')),
    ],
], 200);


        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Upload thất bại: ' . $e->getMessage(),
            ], 500);
        }
    }

    // ========== CẬP NHẬT THÔNG TIN USER ==========
    public function update(Request $request)
    {
        /** @var User $user */
        $user = Auth::user();

        $validated = $request->validate([
            'name' => ['nullable', 'string', 'max:255'],
            'avatar' => ['nullable'],
            'old_password' => ['nullable', 'string'],
            'password' => ['nullable', 'string', 'min:6'],
            'password_confirmation' => ['nullable', 'string', 'same:password'],
        ]);

        $hasChanges = false;

        // ========== ĐỔI AVATAR ==========
        if ($request->hasFile('avatar')) {
           if ($user->avatar && !Str::startsWith($user->avatar, ['http://', 'https://'])) {
    $userData['avatar'] = asset('storage/' . ltrim($user->avatar, '/'));
} else {
    $userData['avatar'] = $user->avatar;
}

        }

        // ========== ĐỔI TÊN ==========
        if ($request->filled('name') && $request->name !== $user->name) {
            $user->name = $request->name;
            $hasChanges = true;
        }

        // ========== ĐỔI MẬT KHẨU ==========
        if ($request->filled('password')) {
            if (!$request->filled('old_password')) {
                return response()->json(['message' => 'Vui lòng nhập mật khẩu cũ'], 422);
            }

            if (!Hash::check($request->old_password, $user->password)) {
                return response()->json(['message' => 'Mật khẩu cũ không đúng'], 422);
            }

            $user->password = Hash::make($request->password);
            $hasChanges = true;
        }

        // ========== LƯU THAY ĐỔI ==========
        if ($hasChanges) {
            $user->save();

            $userData = $user->toArray();
            unset($userData['password']);
            $userData['avatar'] = $user->avatar
                ? asset('storage/' . $user->avatar) // ✅ luôn trả full URL
                : null;

            return response()->json([
                'message' => 'Cập nhật thành công',
                'user'    => $userData,
            ], 200);
        }

        return response()->json(['message' => 'Không có thay đổi'], 200);
    }
}
