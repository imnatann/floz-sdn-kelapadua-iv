<?php

namespace App\Enums;

enum SubscriptionStatus: string
{
    case Active    = 'active';
    case Expired   = 'expired';
    case Cancelled = 'cancelled';
    case Suspended = 'suspended';

    public function label(): string
    {
        return match ($this) {
            self::Active    => 'Aktif',
            self::Expired   => 'Kadaluarsa',
            self::Cancelled => 'Dibatalkan',
            self::Suspended => 'Ditangguhkan',
        };
    }

    public function color(): string
    {
        return match ($this) {
            self::Active    => 'success',
            self::Expired   => 'warning',
            self::Cancelled => 'error',
            self::Suspended => 'error',
        };
    }
}
