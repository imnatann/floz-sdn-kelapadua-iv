<?php

return [

    /*
    |--------------------------------------------------------------------------
    | School Identity
    |--------------------------------------------------------------------------
    |
    | Static metadata for the single-school deployment. These values
    | replace the dynamic Tenant model used by the original multi-tenant
    | framework. They are surfaced in PDF templates (rapor, ID card) and
    | anywhere the application needs to print "the school".
    |
    */

    'name'    => env('SCHOOL_NAME', 'SDN Kelapadua IV'),
    'address' => env('SCHOOL_ADDRESS', 'Jl. Kelapa Dua Raya'),
    'email'   => env('SCHOOL_EMAIL', 'info@sdnkelapadua4.sch.id'),
    'phone'   => env('SCHOOL_PHONE', '021-12345678'),

    /*
    |--------------------------------------------------------------------------
    | Education Level
    |--------------------------------------------------------------------------
    |
    | One of: SD, SMP, SMA. Drives report-card rendering and grade
    | calculation strategy.
    |
    */

    'education_level' => env('SCHOOL_EDUCATION_LEVEL', 'SD'),

];
