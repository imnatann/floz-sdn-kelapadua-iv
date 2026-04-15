<?php

namespace Database\Seeders;

use App\Models\Tenant\Student;
use App\Models\Tenant\Teacher;
use App\Models\Tenant\User;
use App\Models\Tenant\SchoolClass;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class TenantDatabaseSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create a Teacher User
        $teacherEmail = 'guru@sekolah.id';
        $user = User::firstOrCreate(
            ['email' => $teacherEmail],
            [
                'name' => 'Budi Santoso, S.Pd',
                'password' => Hash::make('password'), // Global password
                'role' => 'teacher',
                'is_active' => true,
            ]
        );

        // 2. Create Teacher Profile linked to User
        Teacher::firstOrCreate(
            ['user_id' => $user->id],
            [
                'name' => $user->name,
                'email' => $user->email,
                'nip' => '198501012010011001',
                'status' => 'active',
                'is_homeroom' => true,
            ]
        );

        // 3. Create active Academic Year
        $academicYear = \App\Models\Tenant\AcademicYear::firstOrCreate(
            ['name' => '2023/2024'],
            ['is_active' => true, 'start_date' => '2023-07-01', 'end_date' => '2024-06-30']
        );

        // 4. Create some Classes (if not exist)
        $classA = SchoolClass::firstOrCreate(
            ['name' => 'X IPA 1'],
            ['grade_level' => 10, 'academic_year_id' => $academicYear->id, 'status' => 'active']
        );
        SchoolClass::firstOrCreate(
            ['name' => 'X IPA 2'],
            ['grade_level' => 10, 'academic_year_id' => $academicYear->id, 'status' => 'active']
        );
        SchoolClass::firstOrCreate(
            ['name' => 'XI IPS 1'],
            ['grade_level' => 11, 'academic_year_id' => $academicYear->id, 'status' => 'active']
        );

        // 5. Create dummy students for Class A (with User accounts for login)
        if (Student::count() < 5) {
            $password = Hash::make('password');

            // Student 1
            $email1 = 'ahmad.dani@siswa.sekolah.id';
            User::firstOrCreate(
                ['email' => $email1],
                ['name' => 'Ahmad Dani', 'password' => $password, 'role' => 'student', 'is_active' => true]
            );
            Student::create([
                'nis' => '2024001', 'name' => 'Ahmad Dani', 'email' => $email1,
                'class_id' => $classA->id, 'gender' => 'L', 'status' => 'active',
            ]);

            // Student 2
            $email2 = 'bunga.citra@siswa.sekolah.id';
            User::firstOrCreate(
                ['email' => $email2],
                ['name' => 'Bunga Citra', 'password' => $password, 'role' => 'student', 'is_active' => true]
            );
            Student::create([
                'nis' => '2024002', 'name' => 'Bunga Citra', 'email' => $email2,
                'class_id' => $classA->id, 'gender' => 'P', 'status' => 'active',
            ]);
        }

        // 6. Seed 10 additional students with login accounts
        $this->call(StudentSeeder::class);
    }
}
