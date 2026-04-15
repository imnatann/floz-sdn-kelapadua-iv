<?php

namespace App\Enums;

enum UserRole: string
{
    case SuperAdmin   = 'super_admin';
    case SchoolAdmin  = 'school_admin';
    case Teacher      = 'teacher';
    case Student      = 'student';
    case Parent       = 'parent';

    public function label(): string
    {
        return match ($this) {
            self::SuperAdmin  => 'Super Admin',
            self::SchoolAdmin => 'Admin Sekolah',
            self::Teacher     => 'Guru',
            self::Student     => 'Siswa',
            self::Parent      => 'Orang Tua',
        };
    }

    public function isPlatformLevel(): bool
    {
        return $this === self::SuperAdmin;
    }

    public function isTenantLevel(): bool
    {
        return in_array($this, [
            self::SchoolAdmin,
            self::Teacher,
            self::Student,
            self::Parent,
        ]);
    }
}
