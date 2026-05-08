# Plan: AcademicYear + Semester Web CRUD

## Goal

Give school admins a web UI (Inertia/Vue 3) to create, edit, delete, and activate academic years and semesters — eliminating the current dependency on seeders/tinker for calendar management and unblocking Phase 7 (school-year transition wizard).

---

## Scope

### Resources

**AcademicYear** (`academic_years` table)
- `id`, `name` (string, e.g. "2025/2026"), `start_date` (date), `end_date` (date), `is_active` (boolean), `created_at`, `updated_at`
- Relations: `hasMany(Semester)`, `hasMany(SchoolClass)`

**Semester** (`semesters` table)
- `id`, `academic_year_id` (FK), `semester_number` (integer, 1 or 2), `start_date` (date), `end_date` (date), `is_active` (boolean), `created_at`, `updated_at`
- Relations: `belongsTo(AcademicYear)`, `hasMany(Grade)`, `hasMany(ReportCard)`

### Business Rules

1. **Only one `AcademicYear` can be `is_active = true` at a time.** Activating one deactivates all others atomically in a DB transaction. (Confirmed from DemoDataSeeder: `AcademicYear::query()->update(['is_active' => false])` before setting the new one.)
2. **Only one `Semester` can be `is_active = true` per academic year.** (Seeder creates two semesters per year; only one is active.) Activating a semester deactivates all siblings of the same `academic_year_id`.
3. **Semesters are scoped to their academic year.** Semester index page is accessed via `/academic-years/{academicYear}/semesters`. `semester_number` is 1 or 2 only.
4. **Deletion guard:** AcademicYear cannot be deleted if it has associated classes (FK cascade from SchoolClass). Semester cannot be deleted if it has associated grades or report cards. Controller catches `QueryException` (FK violation) and returns a 422 with user-friendly message.
5. **Name uniqueness:** `academic_years.name` must be unique. `(academic_year_id, semester_number)` pair must be unique.
6. **Date ranges:** `end_date` must be after `start_date`.
7. **Authorization:** Only `school_admin` can write (create/update/delete/activate). All authenticated users can view (index/show).

---

## Routes

```php
// Academic Years
Route::resource('academic-years', AcademicYearController::class);
Route::post('academic-years/{academicYear}/activate', [AcademicYearController::class, 'activate'])
    ->name('academic-years.activate');

// Semesters (nested under academic year)
Route::resource('academic-years.semesters', SemesterController::class)
    ->shallow();
Route::post('semesters/{semester}/activate', [SemesterController::class, 'activate'])
    ->name('semesters.activate');
```

Named routes generated:
- `academic-years.index` → `GET /academic-years`
- `academic-years.create` → `GET /academic-years/create`
- `academic-years.store` → `POST /academic-years`
- `academic-years.edit` → `GET /academic-years/{academicYear}/edit`
- `academic-years.update` → `PUT /academic-years/{academicYear}`
- `academic-years.destroy` → `DELETE /academic-years/{academicYear}`
- `academic-years.activate` → `POST /academic-years/{academicYear}/activate`
- `academic-years.semesters.index` → `GET /academic-years/{academicYear}/semesters`
- `academic-years.semesters.create` → `GET /academic-years/{academicYear}/semesters/create`
- `academic-years.semesters.store` → `POST /academic-years/{academicYear}/semesters`
- `semesters.edit` → `GET /semesters/{semester}/edit` (shallow)
- `semesters.update` → `PUT /semesters/{semester}` (shallow)
- `semesters.destroy` → `DELETE /semesters/{semester}` (shallow)
- `semesters.activate` → `POST /semesters/{semester}/activate`

---

## File Structure

### Create (new files)

**Backend:**
- `src/app/Http/Controllers/AcademicYearController.php`
- `src/app/Http/Controllers/SemesterController.php`
- `src/app/Policies/AcademicYearPolicy.php`
- `src/app/Policies/SemesterPolicy.php`
- `src/app/Http/Requests/StoreAcademicYearRequest.php`
- `src/app/Http/Requests/UpdateAcademicYearRequest.php`
- `src/app/Http/Requests/StoreSemesterRequest.php`
- `src/app/Http/Requests/UpdateSemesterRequest.php`
- `src/tests/Feature/AcademicYearTest.php`
- `src/tests/Feature/SemesterTest.php`

**Frontend:**
- `src/resources/js/Pages/AcademicYears/Index.vue`
- `src/resources/js/Pages/AcademicYears/Form.vue`
- `src/resources/js/Pages/Semesters/Index.vue`
- `src/resources/js/Pages/Semesters/Form.vue`

### Modify (existing files)

- `src/routes/web.php` — add resource routes + activate routes
- `src/app/Http/Middleware/HandleInertiaRequests.php` — add `manage_academic_years` permission key
- `src/resources/js/Layouts/AppLayout.vue` — add nav items under LAINNYA divider (admin-only)
- `src/app/Providers/AppServiceProvider.php` — register policies (verify auto-discovery first; add Gate::policy() if needed)

---

## Tasks (TDD, task-by-task)

### Task 1: AcademicYearController + Policy + Routes + Tests (backend)

**Files created:** `AcademicYearController.php`, `AcademicYearPolicy.php`, `StoreAcademicYearRequest.php`, `UpdateAcademicYearRequest.php`, `tests/Feature/AcademicYearTest.php`
**Files modified:** `routes/web.php`, `HandleInertiaRequests.php`, `AppServiceProvider.php`

#### Step 1 — Write failing test

Create `src/tests/Feature/AcademicYearTest.php`:

```php
<?php

use App\Models\AcademicYear;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

// ── helpers ──────────────────────────────────────────────────────────

function adminUser(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function teacherUser(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

// ── index ─────────────────────────────────────────────────────────────

it('admin can view academic years index', function () {
    $admin = adminUser();
    AcademicYear::factory()->count(3)->create();

    $this->actingAs($admin)
        ->get(route('academic-years.index'))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('AcademicYears/Index')
            ->has('academicYears.data', 3)
        );
});

it('teacher can view academic years index (read-only)', function () {
    $teacher = teacherUser();
    $this->actingAs($teacher)
        ->get(route('academic-years.index'))
        ->assertOk();
});

it('guest is redirected to login', function () {
    $this->get(route('academic-years.index'))
        ->assertRedirect(route('login'));
});

// ── store ─────────────────────────────────────────────────────────────

it('admin can create an academic year', function () {
    $admin = adminUser();

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-07-13',
            'end_date'   => '2027-06-18',
            'is_active'  => false,
        ])
        ->assertRedirect(route('academic-years.index'));

    $this->assertDatabaseHas('academic_years', ['name' => '2026/2027']);
});

it('teacher cannot create an academic year (403)', function () {
    $teacher = teacherUser();

    $this->actingAs($teacher)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-07-13',
            'end_date'   => '2027-06-18',
        ])
        ->assertForbidden();
});

it('store validates required fields', function () {
    $admin = adminUser();

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [])
        ->assertSessionHasErrors(['name', 'start_date', 'end_date']);
});

it('store validates end_date must be after start_date', function () {
    $admin = adminUser();

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-12-01',
            'end_date'   => '2026-07-01', // before start
        ])
        ->assertSessionHasErrors(['end_date']);
});

it('store validates name uniqueness', function () {
    $admin = adminUser();
    AcademicYear::factory()->create(['name' => '2026/2027']);

    $this->actingAs($admin)
        ->post(route('academic-years.store'), [
            'name'       => '2026/2027',
            'start_date' => '2026-07-13',
            'end_date'   => '2027-06-18',
        ])
        ->assertSessionHasErrors(['name']);
});

// ── update ────────────────────────────────────────────────────────────

it('admin can update an academic year', function () {
    $admin = adminUser();
    $ay = AcademicYear::factory()->create(['name' => 'Old Name']);

    $this->actingAs($admin)
        ->put(route('academic-years.update', $ay), [
            'name'       => 'New Name',
            'start_date' => $ay->start_date->toDateString(),
            'end_date'   => $ay->end_date->toDateString(),
        ])
        ->assertRedirect(route('academic-years.index'));

    $this->assertDatabaseHas('academic_years', ['id' => $ay->id, 'name' => 'New Name']);
});

it('teacher cannot update an academic year (403)', function () {
    $teacher = teacherUser();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->put(route('academic-years.update', $ay), ['name' => 'Hack'])
        ->assertForbidden();
});

// ── destroy ───────────────────────────────────────────────────────────

it('admin can delete an academic year with no dependents', function () {
    $admin = adminUser();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->delete(route('academic-years.destroy', $ay))
        ->assertRedirect(route('academic-years.index'));

    $this->assertDatabaseMissing('academic_years', ['id' => $ay->id]);
});

it('delete returns 422 with message when academic year has classes', function () {
    $admin = adminUser();
    // Create AY with a class attached
    $ay = AcademicYear::factory()
        ->has(\App\Models\SchoolClass::factory()->count(1), 'classes')
        ->create();

    $this->actingAs($admin)
        ->delete(route('academic-years.destroy', $ay))
        ->assertStatus(422)
        ->assertSessionHasErrors(['message']);
});

// ── activate ──────────────────────────────────────────────────────────

it('activate sets target year active and deactivates all others atomically', function () {
    $admin = adminUser();
    $ay1 = AcademicYear::factory()->create(['is_active' => true]);
    $ay2 = AcademicYear::factory()->create(['is_active' => false]);

    $this->actingAs($admin)
        ->post(route('academic-years.activate', $ay2))
        ->assertRedirect(route('academic-years.index'));

    expect($ay1->fresh()->is_active)->toBeFalse();
    expect($ay2->fresh()->is_active)->toBeTrue();
});

it('teacher cannot activate an academic year (403)', function () {
    $teacher = teacherUser();
    $ay = AcademicYear::factory()->create(['is_active' => false]);

    $this->actingAs($teacher)
        ->post(route('academic-years.activate', $ay))
        ->assertForbidden();
});
```

#### Step 2 — Run, confirm fail

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/AcademicYearTest.php
```

Expected: all tests fail (route not found / class not found).

#### Step 3 — Implement

**`src/app/Policies/AcademicYearPolicy.php`:**
```php
<?php

namespace App\Policies;

use App\Models\AcademicYear;
use App\Models\User;

class AcademicYearPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // all authenticated users can list
    }

    public function view(User $user, AcademicYear $academicYear): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return $user->isSchoolAdmin();
    }

    public function update(User $user, AcademicYear $academicYear): bool
    {
        return $user->isSchoolAdmin();
    }

    public function delete(User $user, AcademicYear $academicYear): bool
    {
        return $user->isSchoolAdmin();
    }

    public function activate(User $user, AcademicYear $academicYear): bool
    {
        return $user->isSchoolAdmin();
    }
}
```

**`src/app/Http/Requests/StoreAcademicYearRequest.php`:**
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAcademicYearRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', \App\Models\AcademicYear::class);
    }

    public function rules(): array
    {
        return [
            'name'       => 'required|string|max:20|unique:academic_years,name',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }
}
```

**`src/app/Http/Requests/UpdateAcademicYearRequest.php`:**
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAcademicYearRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('academicYear'));
    }

    public function rules(): array
    {
        $id = $this->route('academicYear')->id;
        return [
            'name'       => "required|string|max:20|unique:academic_years,name,{$id}",
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }
}
```

**`src/app/Http/Controllers/AcademicYearController.php`:**
```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAcademicYearRequest;
use App\Http\Requests\UpdateAcademicYearRequest;
use App\Models\AcademicYear;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\QueryException;
use Inertia\Inertia;
use Inertia\Response;

class AcademicYearController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(AcademicYear::class, 'academicYear');
    }

    public function index(): Response
    {
        $academicYears = AcademicYear::withCount('semesters')
            ->orderByDesc('start_date')
            ->paginate(20);

        return Inertia::render('AcademicYears/Index', [
            'academicYears' => $academicYears,
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('AcademicYears/Form');
    }

    public function store(StoreAcademicYearRequest $request): RedirectResponse
    {
        AcademicYear::create($request->validated());

        return redirect()->route('academic-years.index')
            ->with('success', 'Tahun ajaran berhasil dibuat.');
    }

    public function edit(AcademicYear $academicYear): Response
    {
        return Inertia::render('AcademicYears/Form', [
            'academicYear' => $academicYear,
        ]);
    }

    public function update(UpdateAcademicYearRequest $request, AcademicYear $academicYear): RedirectResponse
    {
        $academicYear->update($request->validated());

        return redirect()->route('academic-years.index')
            ->with('success', 'Tahun ajaran berhasil diperbarui.');
    }

    public function destroy(AcademicYear $academicYear): RedirectResponse
    {
        $this->authorize('delete', $academicYear);

        try {
            $academicYear->delete();
        } catch (QueryException $e) {
            return back()->withErrors([
                'message' => 'Tahun ajaran tidak bisa dihapus karena masih memiliki data kelas.',
            ]);
        }

        return redirect()->route('academic-years.index')
            ->with('success', 'Tahun ajaran berhasil dihapus.');
    }

    public function activate(AcademicYear $academicYear): RedirectResponse
    {
        $this->authorize('activate', $academicYear);

        DB::transaction(function () use ($academicYear) {
            AcademicYear::query()->update(['is_active' => false]);
            $academicYear->update(['is_active' => true]);
        });

        return redirect()->route('academic-years.index')
            ->with('success', "Tahun ajaran {$academicYear->name} sekarang aktif.");
    }
}
```

**Modify `src/routes/web.php`** — add inside the `auth` middleware group:
```php
use App\Http\Controllers\AcademicYearController;
use App\Http\Controllers\SemesterController;

// Academic Years
Route::resource('academic-years', AcademicYearController::class);
Route::post('academic-years/{academicYear}/activate', [AcademicYearController::class, 'activate'])
    ->name('academic-years.activate');
```

**Modify `src/app/Http/Middleware/HandleInertiaRequests.php`** — add to permissions array:
```php
'manage_academic_years' => $user->isSchoolAdmin(),
```

**Check policy auto-discovery:** Laravel auto-discovers `AcademicYearPolicy` for `AcademicYear` model if naming matches. Run:
```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan tinker --execute="dump(Gate::getPolicyFor(App\Models\AcademicYear::class));"
```
If null, add to `AppServiceProvider::boot()`:
```php
Gate::policy(\App\Models\AcademicYear::class, \App\Policies\AcademicYearPolicy::class);
```

#### Step 4 — Run, confirm pass

```bash
./vendor/bin/pest tests/Feature/AcademicYearTest.php
```

Expected: 13 tests pass.

#### Step 5 — Commit

```bash
git add src/app/Http/Controllers/AcademicYearController.php \
        src/app/Policies/AcademicYearPolicy.php \
        src/app/Http/Requests/StoreAcademicYearRequest.php \
        src/app/Http/Requests/UpdateAcademicYearRequest.php \
        src/routes/web.php \
        src/app/Http/Middleware/HandleInertiaRequests.php \
        src/app/Providers/AppServiceProvider.php \
        src/tests/Feature/AcademicYearTest.php
git commit -m "feat(academic-years): admin CRUD with activate flow"
```

---

### Task 2: SemesterController + Policy + Routes + Tests (backend)

**Files created:** `SemesterController.php`, `SemesterPolicy.php`, `StoreSemesterRequest.php`, `UpdateSemesterRequest.php`, `tests/Feature/SemesterTest.php`
**Files modified:** `routes/web.php` (semester routes), `AppServiceProvider.php` (if auto-discovery fails)

#### Step 1 — Write failing test

Create `src/tests/Feature/SemesterTest.php`:

```php
<?php

use App\Models\AcademicYear;
use App\Models\Semester;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

function semesterAdmin(): User
{
    return User::factory()->create(['role' => 'school_admin']);
}

function semesterTeacher(): User
{
    return User::factory()->create(['role' => 'teacher']);
}

// ── index ─────────────────────────────────────────────────────────────

it('admin can view semesters for an academic year', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    Semester::factory()->count(2)->create(['academic_year_id' => $ay->id]);

    $this->actingAs($admin)
        ->get(route('academic-years.semesters.index', $ay))
        ->assertOk()
        ->assertInertia(fn ($page) => $page
            ->component('Semesters/Index')
            ->has('semesters', 2)
            ->has('academicYear')
        );
});

// ── store ─────────────────────────────────────────────────────────────

it('admin can create a semester', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create([
        'start_date' => '2026-07-01',
        'end_date'   => '2027-06-30',
    ]);

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    $this->assertDatabaseHas('semesters', [
        'academic_year_id' => $ay->id,
        'semester_number'  => 1,
    ]);
});

it('teacher cannot create a semester (403)', function () {
    $teacher = semesterTeacher();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($teacher)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertForbidden();
});

it('store validates semester_number is 1 or 2', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 3,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertSessionHasErrors(['semester_number']);
});

it('store validates uniqueness of semester_number within academic year', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 1]);

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-20',
        ])
        ->assertSessionHasErrors(['semester_number']);
});

it('store validates end_date must be after start_date', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();

    $this->actingAs($admin)
        ->post(route('academic-years.semesters.store', $ay), [
            'semester_number' => 1,
            'start_date'      => '2026-12-01',
            'end_date'        => '2026-07-01',
        ])
        ->assertSessionHasErrors(['end_date']);
});

// ── update ────────────────────────────────────────────────────────────

it('admin can update a semester', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    $sem = Semester::factory()->create([
        'academic_year_id' => $ay->id,
        'semester_number'  => 1,
        'start_date'       => '2026-07-01',
        'end_date'         => '2026-12-20',
    ]);

    $this->actingAs($admin)
        ->put(route('semesters.update', $sem), [
            'semester_number' => 1,
            'start_date'      => '2026-07-01',
            'end_date'        => '2026-12-31',
        ])
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    expect($sem->fresh()->end_date->toDateString())->toBe('2026-12-31');
});

// ── destroy ───────────────────────────────────────────────────────────

it('admin can delete a semester with no dependents', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    $sem = Semester::factory()->create(['academic_year_id' => $ay->id]);

    $this->actingAs($admin)
        ->delete(route('semesters.destroy', $sem))
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    $this->assertDatabaseMissing('semesters', ['id' => $sem->id]);
});

// ── activate ──────────────────────────────────────────────────────────

it('activate sets semester active and deactivates siblings', function () {
    $admin = semesterAdmin();
    $ay = AcademicYear::factory()->create();
    $sem1 = Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 1, 'is_active' => true]);
    $sem2 = Semester::factory()->create(['academic_year_id' => $ay->id, 'semester_number' => 2, 'is_active' => false]);

    $this->actingAs($admin)
        ->post(route('semesters.activate', $sem2))
        ->assertRedirect(route('academic-years.semesters.index', $ay));

    expect($sem1->fresh()->is_active)->toBeFalse();
    expect($sem2->fresh()->is_active)->toBeTrue();
});

it('teacher cannot activate a semester (403)', function () {
    $teacher = semesterTeacher();
    $ay = AcademicYear::factory()->create();
    $sem = Semester::factory()->create(['academic_year_id' => $ay->id, 'is_active' => false]);

    $this->actingAs($teacher)
        ->post(route('semesters.activate', $sem))
        ->assertForbidden();
});
```

#### Step 2 — Run, confirm fail

```bash
./vendor/bin/pest tests/Feature/SemesterTest.php
```

#### Step 3 — Implement

**`src/app/Policies/SemesterPolicy.php`:**
```php
<?php

namespace App\Policies;

use App\Models\Semester;
use App\Models\User;

class SemesterPolicy
{
    public function viewAny(User $user): bool { return true; }
    public function view(User $user, Semester $semester): bool { return true; }
    public function create(User $user): bool { return $user->isSchoolAdmin(); }
    public function update(User $user, Semester $semester): bool { return $user->isSchoolAdmin(); }
    public function delete(User $user, Semester $semester): bool { return $user->isSchoolAdmin(); }
    public function activate(User $user, Semester $semester): bool { return $user->isSchoolAdmin(); }
}
```

**`src/app/Http/Requests/StoreSemesterRequest.php`:**
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSemesterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', \App\Models\Semester::class);
    }

    public function rules(): array
    {
        $ayId = $this->route('academicYear')->id;
        return [
            'semester_number' => [
                'required',
                'integer',
                Rule::in([1, 2]),
                Rule::unique('semesters')->where('academic_year_id', $ayId),
            ],
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }

    public function messages(): array
    {
        return [
            'semester_number.unique' => 'Semester ini sudah ada untuk tahun ajaran ini.',
            'semester_number.in'     => 'Semester hanya boleh bernilai 1 atau 2.',
        ];
    }
}
```

**`src/app/Http/Requests/UpdateSemesterRequest.php`:**
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateSemesterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('update', $this->route('semester'));
    }

    public function rules(): array
    {
        $sem = $this->route('semester');
        return [
            'semester_number' => [
                'required',
                'integer',
                Rule::in([1, 2]),
                Rule::unique('semesters')
                    ->where('academic_year_id', $sem->academic_year_id)
                    ->ignore($sem->id),
            ],
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ];
    }
}
```

**`src/app/Http/Controllers/SemesterController.php`:**
```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreSemesterRequest;
use App\Http\Requests\UpdateSemesterRequest;
use App\Models\AcademicYear;
use App\Models\Semester;
use Illuminate\Database\QueryException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class SemesterController extends Controller
{
    public function index(AcademicYear $academicYear): Response
    {
        $this->authorize('viewAny', Semester::class);

        return Inertia::render('Semesters/Index', [
            'academicYear' => $academicYear,
            'semesters'    => $academicYear->semesters()->orderBy('semester_number')->get(),
        ]);
    }

    public function create(AcademicYear $academicYear): Response
    {
        $this->authorize('create', Semester::class);

        return Inertia::render('Semesters/Form', [
            'academicYear' => $academicYear,
        ]);
    }

    public function store(StoreSemesterRequest $request, AcademicYear $academicYear): RedirectResponse
    {
        $academicYear->semesters()->create($request->validated());

        return redirect()->route('academic-years.semesters.index', $academicYear)
            ->with('success', 'Semester berhasil dibuat.');
    }

    public function edit(Semester $semester): Response
    {
        $this->authorize('update', $semester);

        return Inertia::render('Semesters/Form', [
            'academicYear' => $semester->academicYear,
            'semester'     => $semester,
        ]);
    }

    public function update(UpdateSemesterRequest $request, Semester $semester): RedirectResponse
    {
        $semester->update($request->validated());

        return redirect()->route('academic-years.semesters.index', $semester->academic_year_id)
            ->with('success', 'Semester berhasil diperbarui.');
    }

    public function destroy(Semester $semester): RedirectResponse
    {
        $this->authorize('delete', $semester);
        $ayId = $semester->academic_year_id;

        try {
            $semester->delete();
        } catch (QueryException $e) {
            return back()->withErrors([
                'message' => 'Semester tidak bisa dihapus karena masih memiliki data nilai atau rapor.',
            ]);
        }

        return redirect()->route('academic-years.semesters.index', $ayId)
            ->with('success', 'Semester berhasil dihapus.');
    }

    public function activate(Semester $semester): RedirectResponse
    {
        $this->authorize('activate', $semester);

        DB::transaction(function () use ($semester) {
            Semester::where('academic_year_id', $semester->academic_year_id)
                ->update(['is_active' => false]);
            $semester->update(['is_active' => true]);
        });

        return redirect()->route('academic-years.semesters.index', $semester->academic_year_id)
            ->with('success', "Semester {$semester->semester_number} sekarang aktif.");
    }
}
```

**Add to `src/routes/web.php`** (inside `auth` group):
```php
// Semesters (nested + shallow)
Route::resource('academic-years.semesters', SemesterController::class)->shallow();
Route::post('semesters/{semester}/activate', [SemesterController::class, 'activate'])
    ->name('semesters.activate');
```

#### Step 4 — Run, confirm pass

```bash
./vendor/bin/pest tests/Feature/SemesterTest.php
```

Expected: 12 tests pass.

#### Step 5 — Commit

```bash
git add src/app/Http/Controllers/SemesterController.php \
        src/app/Policies/SemesterPolicy.php \
        src/app/Http/Requests/StoreSemesterRequest.php \
        src/app/Http/Requests/UpdateSemesterRequest.php \
        src/routes/web.php \
        src/tests/Feature/SemesterTest.php
git commit -m "feat(semesters): admin CRUD with activate flow"
```

---

### Task 3: Vue Pages — AcademicYears/Index.vue + Form.vue

**Clone pattern from:** `Pages/Classes/Index.vue` and `Pages/Subjects/Form.vue`
**UI components used:** `AppLayout`, `Button`, `FormInput`, `Badge` (for active pill), `Pagination`

**`src/resources/js/Pages/AcademicYears/Index.vue`:**

Key sections:
- `defineOptions({ layout: AppLayout })`
- Props: `{ academicYears: Object }` (Laravel paginator shape with `data`, `links`)
- Table columns: Name | Period (start_date – end_date) | Status (active/inactive badge) | Semesters count | Actions
- "Active" badge: green pill if `is_active`, grey if not
- Per-row actions (admin-only, gated by `permissions.manage_academic_years`):
  - "Aktifkan" button → `router.post(route('academic-years.activate', ay.id))` (shown only if `!ay.is_active`)
  - "Edit" link → `route('academic-years.edit', ay.id)`
  - "Hapus" button → confirm dialog → `router.delete(route('academic-years.destroy', ay.id))`
- Top-right "Tambah Tahun Ajaran" button (admin-only) → `Link` to `route('academic-years.create')`
- "Kelola Semester" link per row → `route('academic-years.semesters.index', ay.id)`
- Flash success/error handled by AppLayout's Toast (already wired via `page.props.flash`)

```vue
<script setup>
import { Link, router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import { computed } from 'vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    academicYears: Object,
});

const page = usePage();
const canManage = computed(() => page.props.auth?.permissions?.manage_academic_years);

function activate(id) {
    router.post(route('academic-years.activate', id));
}

function destroy(id) {
    if (confirm('Hapus tahun ajaran ini? Data yang terkait akan ikut terhapus.')) {
        router.delete(route('academic-years.destroy', id));
    }
}
</script>

<template>
    <Head title="Tahun Ajaran" />
    <div class="p-6">
        <div class="mb-6 flex items-center justify-between">
            <h1 class="text-2xl font-semibold text-slate-800">Tahun Ajaran</h1>
            <Link v-if="canManage" :href="route('academic-years.create')">
                <Button variant="primary">+ Tambah Tahun Ajaran</Button>
            </Link>
        </div>

        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50 text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <tr>
                        <th class="px-4 py-3 text-left">Nama</th>
                        <th class="px-4 py-3 text-left">Periode</th>
                        <th class="px-4 py-3 text-left">Status</th>
                        <th class="px-4 py-3 text-left">Semester</th>
                        <th class="px-4 py-3 text-left">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    <tr v-for="ay in academicYears.data" :key="ay.id">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ ay.name }}</td>
                        <td class="px-4 py-3 text-slate-600 text-sm">
                            {{ ay.start_date }} – {{ ay.end_date }}
                        </td>
                        <td class="px-4 py-3">
                            <Badge :variant="ay.is_active ? 'success' : 'neutral'">
                                {{ ay.is_active ? 'Aktif' : 'Tidak Aktif' }}
                            </Badge>
                        </td>
                        <td class="px-4 py-3">
                            <Link :href="route('academic-years.semesters.index', ay.id)"
                                  class="text-orange-600 hover:underline text-sm">
                                {{ ay.semesters_count }} Semester
                            </Link>
                        </td>
                        <td class="px-4 py-3 flex gap-2" v-if="canManage">
                            <Button v-if="!ay.is_active" size="sm" variant="outline"
                                    @click="activate(ay.id)">Aktifkan</Button>
                            <Link :href="route('academic-years.edit', ay.id)">
                                <Button size="sm" variant="ghost">Edit</Button>
                            </Link>
                            <Button size="sm" variant="danger" @click="destroy(ay.id)">Hapus</Button>
                        </td>
                        <td v-else class="px-4 py-3 text-slate-400 text-sm">–</td>
                    </tr>
                    <tr v-if="!academicYears.data.length">
                        <td colspan="5" class="px-4 py-8 text-center text-slate-400">
                            Belum ada tahun ajaran.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <Pagination :links="academicYears.links" class="mt-4" />
    </div>
</template>
```

**`src/resources/js/Pages/AcademicYears/Form.vue`:**

- Props: `{ academicYear: Object|null }` (null = create mode)
- `useForm({ name, start_date, end_date })` from `@inertiajs/vue3`
- `isEditing = computed(() => !!props.academicYear)`
- On submit: `form.post(route('academic-years.store'))` or `form.put(route('academic-years.update', academicYear.id))`
- Validation errors shown inline via `form.errors.name` etc.
- Three `FormInput` fields: Name (text), Start Date (date), End Date (date)
- Cancel link back to index

---

### Task 4: Vue Pages — Semesters/Index.vue + Form.vue

**`src/resources/js/Pages/Semesters/Index.vue`:**

- Props: `{ academicYear: Object, semesters: Array }` (not paginated — max 2 semesters per year)
- Breadcrumb: Tahun Ajaran > {{ academicYear.name }} > Semester
- Table columns: Semester | Periode | Status | Actions
- "Aktifkan" button if `!sem.is_active` → `router.post(route('semesters.activate', sem.id))`
- Edit → `route('semesters.edit', sem.id)`, Delete → `router.delete(route('semesters.destroy', sem.id))`
- "Tambah Semester" button → `route('academic-years.semesters.create', academicYear.id)` (only shown if `semesters.length < 2`)
- Back link to `route('academic-years.index')`

**`src/resources/js/Pages/Semesters/Form.vue`:**

- Props: `{ academicYear: Object, semester: Object|null }`
- `useForm({ semester_number, start_date, end_date })`
- `semester_number` → `<FormSelect>` with options `[{value: 1, label: 'Semester 1'}, {value: 2, label: 'Semester 2'}]`
- On submit: `form.post(route('academic-years.semesters.store', academicYear.id))` or `form.put(route('semesters.update', semester.id))`
- Breadcrumb + cancel link back to `route('academic-years.semesters.index', academicYear.id)`

---

### Task 5: AppLayout nav + permissions wiring

**Modify `src/resources/js/Layouts/AppLayout.vue`:**

In the `navigation` computed array, after the existing `LAINNYA` divider and before `Audit Logs`, add:

```javascript
{ type: 'divider', name: 'KONFIGURASI', show: user.value?.role === 'school_admin' },
{ name: 'Tahun Ajaran', href: '/academic-years', icon: 'calendar', show: permissions.manage_academic_years },
```

Or alternatively, insert inside the existing LAINNYA group (before Audit Logs):
```javascript
{ name: 'Tahun Ajaran', href: '/academic-years', icon: 'calendar', show: permissions.manage_academic_years },
```

The `icon: 'calendar'` value must match an existing icon in AppLayout's icon rendering switch. **Check which icons exist in AppLayout's SVG switch block** before choosing — use `calendar` or `academic` or whichever key already maps to a suitable SVG, or add a new case.

**Modify `src/app/Http/Middleware/HandleInertiaRequests.php`:**

Add to the `permissions` array (already planned in Task 1):
```php
'manage_academic_years' => $user->isSchoolAdmin(),
```

#### No additional commit — include in Task 5 commit:

```bash
git add src/resources/js/Layouts/AppLayout.vue \
        src/resources/js/Pages/AcademicYears/Index.vue \
        src/resources/js/Pages/AcademicYears/Form.vue \
        src/resources/js/Pages/Semesters/Index.vue \
        src/resources/js/Pages/Semesters/Form.vue
git commit -m "feat(ui): AcademicYears + Semesters admin pages and nav item"
```

---

### Task 6: Model Factories (prerequisite for tests)

**Check if factories exist** before running tests:

```bash
ls /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/database/factories/ | grep -E "AcademicYear|Semester"
```

If `AcademicYearFactory.php` or `SemesterFactory.php` are missing, create them:

**`src/database/factories/AcademicYearFactory.php`:**
```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class AcademicYearFactory extends Factory
{
    public function definition(): array
    {
        $start = $this->faker->dateTimeBetween('-2 years', 'now');
        $end = (clone $start)->modify('+11 months');

        return [
            'name'       => $start->format('Y') . '/' . $end->format('Y'),
            'start_date' => $start->format('Y-m-d'),
            'end_date'   => $end->format('Y-m-d'),
            'is_active'  => false,
        ];
    }
}
```

**`src/database/factories/SemesterFactory.php`:**
```php
<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class SemesterFactory extends Factory
{
    public function definition(): array
    {
        $start = $this->faker->dateTimeBetween('-1 year', 'now');
        $end = (clone $start)->modify('+5 months');

        return [
            'academic_year_id' => AcademicYear::factory(),
            'semester_number'  => $this->faker->randomElement([1, 2]),
            'start_date'       => $start->format('Y-m-d'),
            'end_date'         => $end->format('Y-m-d'),
            'is_active'        => false,
        ];
    }
}
```

Commit:
```bash
git add src/database/factories/AcademicYearFactory.php \
        src/database/factories/SemesterFactory.php
git commit -m "test(factories): AcademicYear + Semester factories for feature tests"
```

> **Run this task BEFORE Task 1** if factories are missing. Adjust order accordingly.

---

### Task 7: Manual smoke test + regression + tag

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan serve &
npm run dev &
```

Manual checklist:
- [ ] Login as school_admin → sidebar shows "Tahun Ajaran" nav item
- [ ] Navigate to `/academic-years` → list renders
- [ ] Create new year `2027/2028` → appears in list
- [ ] Edit year → name/dates update in DB
- [ ] Click "Aktifkan" on inactive year → active badge shifts, others deactivate
- [ ] Navigate to Semester → create Semester 1, create Semester 2
- [ ] Activate Semester 2 → Semester 1 deactivates
- [ ] Login as teacher → `/academic-years` accessible (read-only), no create/edit/delete buttons
- [ ] Attempt `POST /academic-years` as teacher via curl → 403

Run full test suite:
```bash
./vendor/bin/pest
```

Expected: all existing tests still green, 25+ new tests pass.

Tag:
```bash
git tag v0.academic-year-crud
```

---

## Definition of Done

- [ ] Admin can list, create, edit, delete academic years via `/academic-years` UI
- [ ] Admin can mark a year active (others auto-deactivated in DB transaction)
- [ ] Admin can list, create, edit, delete semesters per academic year via `/academic-years/{id}/semesters`
- [ ] Admin can activate a semester (siblings deactivated, scoped to same academic year)
- [ ] Authz: only `school_admin` can write; `teacher` gets 403 on mutating routes; `student`/`parent` gets 403
- [ ] Deletion of year with FK-linked classes returns 422 with Indonesian-language error message
- [ ] Deletion of semester with FK-linked grades/report-cards returns 422
- [ ] `AcademicYearTest.php` passes (13 tests)
- [ ] `SemesterTest.php` passes (12 tests)
- [ ] `manage_academic_years` permission key exposed in Inertia shared props
- [ ] Nav item "Tahun Ajaran" appears in sidebar for `school_admin` only
- [ ] Existing test suite still green (no regressions)
- [ ] No tinker/seeder required to create or activate a year or semester

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Activate flow race condition (two admins simultaneously activate different years) | Low (single school, single admin) | DB transaction wraps the update pair; last write wins — acceptable |
| Deleting AY with SchoolClass FK cascade (classes has `onDelete('cascade')`) | Medium | Classes table has `academic_year_id` with cascade, so AY delete would cascade-delete classes. Must guard: check `$ay->classes()->exists()` BEFORE delete call, return 422 proactively rather than catching FK error after cascade |
| `Semester::where('is_active', true)->first()` in services broken during activate | Medium | Activate is atomic in transaction — in-flight requests resolve before or after; no partial state window |
| `semester_number` uniqueness: factory generates duplicates in tests | Medium | Explicitly set `semester_number` in each test, don't rely on factory randomness for uniqueness-dependent tests |
| AppLayout icon key not existing for `calendar` | Low | Read the existing icon switch in AppLayout before using key; add new SVG case if needed |
| Shallow routing mismatch: `semesters.update` route needs `academic_year_id` to redirect back | Low | Controller reads `$semester->academic_year_id` directly — no route parameter needed |

---

## Estimated Time Budget

| Task | Estimate |
|------|----------|
| Task 0: Check/create factories | 10 min |
| Task 1: AcademicYear backend (TDD) | 30 min |
| Task 2: Semester backend (TDD) | 30 min |
| Task 3: AcademicYears Vue pages | 30 min |
| Task 4: Semesters Vue pages | 20 min |
| Task 5: Nav + permissions | 15 min |
| Task 6: Smoke test + regression | 25 min |
| **Total** | **~2h 40min** |
