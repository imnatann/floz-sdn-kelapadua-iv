<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class AcademicYearFactory extends Factory
{
    protected $model = AcademicYear::class;

    public function definition(): array
    {
        $startYear = $this->faker->unique()->numberBetween(2020, 2099);
        $endYear = $startYear + 1;

        return [
            'name'       => "{$startYear}/{$endYear}",
            'start_date' => "{$startYear}-07-01",
            'end_date'   => "{$endYear}-06-30",
            'is_active'  => false,
        ];
    }
}
