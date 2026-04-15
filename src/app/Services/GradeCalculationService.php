<?php

namespace App\Services;

class GradeCalculationService
{
    /**
     * Calculate final score for SD (Elementary School).
     * Formula: daily*0.4 + mid*0.3 + final*0.3
     */
    public function calculateSD(float $dailyTestAvg, float $midTest, float $finalTest): array
    {
        $weights = config('floz.grade_weights.sd');

        $finalScore = round(
            $dailyTestAvg * $weights['daily_test'] +
            $midTest * $weights['mid_test'] +
            $finalTest * $weights['final_test'],
            2
        );

        return [
            'final_score' => $finalScore,
            'description' => $this->generateDescriptionSD($finalScore),
        ];
    }

    /**
     * Calculate final score for SMP/SMA.
     * Formula: (knowledge + skill) / 2
     */
    public function calculateSMPSMA(float $knowledgeScore, float $skillScore): array
    {
        $finalScore = round(($knowledgeScore + $skillScore) / 2, 2);
        $predicate = $this->determinePredicate($finalScore);

        return [
            'final_score' => $finalScore,
            'predicate'   => $predicate,
            'description' => $this->generateDescriptionSMPSMA($finalScore, $predicate),
        ];
    }

    /**
     * Determine predicate (A/B/C/D) based on score.
     */
    /**
     * Determine predicate (A/B/C/D) based on score.
     */
    public static function determinePredicate(float $score): string
    {
        $thresholds = config('floz.predicates');

        foreach ($thresholds as $predicate => $minScore) {
            if ($score >= $minScore) {
                return $predicate;
            }
        }

        return 'D';
    }

    public static function determinePredicateStatic(float $score): string
    {
        return self::determinePredicate($score);
    }

    /**
     * Check if a score meets KKM.
     */
    public function meetsKkm(float $score, float $kkm): bool
    {
        return $score >= $kkm;
    }

    /**
     * Generate description for SD grades.
     */
    protected function generateDescriptionSD(float $score): string
    {
        if ($score >= 90) {
            return 'Sangat baik dalam memahami dan menguasai materi pelajaran.';
        } elseif ($score >= 80) {
            return 'Baik dalam memahami dan menguasai materi pelajaran.';
        } elseif ($score >= 70) {
            return 'Cukup baik dalam memahami materi pelajaran, perlu meningkatkan latihan.';
        } else {
            return 'Perlu bimbingan lebih lanjut dalam memahami materi pelajaran.';
        }
    }

    /**
     * Generate description for SMP/SMA grades.
     */
    protected function generateDescriptionSMPSMA(float $score, string $predicate): string
    {
        return match ($predicate) {
            'A' => 'Sangat menguasai kompetensi yang diajarkan dengan sangat baik.',
            'B' => 'Menguasai kompetensi yang diajarkan dengan baik.',
            'C' => 'Cukup menguasai kompetensi yang diajarkan.',
            'D' => 'Perlu bimbingan lebih lanjut untuk menguasai kompetensi.',
            default => '',
        };
    }
}
