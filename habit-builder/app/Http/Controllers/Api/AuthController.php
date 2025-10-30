<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Http\Controllers\Controller;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'min:6', 'confirmed'],
            'age' => ['required', 'integer', 'min:5', 'max:120'],
            'gender' => ['required', 'string', 'in:Nam,Nữ,Khác']
        ]);

        $user = \App\Models\User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => bcrypt($validated['password']),
            'age' => $validated['age'],
            'gender' => $validated['gender'],
            'avatar' => 'https://i.pravatar.cc/150?img=' . rand(1, 70), // Avatar mặc định
            'plant_xp' => 0
        ]);

        $token = $user->createToken('AppToken')->accessToken;

        return response()->json([
            'message' => 'Đăng ký thành công',
            'access_token' => $token,
            'user' => $user
        ]);
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required']
        ]);

        if (!Auth::attempt($credentials)) {
            return response()->json(['message' => 'Sai thông tin đăng nhập'], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('AppToken')->accessToken;

        return response()->json([
            'message' => 'Đăng nhập thành công',
            'access_token' => $token,
            'user' => $user
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->token()->revoke();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();
        
        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'age' => $user->age,
            'gender' => $user->gender,
            'avatar' => $user->avatar,
            'plant_xp' => $user->plant_xp ?? 0
        ]);
    }
}