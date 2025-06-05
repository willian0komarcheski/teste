<?php

use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/test-redis', [AuthController::class, 'testRedis']);
Route::post('/verify-token', [AuthController::class, 'verifyToken']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/test-tokens', [AuthController::class, 'testTokens']);

    Route::apiResource('users', UserController::class);
});