<?php

namespace Database\Seeders;

use App\Models\Tenant\Student;
use App\Models\Tenant\User;
use App\Models\Tenant\SchoolClass;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class StudentSeeder extends Seeder
{
    /**
     * Seed 10 students with linked User accounts for login.
     * Each student gets a User (role: student) + Student record sharing same email.
     *
     * Run: php artisan db:seed --class=StudentSeeder --database=tenant
     */
    public function run(): void
    {
        // Make sure we have classes to assign students to
        $classes = SchoolClass::all();
        if ($classes->isEmpty()) {
            $this->command->warn('No classes found! Please run TenantDatabaseSeeder first to create classes.');
            return;
        }

        $students = [
            [
                'nis'          => '2024101',
                'nisn'         => '0081234001',
                'name'         => 'Aisyah Putri Rahayu',
                'gender'       => 'P',
                'birth_place'  => 'Jakarta',
                'birth_date'   => '2010-03-15',
                'religion'     => 'Islam',
                'address'      => 'Jl. Merdeka No. 10, Jakarta Selatan',
                'parent_name'  => 'Hendra Rahayu',
                'parent_phone' => '081234567001',
            ],
            [
                'nis'          => '2024102',
                'nisn'         => '0081234002',
                'name'         => 'Bima Arya Pratama',
                'gender'       => 'L',
                'birth_place'  => 'Bandung',
                'birth_date'   => '2010-06-22',
                'religion'     => 'Islam',
                'address'      => 'Jl. Cihampelas No. 45, Bandung',
                'parent_name'  => 'Agus Pratama',
                'parent_phone' => '081234567002',
            ],
            [
                'nis'          => '2024103',
                'nisn'         => '0081234003',
                'name'         => 'Citra Dewi Anggraini',
                'gender'       => 'P',
                'birth_place'  => 'Surabaya',
                'birth_date'   => '2010-01-08',
                'religion'     => 'Kristen',
                'address'      => 'Jl. Basuki Rahmat No. 78, Surabaya',
                'parent_name'  => 'Michael Anggraini',
                'parent_phone' => '081234567003',
            ],
            [
                'nis'          => '2024104',
                'nisn'         => '0081234004',
                'name'         => 'Dimas Kurniawan',
                'gender'       => 'L',
                'birth_place'  => 'Semarang',
                'birth_date'   => '2010-09-30',
                'religion'     => 'Islam',
                'address'      => 'Jl. Pandanaran No. 12, Semarang',
                'parent_name'  => 'Joko Kurniawan',
                'parent_phone' => '081234567004',
            ],
            [
                'nis'          => '2024105',
                'nisn'         => '0081234005',
                'name'         => 'Eka Fitriani',
                'gender'       => 'P',
                'birth_place'  => 'Yogyakarta',
                'birth_date'   => '2010-12-05',
                'religion'     => 'Islam',
                'address'      => 'Jl. Malioboro No. 55, Yogyakarta',
                'parent_name'  => 'Bambang Fitriani',
                'parent_phone' => '081234567005',
            ],
            [
                'nis'          => '2024106',
                'nisn'         => '0081234006',
                'name'         => 'Farhan Maulana',
                'gender'       => 'L',
                'birth_place'  => 'Medan',
                'birth_date'   => '2010-04-18',
                'religion'     => 'Islam',
                'address'      => 'Jl. Gatot Subroto No. 33, Medan',
                'parent_name'  => 'Rizal Maulana',
                'parent_phone' => '081234567006',
            ],
            [
                'nis'          => '2024107',
                'nisn'         => '0081234007',
                'name'         => 'Gita Nuraini',
                'gender'       => 'P',
                'birth_place'  => 'Malang',
                'birth_date'   => '2010-07-25',
                'religion'     => 'Hindu',
                'address'      => 'Jl. Ijen No. 21, Malang',
                'parent_name'  => 'Wayan Nuraini',
                'parent_phone' => '081234567007',
            ],
            [
                'nis'          => '2024108',
                'nisn'         => '0081234008',
                'name'         => 'Hadi Saputra',
                'gender'       => 'L',
                'birth_place'  => 'Makassar',
                'birth_date'   => '2010-02-14',
                'religion'     => 'Islam',
                'address'      => 'Jl. Somba Opu No. 66, Makassar',
                'parent_name'  => 'Andi Saputra',
                'parent_phone' => '081234567008',
            ],
            [
                'nis'          => '2024109',
                'nisn'         => '0081234009',
                'name'         => 'Indah Permatasari',
                'gender'       => 'P',
                'birth_place'  => 'Denpasar',
                'birth_date'   => '2010-11-11',
                'religion'     => 'Hindu',
                'address'      => 'Jl. Sunset Road No. 88, Denpasar',
                'parent_name'  => 'Made Permatasari',
                'parent_phone' => '081234567009',
            ],
            [
                'nis'          => '2024110',
                'nisn'         => '0081234010',
                'name'         => 'Johan Kristianto',
                'gender'       => 'L',
                'birth_place'  => 'Manado',
                'birth_date'   => '2010-08-03',
                'religion'     => 'Kristen',
                'address'      => 'Jl. Sam Ratulangi No. 42, Manado',
                'parent_name'  => 'Daniel Kristianto',
                'parent_phone' => '081234567010',
            ],
        ];

        $password = Hash::make('password');

        foreach ($students as $index => $data) {
            // Generate email from name
            $emailSlug = strtolower(str_replace(' ', '.', $data['name']));
            $email = "{$emailSlug}@siswa.sekolah.id";

            // Distribute students across available classes (round-robin)
            $classId = $classes[$index % $classes->count()]->id;

            // 1. Create User account for login
            $user = User::firstOrCreate(
                ['email' => $email],
                [
                    'name'      => $data['name'],
                    'password'  => $password,
                    'role'      => 'student',
                    'is_active' => true,
                ]
            );

            // 2. Create Student record linked via same email
            Student::firstOrCreate(
                ['nis' => $data['nis']],
                array_merge($data, [
                    'email'    => $email,
                    'class_id' => $classId,
                    'status'   => 'active',
                ])
            );

            $this->command->info("✓ {$data['name']} ({$email}) → Class ID: {$classId}");
        }

        $this->command->newLine();
        $this->command->info('ℹ  Semua siswa bisa login dengan password: password');
        $this->command->info('ℹ  Total siswa di-seed: ' . count($students));
    }
}
