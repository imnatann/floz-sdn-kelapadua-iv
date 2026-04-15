<?php

return [

    /*
    |--------------------------------------------------------------------------
    | FLOZ LMS Configuration
    |--------------------------------------------------------------------------
    */

    // Subscription Plans
    'plans' => [
        'starter' => [
            'name'         => 'Starter',
            'max_students' => 100,
            'max_teachers' => 20,
            'features'     => ['basic_grades', 'report_cards', 'pdf_export'],
            'price'        => [
                'monthly' => 199000,
                'yearly'  => 1990000,
            ],
        ],
        'professional' => [
            'name'         => 'Professional',
            'max_students' => 500,
            'max_teachers' => 50,
            'features'     => ['basic_grades', 'report_cards', 'pdf_export', 'excel_import', 'analytics', 'notifications'],
            'price'        => [
                'monthly' => 499000,
                'yearly'  => 4990000,
            ],
        ],
        'enterprise' => [
            'name'         => 'Enterprise',
            'max_students' => -1, // Unlimited
            'max_teachers' => -1,
            'features'     => ['all'],
            'price'        => [
                'monthly' => 999000,
                'yearly'  => 9990000,
            ],
        ],
    ],

    // Grade Calculation Weights (SD)
    'grade_weights' => [
        'sd' => [
            'daily_test' => 0.40,
            'mid_test'   => 0.30,
            'final_test' => 0.30,
        ],
    ],

    // Predicate Thresholds (SMP/SMA)
    'predicates' => [
        'A' => 90,
        'B' => 80,
        'C' => 70,
        'D' => 0,
    ],

    // Default KKM (Kriteria Ketuntasan Minimal)
    'default_kkm' => 70.00,

    // Attitude scoring scale
    'attitude_scale' => [
        'SB' => 'Sangat Baik',
        'B'  => 'Baik',
        'C'  => 'Cukup',
        'K'  => 'Kurang',
    ],

    // Report card statuses
    'report_card_statuses' => [
        'draft'     => 'Draft',
        'review'    => 'Dalam Review',
        'published' => 'Dipublikasikan',
    ],

];
