<?php

namespace App\Models;

use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Traits\UsesTenantConnection;
use App\Traits\Auditable;

class User extends Authenticatable
{
    use HasFactory, HasApiTokens, Notifiable, UsesTenantConnection, Auditable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'avatar_url',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'role' => UserRole::class,
        'is_active' => 'boolean',
    ];

    public function student()
    {
        return $this->hasOne(Student::class, 'email', 'email');
    }

    public function teacher()
    {
        return $this->hasOne(Teacher::class, 'email', 'email');
    }

    public function announcements()
    {
        return $this->hasMany(Announcement::class, 'user_id');
    }

    // Helpers
    // Helpers
    public function isSuperAdmin(): bool
    {
        return $this->role === UserRole::SuperAdmin;
    }

    public function isSchoolAdmin(): bool
    {
        return $this->role === UserRole::SchoolAdmin;
    }

    public function isTeacher(): bool
    {
        return $this->role === UserRole::Teacher;
    }

    public function isStudent(): bool
    {
        return $this->role === UserRole::Student;
    }

    public function isParent(): bool
    {
        return $this->role === UserRole::Parent;
    }

    /**
     * The channels the user should receive broadcast notifications on.
     */
    public function receivesBroadcastNotificationsOn(): string
    {
        return 'App.Models.Tenant.User.'.$this->id;
    }
}
