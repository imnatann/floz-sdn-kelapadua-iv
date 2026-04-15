<?php

namespace App\Enums;

enum EducationLevel: string
{
    case SD  = 'SD';
    case SMP = 'SMP';
    case SMA = 'SMA';

    public function label(): string
    {
        return match ($this) {
            self::SD  => 'Sekolah Dasar',
            self::SMP => 'Sekolah Menengah Pertama',
            self::SMA => 'Sekolah Menengah Atas',
        };
    }

    public function gradeLevels(): array
    {
        return match ($this) {
            self::SD  => [1, 2, 3, 4, 5, 6],
            self::SMP => [7, 8, 9],
            self::SMA => [10, 11, 12],
        };
    }
}
