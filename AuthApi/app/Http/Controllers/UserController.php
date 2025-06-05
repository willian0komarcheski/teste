<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index()
    {
        return response()->json([
            'users' => User::all()
        ]);
    }

    public function show(User $user)
    {
        return response()->json([
            'user' => $user
        ]);
    }

    public function update(Request $request, User $user)
    {
        $request->validate([
            'name' => 'string|max:255',
            'email' => 'string|email|max:255|unique:users,email,'.$user->id,
            'password' => 'string|min:6',
        ]);

        $user->update([
            'name' => $request->name ?? $user->name,
            'email' => $request->email ?? $user->email,
            'password' => $request->password ? Hash::make($request->password) : $user->password,
        ]);

        return response()->json([
            'message' => 'User updated successfully',
            'user' => $user
        ]);
    }

    public function destroy(User $user)
    {
        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully'
        ]);
    }
}