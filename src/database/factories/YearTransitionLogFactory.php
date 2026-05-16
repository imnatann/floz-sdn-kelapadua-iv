<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use App\Models\User;
use App\Models\YearTransitionLog;
use Illuminate\Database\Eloquent\Factories\Factory;

class YearTransitionLogFactory extends Factory
{
    protected $model = YearTransitionLog::class;

    public function definition(): array
    {
        return [
            'executed_by'              => User::factory(),
            'source_academic_year_id'  => AcademicYear::factory(),
            'target_academic_year_id'  => AcademicYear::factory(),
            'executed_at'              => now(),
            'promoted_count'           => $this->faker->numberBetween(10, 30),
            'graduated_count'          => $this->faker->numberBetween(0, 10),
            'retained_count'           => $this->faker->numberBetween(0, 3),
            'excluded_count'           => 0,
            'plan_snapshot'            => ['mutations' => [], 'summary' => []],
            'ip_address'               => '192.168.1.' . $this->faker->numberBetween(1, 254),
        ];
    }
}
