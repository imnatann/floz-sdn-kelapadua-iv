<?php

namespace App\Enums;

enum GradeType: string
{
    case DailyTest   = 'daily_test';
    case MidTest     = 'mid_test';
    case FinalTest   = 'final_test';
    case Knowledge   = 'knowledge';
    case Skill       = 'skill';

    public function label(): string
    {
        return match ($this) {
            self::DailyTest => 'Nilai Harian',
            self::MidTest   => 'UTS',
            self::FinalTest => 'UAS',
            self::Knowledge => 'Pengetahuan (KI-3)',
            self::Skill     => 'Keterampilan (KI-4)',
        };
    }

    /**
     * Grade types applicable for SD.
     */
    public static function forSD(): array
    {
        return [self::DailyTest, self::MidTest, self::FinalTest];
    }

    /**
     * Grade types applicable for SMP/SMA.
     */
    public static function forSMPSMA(): array
    {
        return [self::Knowledge, self::Skill];
    }
}
