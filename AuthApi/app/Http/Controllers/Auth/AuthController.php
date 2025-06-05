<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;
use Laravel\Sanctum\PersonalAccessToken;


class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        $user = Cache::get('user_' . $request->email);

        if ($user) {
            return response()->json([
                'message' => 'email already exists',
                'user' => $user->email
            ], 409);
        }
        
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);
            

        Cache::put('user_' . $user->email, $user, now()->addHours(2));
        
        return response()->json([
            'message' => 'User registered successfully',
            'user' => $user
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $userCache = Cache::get('user_' . $request->email);
        
        if ($userCache) {
            if( $userCache->email === $request->email && $userCache->password === Hash::make($request->password) ) {
                $token = Cache::get('token_' . $request->email);
                if($token) {
                    return response()->json([
                        'message' => 'User already logged in',
                        'user' => $userCache->email,
                        'token' => Cache::get('token_' . $request->email)
                    ]);
                } else {
                    $userCache->tokens()->delete();
                    $token = $user->createToken('auth_token', ['*'], now()->addHours(1))->plainTextToken;
                    Cache::put('token_' . $userCache->email, $token, now()->addHours(1));
                    return response()->json([
                        'message' => 'User logged in successfully',
                        'user' => $userCache->email,
                        'token' => $token
                    ]);
                }
            }
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json([
                'message' => 'Invalid login credentials'
            ], 401);
        }

        $user = Auth::user();
        
        $token = Cache::get('token_' . $user->email);
        if ($token) {
            return response()->json([
                'message' => 'User already logged in',
                'user' => $user->email,
                'token' => $token
            ]);
        }

        $user->tokens()->delete();

        $token = $user->createToken('auth_token', ['*'], now()->addHours(1))->plainTextToken;

        Cache::put('user_' . $user->email, $user, now()->addHours(2));
        Cache::put('token_' . $user->email, $token, now()->addHours(1));

        return response()->json([
            'message' => 'User logged in successfully',
            'user' => $user->email,
            'token' => $token
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        $request->user()->tokens()->delete();

        Cache::forget('user_' . $user->email);
        Cache::forget('token_' . $user->email);
        Auth::logout();
        
        return response()->json([
            'message' => 'User logged out successfully'
        ]);
    }

    public function verifyToken(Request $request)
    {
        try {

            $request->validate([
                'token' => 'required|string'
            ]);
    
            $token = PersonalAccessToken::findToken($request->token);
    
            if (!$token) {
                return response()->json([
                    'message' => 'Invalid token',
                    'valid' => false
                ], 401);
            }
    
            if ($token->expires_at && $token->expires_at->isPast()) {
            return response()->json(['message' => 'Token is expired'], 401);
            }
    
            $user = $token->tokenable;
    
            $user->tokens()->delete();
    
            $token = $user->createToken('auth_token', ['*'], now()->addHours(1))->plainTextToken;
    
            Cache::put('token_' . $user->email, $token, now()->addHours(1));
            Cache::put('user_' . $user->email, $user, now()->addHours(2));
    
            return response()->json([
                'valid' => true,
                "token" => $token
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'An error occurred while verifying the token',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function testRedis()
    {
        $redis = Redis::connection();
        
        // Get current counter or start at 1
        $counter = $redis->get('api_test_counter') ?? 0;
        $counter++;
        
        // Set counter and test value with counter
        $redis->set('api_test_counter', $counter);
        $redis->set("test_key_{$counter}", "Hello from Redis! Call #{$counter}");
        
        // Get all keys
        $keys = $redis->keys('*');
        
        // Get all test values
        $values = [];
        foreach ($keys as $key) {
            $values[$key] = $redis->get($key);
        }
        
        return response()->json([
            'total_keys' => count($keys),
            'all_keys' => $keys,
            'all_values' => $values,
            'current_counter' => $counter,
            'ping' => $redis->ping()
        ]);
    }

    public function testTokens(Request $request)
    {
        $user = Auth::user();
        return response()->json([
            'user_id' => $user->id,
            'tokens' => $user->tokens()->get(),
            'current_token' => $request->user()->currentAccessToken()
        ]);
    }
}