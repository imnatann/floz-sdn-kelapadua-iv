<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\AcademicYear;
use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Grade;
use App\Models\Meeting;
use App\Models\OfflineAssignment;
use App\Models\ReportCard;
use App\Models\Schedule;
use App\Models\SchoolClass;
use App\Models\Semester;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;

/**
 * Realistic demo data for SDN Kelapa Dua IV.
 *
 * Idempotent: safe to run multiple times (uses firstOrCreate).
 * Run: php artisan db:seed --class=DemoDataSeeder
 */
class DemoDataSeeder extends Seeder
{
    private string $password;

    public function run(): void
    {
        $this->password = Hash::make('password123');

        $this->command->info('Seeding SDN Kelapa Dua IV demo data...');

        $ay = $this->seedAcademicYear();
        $semesters = $this->seedSemesters($ay);
        $subjects = $this->seedSubjects();
        $teachers = $this->seedTeachers();
        $classes = $this->seedClasses($ay, $teachers);
        $students = $this->seedStudents($classes);
        $tas = $this->seedTeachingAssignments($ay, $teachers, $subjects, $classes);
        $this->seedSchedules($tas);
        $this->seedGrades($students, $subjects, $classes, $semesters, $teachers);
        $this->seedAttendance($students, $classes, $semesters);
        $this->seedAnnouncements();
        $this->seedReportCards($students, $classes, $semesters);
        $this->seedAssignments($tas, $classes);

        $this->command->info('Demo data seeded successfully!');
        $this->command->table(
            ['Entity', 'Count'],
            collect([
                'Users' => User::count(),
                'Teachers' => Teacher::count(),
                'Students' => Student::count(),
                'Classes' => SchoolClass::count(),
                'Subjects' => Subject::count(),
                'Teaching Assignments' => TeachingAssignment::count(),
                'Meetings' => Meeting::count(),
                'Schedules' => Schedule::count(),
                'Grades' => Grade::count(),
                'Attendance' => Attendance::count(),
                'Announcements' => Announcement::count(),
                'Report Cards' => ReportCard::count(),
                'Assignments' => OfflineAssignment::count(),
            ])->map(fn ($v, $k) => [$k, $v])->values()->toArray()
        );
    }

    // ── Academic Year + Semesters ──────────────────────────────────

    private function seedAcademicYear(): AcademicYear
    {
        // Deactivate all others first
        AcademicYear::query()->update(['is_active' => false]);

        return AcademicYear::firstOrCreate(
            ['name' => '2025/2026'],
            [
                'start_date' => '2025-07-14',
                'end_date' => '2026-06-20',
                'is_active' => true,
            ]
        );
    }

    private function seedSemesters(AcademicYear $ay): array
    {
        $ganjil = Semester::firstOrCreate(
            ['academic_year_id' => $ay->id, 'semester_number' => 1],
            [
                'start_date' => '2025-07-14',
                'end_date' => '2025-12-20',
                'is_active' => false,
            ]
        );

        $genap = Semester::firstOrCreate(
            ['academic_year_id' => $ay->id, 'semester_number' => 2],
            [
                'start_date' => '2026-01-06',
                'end_date' => '2026-06-20',
                'is_active' => true,
            ]
        );

        $this->command->info("  Semesters: Ganjil #{$ganjil->id}, Genap #{$genap->id}");

        return ['ganjil' => $ganjil, 'genap' => $genap];
    }

    // ── Subjects ──────────────────────────────────────────────────

    private function seedSubjects(): array
    {
        $defs = [
            ['code' => 'MTK',  'name' => 'Matematika',        'category' => 'Muatan Nasional'],
            ['code' => 'BIND', 'name' => 'Bahasa Indonesia',   'category' => 'Muatan Nasional'],
            ['code' => 'IPA',  'name' => 'Ilmu Pengetahuan Alam', 'category' => 'Muatan Nasional'],
            ['code' => 'IPS',  'name' => 'Ilmu Pengetahuan Sosial', 'category' => 'Muatan Nasional'],
            ['code' => 'PKN',  'name' => 'Pendidikan Kewarganegaraan', 'category' => 'Muatan Nasional'],
            ['code' => 'PAI',  'name' => 'Pendidikan Agama Islam', 'category' => 'Muatan Nasional'],
            ['code' => 'PJOK', 'name' => 'Pendidikan Jasmani',  'category' => 'Muatan Nasional'],
            ['code' => 'SBDP', 'name' => 'Seni Budaya dan Prakarya', 'category' => 'Muatan Nasional'],
            ['code' => 'BING', 'name' => 'Bahasa Inggris',      'category' => 'Muatan Lokal'],
            ['code' => 'BSUN', 'name' => 'Bahasa Sunda',        'category' => 'Muatan Lokal'],
        ];

        $subjects = [];
        foreach ($defs as $d) {
            $subjects[$d['code']] = Subject::firstOrCreate(
                ['code' => $d['code']],
                [
                    'name' => $d['name'],
                    'education_level' => 'SD',
                    'grade_level' => 4,
                    'kkm' => 75,
                    'category' => $d['category'],
                    'status' => 'active',
                ]
            );
        }

        $this->command->info('  Subjects: ' . count($subjects));

        return $subjects;
    }

    // ── Teachers ──────────────────────────────────────────────────

    private function seedTeachers(): array
    {
        $defs = [
            [
                'email' => 'siti.nurhaliza@floz.test',
                'name' => 'Siti Nurhaliza, S.Pd.',
                'nip' => '198505152010012001',
            ],
            [
                'email' => 'budi.santoso@floz.test',
                'name' => 'Budi Santoso, S.Pd.',
                'nip' => '198207102008011002',
            ],
            [
                'email' => 'ratna.dewi@floz.test',
                'name' => 'Ratna Dewi, S.Pd.',
                'nip' => '199001202012012003',
            ],
            [
                'email' => 'ahmad.hidayat@floz.test',
                'name' => 'Ahmad Hidayat, S.Pd.',
                'nip' => '198803052011011004',
            ],
            [
                'email' => 'teacher@floz.test', // existing test account
                'name' => 'Rina Wati, S.Pd.I.',
                'nip' => '199112152014012005',
            ],
            [
                'email' => 'dewi.lestari@floz.test',
                'name' => 'Dewi Lestari, S.Pd.',
                'nip' => '198706202009012006',
            ],
        ];

        $teachers = [];
        foreach ($defs as $d) {
            $user = User::firstOrCreate(
                ['email' => $d['email']],
                [
                    'name' => $d['name'],
                    'password' => $this->password,
                    'role' => UserRole::Teacher,
                    'is_active' => true,
                    'email_verified_at' => now(),
                ]
            );
            // Update name if already exists (for teacher@floz.test)
            $user->update(['name' => $d['name']]);

            $teacher = Teacher::firstOrCreate(
                ['email' => $d['email']],
                [
                    'name' => $d['name'],
                    'nip' => $d['nip'],
                    'user_id' => $user->id,
                ]
            );

            $teachers[$d['email']] = $teacher;
        }

        $this->command->info('  Teachers: ' . count($teachers));

        return $teachers;
    }

    // ── Classes ───────────────────────────────────────────────────

    private function seedClasses(AcademicYear $ay, array $teachers): array
    {
        $defs = [
            ['name' => 'Kelas 4A', 'level' => 4, 'homeroom' => 'siti.nurhaliza@floz.test'],
            ['name' => 'Kelas 4B', 'level' => 4, 'homeroom' => 'budi.santoso@floz.test'],
            ['name' => 'Kelas 5A', 'level' => 5, 'homeroom' => 'ratna.dewi@floz.test'],
            ['name' => 'Kelas 6A', 'level' => 6, 'homeroom' => 'dewi.lestari@floz.test'],
        ];

        $classes = [];
        foreach ($defs as $d) {
            $class = SchoolClass::firstOrCreate(
                ['name' => $d['name'], 'academic_year_id' => $ay->id],
                [
                    'grade_level' => $d['level'],
                    'homeroom_teacher_id' => $teachers[$d['homeroom']]->id,
                    'max_students' => 30,
                    'status' => 'active',
                ]
            );
            $classes[$d['name']] = $class;
        }

        $this->command->info('  Classes: ' . count($classes));

        return $classes;
    }

    // ── Students ──────────────────────────────────────────────────

    private function seedStudents(array $classes): array
    {
        // Realistic Indonesian student names for Kelas 4A
        $kelas4a = [
            ['nis' => '24001', 'nisn' => '0081234501', 'name' => 'Ahmad Rizki Pratama',      'gender' => 'L'],
            ['nis' => '24002', 'nisn' => '0081234502', 'name' => 'Aisyah Putri Ramadhani',   'gender' => 'P'],
            ['nis' => '24003', 'nisn' => '0081234503', 'name' => 'Dimas Arya Wijaya',         'gender' => 'L'],
            ['nis' => '24004', 'nisn' => '0081234504', 'name' => 'Farah Aulia Zahra',         'gender' => 'P'],
            ['nis' => '24005', 'nisn' => '0081234505', 'name' => 'Galih Setiawan',            'gender' => 'L'],
            ['nis' => '24006', 'nisn' => '0081234506', 'name' => 'Hana Permata Sari',         'gender' => 'P'],
            ['nis' => '24007', 'nisn' => '0081234507', 'name' => 'Irfan Maulana',             'gender' => 'L'],
            ['nis' => '24008', 'nisn' => '0081234508', 'name' => 'Jasmine Khairunnisa',       'gender' => 'P'],
            ['nis' => '24009', 'nisn' => '0081234509', 'name' => 'Kevin Dwi Cahyo',           'gender' => 'L'],
            ['nis' => '24010', 'nisn' => '0081234510', 'name' => 'Lestari Wulandari',         'gender' => 'P'],
            ['nis' => '24011', 'nisn' => '0081234511', 'name' => 'Muhammad Farhan',           'gender' => 'L'],
            ['nis' => '24012', 'nisn' => '0081234512', 'name' => 'Nabila Azzahra',            'gender' => 'P'],
            ['nis' => '24013', 'nisn' => '0081234513', 'name' => 'Omar Hakim',                'gender' => 'L'],
            ['nis' => '24014', 'nisn' => '0081234514', 'name' => 'Putri Amelia Salsabila',    'gender' => 'P'],
        ];

        // Kelas 4B
        $kelas4b = [
            ['nis' => '24015', 'nisn' => '0081234515', 'name' => 'Rafi Aditya Nugraha',  'gender' => 'L'],
            ['nis' => '24016', 'nisn' => '0081234516', 'name' => 'Sinta Maharani',        'gender' => 'P'],
            ['nis' => '24017', 'nisn' => '0081234517', 'name' => 'Taufik Hidayat',        'gender' => 'L'],
            ['nis' => '24018', 'nisn' => '0081234518', 'name' => 'Umi Kalsum',            'gender' => 'P'],
            ['nis' => '24019', 'nisn' => '0081234519', 'name' => 'Vino Bastian',          'gender' => 'L'],
            ['nis' => '24020', 'nisn' => '0081234520', 'name' => 'Winda Safitri',         'gender' => 'P'],
            ['nis' => '24021', 'nisn' => '0081234521', 'name' => 'Yusuf Abdillah',        'gender' => 'L'],
            ['nis' => '24022', 'nisn' => '0081234522', 'name' => 'Zahra Kirana Putri',    'gender' => 'P'],
            ['nis' => '24023', 'nisn' => '0081234523', 'name' => 'Bintang Ramadhan',      'gender' => 'L'],
            ['nis' => '24024', 'nisn' => '0081234524', 'name' => 'Cantika Dewi',          'gender' => 'P'],
        ];

        // Kelas 5A
        $kelas5a = [
            ['nis' => '23001', 'nisn' => '0081234601', 'name' => 'Andi Firmansyah',   'gender' => 'L'],
            ['nis' => '23002', 'nisn' => '0081234602', 'name' => 'Bunga Citra Lestari','gender' => 'P'],
            ['nis' => '23003', 'nisn' => '0081234603', 'name' => 'Cahya Putra Mahesa', 'gender' => 'L'],
            ['nis' => '23004', 'nisn' => '0081234604', 'name' => 'Dina Amalia',        'gender' => 'P'],
            ['nis' => '23005', 'nisn' => '0081234605', 'name' => 'Eko Prasetyo',       'gender' => 'L'],
            ['nis' => '23006', 'nisn' => '0081234606', 'name' => 'Fitri Handayani',    'gender' => 'P'],
            ['nis' => '23007', 'nisn' => '0081234607', 'name' => 'Gilang Ramadhan',    'gender' => 'L'],
            ['nis' => '23008', 'nisn' => '0081234608', 'name' => 'Indah Permatasari',  'gender' => 'P'],
        ];

        $allStudents = [];

        // Map student@floz.test to Kelas 4A (update existing if needed)
        $existingUser = User::where('email', 'student@floz.test')->first();
        if ($existingUser) {
            $existingStudent = Student::where('email', 'student@floz.test')->first();
            if ($existingStudent) {
                $existingStudent->update([
                    'class_id' => $classes['Kelas 4A']->id,
                    'name' => 'Ahmad Rizki Pratama',
                    'nis' => '24001',
                    'nisn' => '0081234501',
                    'gender' => 'L',
                ]);
                $existingUser->update(['name' => 'Ahmad Rizki Pratama']);
                $allStudents[] = $existingStudent;
                // Skip first entry in kelas4a since it maps to existing
                array_shift($kelas4a);
            }
        }

        $classMap = [
            'Kelas 4A' => $kelas4a,
            'Kelas 4B' => $kelas4b,
            'Kelas 5A' => $kelas5a,
        ];

        foreach ($classMap as $className => $studentList) {
            if (! isset($classes[$className])) {
                continue;
            }
            $classId = $classes[$className]->id;

            foreach ($studentList as $s) {
                $email = strtolower(str_replace([' ', '.', ','], '', $s['name'])) . '@siswa.floz.test';

                $user = User::firstOrCreate(
                    ['email' => $email],
                    [
                        'name' => $s['name'],
                        'password' => $this->password,
                        'role' => UserRole::Student,
                        'is_active' => true,
                        'email_verified_at' => now(),
                    ]
                );

                $student = Student::firstOrCreate(
                    ['nis' => $s['nis']],
                    [
                        'nisn' => $s['nisn'],
                        'name' => $s['name'],
                        'email' => $email,
                        'gender' => $s['gender'],
                        'class_id' => $classId,
                        'status' => 'active',
                    ]
                );

                $allStudents[] = $student;
            }
        }

        $this->command->info('  Students: ' . count($allStudents));

        return $allStudents;
    }

    // ── Teaching Assignments ──────────────────────────────────────

    private function seedTeachingAssignments(
        AcademicYear $ay,
        array $teachers,
        array $subjects,
        array $classes
    ): array {
        // teacher email => [[subject_code, class_name], ...]
        $assignments = [
            'siti.nurhaliza@floz.test' => [
                ['MTK', 'Kelas 4A'], ['IPA', 'Kelas 4A'],
            ],
            'budi.santoso@floz.test' => [
                ['BIND', 'Kelas 4A'], ['BIND', 'Kelas 4B'], ['IPS', 'Kelas 4B'],
            ],
            'ratna.dewi@floz.test' => [
                ['PKN', 'Kelas 4A'], ['SBDP', 'Kelas 4A'],
                ['PKN', 'Kelas 5A'],
            ],
            'ahmad.hidayat@floz.test' => [
                ['PJOK', 'Kelas 4A'], ['PJOK', 'Kelas 4B'], ['PJOK', 'Kelas 5A'],
            ],
            'teacher@floz.test' => [
                ['PAI', 'Kelas 4A'], ['PAI', 'Kelas 4B'],
                ['BING', 'Kelas 4A'], ['BING', 'Kelas 5A'],
            ],
            'dewi.lestari@floz.test' => [
                ['BSUN', 'Kelas 4A'], ['BSUN', 'Kelas 4B'],
                ['MTK', 'Kelas 5A'], ['IPA', 'Kelas 5A'],
            ],
        ];

        $tas = [];
        foreach ($assignments as $email => $combos) {
            $teacher = $teachers[$email] ?? null;
            if (! $teacher) {
                continue;
            }

            foreach ($combos as [$subjectCode, $className]) {
                $subject = $subjects[$subjectCode] ?? null;
                $class = $classes[$className] ?? null;
                if (! $subject || ! $class) {
                    continue;
                }

                $ta = TeachingAssignment::firstOrCreate(
                    [
                        'teacher_id' => $teacher->id,
                        'subject_id' => $subject->id,
                        'class_id' => $class->id,
                        'academic_year_id' => $ay->id,
                    ]
                );

                $tas[] = $ta;
            }
        }

        $this->command->info('  Teaching Assignments: ' . count($tas) . ' (meetings auto-generated)');

        return $tas;
    }

    // ── Schedules ─────────────────────────────────────────────────

    private function seedSchedules(array $tas): void
    {
        // Build a lookup: class_id => [ta1, ta2, ...]
        $byClass = collect($tas)->groupBy('class_id');

        $periods = [
            ['07:00:00', '07:35:00'],
            ['07:35:00', '08:10:00'],
            ['08:10:00', '08:45:00'],
            ['09:00:00', '09:35:00'], // after break
            ['09:35:00', '10:10:00'],
            ['10:10:00', '10:45:00'],
        ];

        $count = 0;
        foreach ($byClass as $classId => $classTas) {
            $taList = $classTas->values();
            $taIndex = 0;

            for ($day = 1; $day <= 5; $day++) { // Mon-Fri
                foreach ($periods as $i => [$start, $end]) {
                    $ta = $taList[$taIndex % $taList->count()];
                    $taIndex++;

                    Schedule::firstOrCreate(
                        [
                            'teaching_assignment_id' => $ta->id,
                            'day_of_week' => $day,
                            'start_time' => $start,
                        ],
                        ['end_time' => $end]
                    );
                    $count++;
                }
            }
        }

        $this->command->info("  Schedules: {$count}");
    }

    // ── Grades ────────────────────────────────────────────────────

    private function seedGrades(
        array $students,
        array $subjects,
        array $classes,
        array $semesters,
        array $teachers
    ): void {
        $semester = $semesters['genap'];
        $kelas4aId = $classes['Kelas 4A']->id ?? null;
        if (! $kelas4aId) {
            return;
        }

        $kelas4aStudents = collect($students)->filter(fn ($s) => $s->class_id === $kelas4aId);

        // Subjects taught in 4A
        $subjectCodes = ['MTK', 'BIND', 'IPA', 'PKN', 'PJOK', 'PAI', 'BING', 'SBDP', 'BSUN'];

        $count = 0;
        foreach ($kelas4aStudents as $student) {
            foreach ($subjectCodes as $code) {
                $subject = $subjects[$code] ?? null;
                if (! $subject) {
                    continue;
                }

                // Realistic score variation
                $daily = rand(65, 95);
                $mid = rand(60, 95);
                $final = rand(60, 95);
                $finalScore = round(($daily * 0.3 + $mid * 0.3 + $final * 0.4), 2);
                $predicate = match (true) {
                    $finalScore >= 90 => 'A',
                    $finalScore >= 80 => 'B',
                    $finalScore >= 70 => 'C',
                    default => 'D',
                };

                Grade::firstOrCreate(
                    [
                        'student_id' => $student->id,
                        'subject_id' => $subject->id,
                        'semester_id' => $semester->id,
                    ],
                    [
                        'class_id' => $kelas4aId,
                        'daily_test_avg' => $daily,
                        'mid_test' => $mid,
                        'final_test' => $final,
                        'final_score' => $finalScore,
                        'predicate' => $predicate,
                        'notes' => $finalScore >= 75 ? 'Tuntas' : 'Perlu perbaikan',
                    ]
                );
                $count++;
            }
        }

        $this->command->info("  Grades: {$count}");
    }

    // ── Attendance ────────────────────────────────────────────────

    private function seedAttendance(
        array $students,
        array $classes,
        array $semesters
    ): void {
        $semester = $semesters['genap'];
        $kelas4aId = $classes['Kelas 4A']->id ?? null;
        if (! $kelas4aId) {
            return;
        }

        $kelas4aStudents = collect($students)->filter(fn ($s) => $s->class_id === $kelas4aId);
        $statuses = ['hadir', 'hadir', 'hadir', 'hadir', 'hadir', 'hadir', 'hadir', 'hadir', 'sakit', 'izin', 'alpha'];
        $startDate = Carbon::parse('2026-01-06');
        $count = 0;

        foreach ($kelas4aStudents as $student) {
            // 16 meetings (1 per meeting_number, unique constraint safe)
            for ($meetingNumber = 1; $meetingNumber <= 16; $meetingNumber++) {
                $date = $startDate->copy()->addWeekdays($meetingNumber - 1);
                $status = $statuses[array_rand($statuses)];

                Attendance::firstOrCreate(
                    [
                        'student_id' => $student->id,
                        'class_id' => $kelas4aId,
                        'semester_id' => $semester->id,
                        'meeting_number' => $meetingNumber,
                    ],
                    [
                        'date' => $date->toDateString(),
                        'status' => $status,
                        'notes' => $status === 'sakit' ? 'Demam' : ($status === 'izin' ? 'Acara keluarga' : null),
                    ]
                );
                $count++;
            }
        }

        $this->command->info("  Attendance: {$count}");
    }

    // ── Announcements ─────────────────────────────────────────────

    private function seedAnnouncements(): void
    {
        $admin = User::where('role', UserRole::SchoolAdmin)->first()
            ?? User::firstOrCreate(
                ['email' => 'admin@floz.test'],
                [
                    'name' => 'Admin Sekolah',
                    'password' => $this->password,
                    'role' => UserRole::SchoolAdmin,
                    'is_active' => true,
                    'email_verified_at' => now(),
                ]
            );

        $announcements = [
            [
                'title' => 'Jadwal Ujian Tengah Semester Genap 2025/2026',
                'content' => '<p>Assalamu\'alaikum Wr. Wb.</p><p>Diberitahukan kepada seluruh siswa/i SDN Kelapa Dua IV bahwa Ujian Tengah Semester (UTS) Genap akan dilaksanakan pada tanggal <strong>10-14 Maret 2026</strong>.</p><p>Siswa diharapkan mempersiapkan diri dengan baik. Jadwal ujian per mata pelajaran akan dibagikan melalui wali kelas masing-masing.</p><p>Wassalamu\'alaikum Wr. Wb.</p>',
                'type' => 'warning',
                'is_pinned' => true,
                'target_audience' => 'all',
            ],
            [
                'title' => 'Libur Hari Raya Idul Fitri 1447 H',
                'content' => '<p>Sehubungan dengan Hari Raya Idul Fitri 1447 H, kegiatan belajar mengajar diliburkan pada tanggal <strong>28 Maret - 7 April 2026</strong>. Kegiatan belajar mengajar kembali aktif pada hari Rabu, 8 April 2026.</p><p>Selamat Hari Raya Idul Fitri, mohon maaf lahir dan batin. 🙏</p>',
                'type' => 'info',
                'is_pinned' => true,
                'target_audience' => 'all',
            ],
            [
                'title' => 'Penerimaan Rapor Semester Ganjil',
                'content' => '<p>Penerimaan rapor semester Ganjil 2025/2026 akan dilaksanakan pada hari <strong>Sabtu, 20 Desember 2025</strong> pukul 08.00 - 12.00 WIB. Orang tua/wali murid wajib hadir untuk mengambil rapor.</p><p>Mohon membawa:</p><ul><li>Kartu pelajar siswa</li><li>Buku penghubung</li></ul>',
                'type' => 'info',
                'is_pinned' => false,
                'target_audience' => 'all',
            ],
            [
                'title' => 'Kegiatan Class Meeting Semester Genap',
                'content' => '<p>Class meeting semester Genap akan diselenggarakan pada tanggal <strong>16-18 Juni 2026</strong>. Kegiatan meliputi lomba futsal, menggambar, hafalan surat pendek, dan cerdas cermat.</p><p>Pendaftaran melalui ketua kelas masing-masing. Ayo semangat!</p>',
                'type' => 'info',
                'is_pinned' => false,
                'target_audience' => 'students',
            ],
            [
                'title' => 'Pengumpulan Administrasi Guru',
                'content' => '<p>Kepada seluruh guru SDN Kelapa Dua IV, dimohon untuk mengumpulkan administrasi pembelajaran (RPP, Silabus, Prota, Prosem) paling lambat tanggal <strong>25 April 2026</strong>.</p><p>File bisa diunggah ke Google Drive sekolah atau diserahkan langsung ke Tata Usaha.</p>',
                'type' => 'warning',
                'is_pinned' => false,
                'target_audience' => 'teachers',
            ],
            [
                'title' => 'Upacara Bendera Hari Senin',
                'content' => '<p>Mengingatkan kepada seluruh siswa/i bahwa upacara bendera dilaksanakan setiap hari Senin pukul 07.00 WIB. Siswa wajib mengenakan seragam lengkap (merah-putih) dan sepatu hitam.</p><p>Petugas upacara minggu depan: Kelas 5A.</p>',
                'type' => 'info',
                'is_pinned' => false,
                'target_audience' => 'all',
            ],
            [
                'title' => 'Vaksinasi Siswa Kelas 4',
                'content' => '<p>Vaksinasi campak-rubella untuk siswa kelas 4 akan dilaksanakan pada hari <strong>Kamis, 24 April 2026</strong> bekerja sama dengan Puskesmas Kelapa Dua.</p><p>Orang tua yang keberatan dimohon menghubungi wali kelas untuk mengisi surat pernyataan.</p>',
                'type' => 'warning',
                'is_pinned' => false,
                'target_audience' => 'all',
            ],
            [
                'title' => 'Peringatan Hari Kartini',
                'content' => '<p>Dalam rangka memperingati Hari Kartini, pada hari <strong>Selasa, 21 April 2026</strong> seluruh siswi diperkenankan memakai pakaian adat atau kebaya. Kegiatan lomba fashion show akan diadakan di aula sekolah.</p>',
                'type' => 'info',
                'is_pinned' => false,
                'target_audience' => 'students',
            ],
        ];

        foreach ($announcements as $a) {
            Announcement::firstOrCreate(
                ['title' => $a['title']],
                array_merge($a, [
                    'user_id' => $admin->id,
                    'is_published' => true,
                    'excerpt' => \Illuminate\Support\Str::limit(strip_tags($a['content']), 120),
                ])
            );
        }

        $this->command->info('  Announcements: ' . count($announcements));
    }

    // ── Report Cards ──────────────────────────────────────────────

    private function seedReportCards(
        array $students,
        array $classes,
        array $semesters
    ): void {
        $semester = $semesters['ganjil']; // Rapor for completed semester
        $kelas4aId = $classes['Kelas 4A']->id ?? null;
        if (! $kelas4aId) {
            return;
        }

        $kelas4aStudents = collect($students)->filter(fn ($s) => $s->class_id === $kelas4aId);
        $count = 0;

        foreach ($kelas4aStudents as $i => $student) {
            $avg = rand(72, 92);
            ReportCard::firstOrCreate(
                [
                    'student_id' => $student->id,
                    'semester_id' => $semester->id,
                ],
                [
                    'class_id' => $kelas4aId,
                    'report_type' => 'final',
                    'average_score' => $avg,
                    'total_score' => $avg * 9, // 9 subjects
                    'rank' => $i + 1,
                    'attendance_present' => rand(85, 95),
                    'attendance_sick' => rand(1, 5),
                    'attendance_permit' => rand(0, 3),
                    'attendance_absent' => rand(0, 2),
                    'homeroom_comment' => $avg >= 80
                        ? 'Prestasi baik, pertahankan semangat belajar.'
                        : 'Perlu lebih giat belajar di semester depan.',
                    'principal_comment' => 'Terus tingkatkan prestasi belajar.',
                    'notes' => 'Aktif dalam kegiatan ekstrakurikuler.',
                    'status' => 'published',
                    'published_at' => Carbon::parse('2025-12-20'),
                ]
            );
            $count++;
        }

        $this->command->info("  Report Cards: {$count}");
    }

    // ── Assignments ───────────────────────────────────────────────

    private function seedAssignments(array $tas, array $classes): void
    {
        $kelas4aId = $classes['Kelas 4A']->id ?? null;
        if (! $kelas4aId) {
            return;
        }

        // Filter TAs for Kelas 4A only
        $kelas4aTas = collect($tas)->filter(fn ($ta) => $ta->class_id === $kelas4aId);

        $assignmentDefs = [
            [
                'title' => 'Latihan Soal Pecahan',
                'description' => '<p>Kerjakan latihan soal pecahan halaman 45-47 di buku paket Matematika. Tulis jawaban di buku tugas dan kumpulkan pada pertemuan berikutnya.</p>',
                'type' => 'essay',
                'due_offset' => 7,
            ],
            [
                'title' => 'Menulis Karangan Narasi',
                'description' => '<p>Tulis karangan narasi dengan tema "Pengalaman Liburan" minimal 3 paragraf. Perhatikan penggunaan tanda baca dan ejaan yang benar.</p>',
                'type' => 'essay',
                'due_offset' => 10,
            ],
            [
                'title' => 'Laporan Percobaan IPA: Siklus Air',
                'description' => '<p>Buat laporan percobaan sederhana tentang siklus air. Gunakan format: Judul, Alat & Bahan, Langkah Kerja, Hasil Pengamatan, Kesimpulan.</p><p>Sertakan gambar atau foto percobaan.</p>',
                'type' => 'essay',
                'due_offset' => 14,
            ],
            [
                'title' => 'Menghafal Surat Al-Falaq',
                'description' => '<p>Hafalkan Surat Al-Falaq beserta artinya. Setoran hafalan dilakukan di kelas pada jadwal PAI berikutnya.</p>',
                'type' => 'essay',
                'due_offset' => 5,
            ],
            [
                'title' => 'Menggambar Pemandangan Alam',
                'description' => '<p>Gambarlah pemandangan alam di kertas gambar A3 menggunakan crayon atau pensil warna. Tema bebas, bisa gunung, pantai, atau sawah.</p>',
                'type' => 'essay',
                'due_offset' => 12,
            ],
        ];

        $count = 0;
        foreach ($kelas4aTas->take(5) as $i => $ta) {
            if (! isset($assignmentDefs[$i])) {
                break;
            }

            $def = $assignmentDefs[$i];
            $meeting = $ta->meetings()->where('meeting_number', rand(3, 8))->first();

            $assignment = OfflineAssignment::firstOrCreate(
                ['title' => $def['title'], 'teacher_id' => $ta->teacher_id],
                [
                    'subject_id' => $ta->subject_id,
                    'description' => $def['description'],
                    'due_date' => now()->addDays($def['due_offset']),
                    'status' => 'active',
                    'type' => $def['type'],
                    'created_by' => $ta->teacher_id,
                    'meeting_id' => $meeting?->id,
                ]
            );

            // Attach to class if not already
            if (! $assignment->classes()->where('class_id', $kelas4aId)->exists()) {
                $assignment->classes()->attach($kelas4aId);
            }

            $count++;
        }

        $this->command->info("  Assignments: {$count}");
    }
}
