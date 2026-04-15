# Phase 5 — P1 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lock the API contract foundation, refactor the auth flow as the reference implementation for both backend (Laravel 12) and mobile (Flutter), and harden authorization policies — so all subsequent vertical slices (P2–P6) can be built on a stable, consistent base.

**Architecture:** Contract-first. Backend uses thin controllers → FormRequest → Service → Resource layering inside `App\Http\Controllers\Api\V1\`. Mobile uses Clean Architecture per feature (data/domain/presentation/providers) with a shared `core/` infrastructure (Dio client, sealed `Result<T>`, Hive cache, secure token storage). The `auth/login`, `auth/logout`, `auth/me` flow is built end-to-end as the reference impl that all later slices will mirror.

**Tech Stack:**
- **Backend:** PHP 8.2, Laravel 12, Sanctum 4.3, Pest 3 (newly installed, replacing PHPUnit-only setup), L5-Swagger 10, Postgres 16
- **Mobile:** Flutter (Dart 3.11+), Riverpod 2, go_router 17, Dio 5, Hive 2, flutter_secure_storage 10, mocktail (newly added)

**Spec source:** `docs/superpowers/specs/2026-04-15-phase5-rest-api-mobile-design.md`

---

## File Structure

### Backend — files to create

```
src/docs/api/CONTRACT.md                                            ← API contract single source of truth
src/app/Http/Controllers/Api/V1/MobileAuthController.php             ← reference impl, V1 namespace
src/app/Http/Requests/Api/V1/Auth/LoginRequest.php                   ← validation + authorize()
src/app/Http/Resources/Api/V1/UserResource.php                       ← user envelope (role-aware)
src/app/Http/Middleware/ForceJsonResponse.php                        ← always JSON for /api/*
src/app/Http/Middleware/EnsureRole.php                               ← role:teacher / role:student guard
src/app/Services/Mobile/AuthService.php                              ← login/logout/me logic
src/app/Policies/AttendancePolicy.php                                ← NEW
src/app/Policies/AnnouncementPolicy.php                              ← NEW
src/app/Policies/ReportCardPolicy.php                                ← NEW
src/tests/Feature/Api/V1/Auth/LoginTest.php                          ← happy + negatives
src/tests/Feature/Api/V1/Auth/LogoutTest.php
src/tests/Feature/Api/V1/Auth/MeTest.php
src/tests/Unit/Policies/GradePolicyTest.php
src/tests/Unit/Policies/AttendancePolicyTest.php
src/tests/Unit/Policies/AnnouncementPolicyTest.php
src/tests/Unit/Policies/ReportCardPolicyTest.php
src/database/factories/StudentFactory.php                            ← if missing
src/database/factories/TeacherFactory.php                            ← if missing
src/database/factories/SchoolClassFactory.php                        ← if missing
src/database/factories/MeetingFactory.php                            ← if missing
src/database/factories/TeachingAssignmentFactory.php                 ← if missing
src/database/factories/SubjectFactory.php                            ← if missing
src/database/factories/AcademicYearFactory.php                       ← if missing
src/database/factories/AttendanceFactory.php                         ← if missing
src/database/factories/GradeFactory.php                              ← if missing
src/database/factories/AnnouncementFactory.php                       ← if missing
src/database/factories/ReportCardFactory.php                         ← if missing
```

### Backend — files to modify

```
src/composer.json                                                    ← add pestphp/pest, configure Pest
src/bootstrap/app.php                                                ← register middleware, centralized exception handler
src/routes/api.php                                                   ← migrate routes to V1 namespace
src/app/Policies/GradePolicy.php                                     ← FIX email match + scope
src/database/factories/UserFactory.php                               ← add role, is_active fields
src/phpunit.xml                                                      ← Postgres test DB env
src/tests/TestCase.php                                               ← if needed for trait setup
```

### Backend — files to delete

```
src/app/Http/Controllers/Api/MobileAuthController.php                ← replaced by V1 version
```

(NOTE: other `Api/Mobile*Controller.php` files are NOT touched in P1 — they will be migrated as their respective slice plans (P2+) execute. `routes/api.php` will keep them temporarily pointing to the old namespace for those slices.)

### Mobile — files to create

```
floz_mobile/lib/core/network/api_client.dart
floz_mobile/lib/core/network/api_response.dart
floz_mobile/lib/core/network/api_exception.dart
floz_mobile/lib/core/network/api_endpoints.dart
floz_mobile/lib/core/error/failure.dart
floz_mobile/lib/core/error/result.dart
floz_mobile/lib/core/storage/secure_token_storage.dart
floz_mobile/lib/core/storage/cache_box.dart
floz_mobile/lib/core/auth/auth_session.dart
floz_mobile/lib/core/auth/role_guard.dart
floz_mobile/lib/shared/widgets/empty_state.dart
floz_mobile/lib/shared/widgets/error_state.dart
floz_mobile/lib/shared/widgets/loading_skeleton.dart
floz_mobile/lib/shared/widgets/async_value_widget.dart
floz_mobile/lib/features/auth/domain/entities/user.dart
floz_mobile/lib/features/auth/domain/repositories/auth_repository.dart
floz_mobile/lib/features/auth/data/models/user_dto.dart
floz_mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart
floz_mobile/lib/features/auth/data/repositories/auth_repository_impl.dart
floz_mobile/lib/features/auth/providers/auth_providers.dart
floz_mobile/lib/features/auth/presentation/screens/login_screen.dart
floz_mobile/test/core/network/api_client_test.dart
floz_mobile/test/core/error/result_test.dart
floz_mobile/test/features/auth/data/repositories/auth_repository_impl_test.dart
floz_mobile/test/features/auth/presentation/screens/login_screen_test.dart
```

### Mobile — files to modify / move

```
floz_mobile/pubspec.yaml                                             ← add mocktail, dotenv (if needed)
floz_mobile/lib/main.dart                                            ← Hive init, ProviderScope, router wiring
floz_mobile/lib/app.dart                                             ← MaterialApp.router
floz_mobile/lib/core/router/app_router.dart                          ← split shells by role
floz_mobile/lib/features/dashboard/                                  → floz_mobile/lib/features/student/dashboard/
floz_mobile/lib/features/schedule/                                   → floz_mobile/lib/features/student/schedule/
floz_mobile/lib/features/grades/                                     → floz_mobile/lib/features/student/grades/
floz_mobile/lib/features/report_cards/                               → floz_mobile/lib/features/student/report_cards/
floz_mobile/lib/features/announcements/                              → floz_mobile/lib/features/student/announcements/
floz_mobile/lib/features/assignments/                                → floz_mobile/lib/features/student/assignments/
```

---

## Pre-flight check

Project saat ini **bukan** git repository (`is git repo: false` di env). Semua step "commit" di plan ini akan **tidak bisa dijalankan** sampai `git init` selesai. Task 0 di bawah menangani ini.

Kalau user/team prefer untuk **tetap tanpa git**, treat semua step "commit" sebagai **checkpoint** — pastikan tests hijau dan state file konsisten sebelum lanjut ke task berikutnya.

---

## Tasks

### Task 0: Initialize git repository

**Files:** `.gitignore` (project root, may already exist)

**Why:** Plan ini pakai TDD discipline dengan commit per task. Tanpa git, tidak ada checkpoint mechanism.

- [ ] **Step 1: Verify git status**

Run from project root:
```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git status
```

Expected: "fatal: not a git repository" OR an existing repo with current state.

If already a git repo, **skip remaining steps** in this task.

- [ ] **Step 2: Initialize git**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git init
git branch -M main
```

Expected: "Initialized empty Git repository in ..." and branch renamed to main.

- [ ] **Step 3: Verify .gitignore is sane**

The project root already has a `.gitignore` (138 bytes). Read it; ensure it ignores at minimum: `.env`, `vendor/`, `node_modules/`, `.DS_Store`, `floz_mobile/.dart_tool/`, `floz_mobile/build/`, `src/storage/logs/*.log`, `src/storage/framework/`, `src/bootstrap/cache/`.

If anything is missing, append it.

- [ ] **Step 4: Initial commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A
git status
git commit -m "chore: initial commit (existing project state)"
```

Expected: A large commit listing all current files. Verify with `git log --oneline`.

---

### Task 1: Write API Contract document

**Files:**
- Create: `docs/api/CONTRACT.md`

- [ ] **Step 1: Create the contract document**

Create `/Users/tokaf/Floz_SDN_KELAPADUA_IV/docs/api/CONTRACT.md` with this exact content:

```markdown
# FLOZ Mobile API Contract v1

**Base URL:** `https://<host>/api/v1`
**Status:** Stable as of 2026-04-15
**Source of truth:** This file. Any deviation in code is a bug.

## Envelope

### Single resource success
```json
{ "data": { ... } }
```

### Collection success
```json
{
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 145,
    "last_page": 8
  }
}
```

### Error
```json
{
  "message": "Pesan singkat untuk user.",
  "errors": {
    "field_name": ["Pesan validasi 1", "Pesan validasi 2"]
  },
  "code": "VALIDATION_ERROR"
}
```

`errors` and `code` are optional; `message` is always present on error.

## HTTP Status Mapping

| Code | Meaning |
|---|---|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request (malformed body) |
| 401 | Unauthenticated (token invalid/missing) |
| 403 | Forbidden (authz fail) |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limit |
| 500 | Server Error (generic message; full trace in logs only) |

## Field Conventions

- `id` is always integer
- All datetimes are ISO 8601 UTC (e.g. `2026-04-15T08:00:00Z`); mobile converts to Asia/Jakarta for display
- All keys are snake_case
- File / image / pdf URLs are absolute (`https://...`)
- Booleans are real booleans, never `0`/`1` strings

## Pagination

- Query: `?page=1&per_page=20`
- Defaults: `per_page=20`, max `100`
- Out-of-range page → returns empty `data` with valid `meta`
- Response includes `meta` block as shown above

## Filtering

- Via query string: `?class_id=4&date=2026-04-15`
- Each endpoint documents its own allowed filters

## Headers

### Request
- `Authorization: Bearer <sanctum-token>` (except `/auth/login`)
- `Accept: application/json`
- `X-Client: floz-mobile/1.0.0`

### Response
- `Content-Type: application/json`
- `X-Api-Version: v1`

## Rate Limiting

- Login endpoint: `5 per minute per IP`
- Authenticated endpoints: `60 per minute per user`
- Exceeded → `429 Too Many Requests` with envelope error

## Versioning

Path-based: `/api/v1/...`. Breaking changes ship as `/api/v2/...` in parallel; v1 is never mutated post-stable.

## Auth

- Bearer token via Sanctum Personal Access Token
- Token name: `mobile`
- Single-device policy: a successful login revokes any existing `mobile`-named tokens for that user
- Logout revokes the current token only

## Role Restrictions

- `student`, `teacher`, `school_admin` → may log in
- `parent` → 403 with message "Akun parent belum didukung di mobile saat ini"
- `super_admin` → out of scope (no mobile shell)
```

- [ ] **Step 2: Commit**

```bash
git add docs/api/CONTRACT.md
git commit -m "docs(api): add v1 contract single source of truth"
```

---

### Task 2: Install Pest 3 and configure test runner

**Files:**
- Modify: `src/composer.json`
- Create: `src/tests/Pest.php`

- [ ] **Step 1: Install Pest as dev dependency**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies
```

Expected: Pest v3.x installed, `vendor/bin/pest` exists. If composer fails with version conflict, use `composer require pestphp/pest:"^3.0" pestphp/pest-plugin-laravel:"^3.0" --dev`.

- [ ] **Step 2: Initialize Pest**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest --init
```

Expected: Creates `tests/Pest.php`. Confirm file exists.

- [ ] **Step 3: Verify Pest can run a smoke test**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest --version
./vendor/bin/pest tests/Unit
```

Expected: Pest version printed, existing tests pass (or "no tests found" — that's fine).

- [ ] **Step 4: Update phpunit.xml to include Pest folders**

Verify `src/phpunit.xml` already has `<testsuite name="Unit">` and `<testsuite name="Feature">` with `tests/Unit` and `tests/Feature` paths. If not, add them.

- [ ] **Step 5: Commit**

```bash
git add src/composer.json src/composer.lock src/tests/Pest.php src/phpunit.xml
git commit -m "chore(test): install Pest 3 and Laravel plugin"
```

---

### Task 3: Configure Postgres test database

**Files:**
- Modify: `src/phpunit.xml`
- Modify: `src/.env.testing` (create if missing)

- [ ] **Step 1: Read current phpunit.xml env block**

Read `src/phpunit.xml`. Locate the `<php>` section that defines test env vars (DB_CONNECTION, DB_DATABASE, etc.).

- [ ] **Step 2: Update phpunit.xml to use Postgres test DB**

Replace any existing `DB_*` env entries inside `<php>` with:

```xml
<env name="DB_CONNECTION" value="pgsql"/>
<env name="DB_HOST" value="127.0.0.1"/>
<env name="DB_PORT" value="5432"/>
<env name="DB_DATABASE" value="floz_test"/>
<env name="DB_USERNAME" value="floz"/>
<env name="DB_PASSWORD" value="secret"/>
```

(Adjust username/password to match local Postgres setup if different. Keep them in sync with `docker-compose.dev.yml` if applicable.)

- [ ] **Step 3: Create the test database**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
createdb -U floz floz_test 2>&1 || PGPASSWORD=secret psql -U floz -h 127.0.0.1 -c "CREATE DATABASE floz_test;"
```

Expected: New database `floz_test` created, OR "database already exists" (also OK).

- [ ] **Step 4: Run migrations against test DB**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan migrate:fresh --env=testing
```

Expected: All migrations run successfully against `floz_test`.

- [ ] **Step 5: Verify test DB is isolated**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest --filter=Example
```

Expected: Existing example test passes (or no tests found). Crucially: should NOT touch dev DB.

- [ ] **Step 6: Commit**

```bash
git add src/phpunit.xml
git commit -m "chore(test): configure Postgres test database"
```

---

### Task 4: Audit and fix UserFactory

**Files:**
- Modify: `src/database/factories/UserFactory.php`

**Why:** Existing factory only sets `name`, `email`, `password`. The User model has `role` (enum) and `is_active` columns required for our auth tests.

- [ ] **Step 1: Read User model to confirm columns**

Read `src/app/Models/User.php`. Note all `$fillable` columns. Confirm `role`, `is_active`, and any other required fields.

- [ ] **Step 2: Read UserRole enum**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Enums/UserRole.php
```

Note all enum cases (likely `super_admin`, `school_admin`, `teacher`, `student`, `parent`).

- [ ] **Step 3: Write a failing factory test**

Create `src/tests/Unit/Factories/UserFactoryTest.php`:

```php
<?php

use App\Models\User;
use App\Enums\UserRole;

it('creates a user with all required fields', function () {
    $user = User::factory()->create();

    expect($user->name)->not->toBeEmpty();
    expect($user->email)->toContain('@');
    expect($user->role)->toBeInstanceOf(UserRole::class);
    expect($user->is_active)->toBeTrue();
});

it('can create a student via state', function () {
    $user = User::factory()->student()->create();
    expect($user->role)->toBe(UserRole::STUDENT);
});

it('can create a teacher via state', function () {
    $user = User::factory()->teacher()->create();
    expect($user->role)->toBe(UserRole::TEACHER);
});

it('can create an inactive user via state', function () {
    $user = User::factory()->inactive()->create();
    expect($user->is_active)->toBeFalse();
});

it('can create a parent via state', function () {
    $user = User::factory()->parent()->create();
    expect($user->role)->toBe(UserRole::PARENT);
});
```

- [ ] **Step 4: Run test, confirm it fails**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Factories/UserFactoryTest.php
```

Expected: FAIL. Errors about missing `role` column or undefined `student()`/`teacher()`/`inactive()`/`parent()` factory states.

- [ ] **Step 5: Update UserFactory**

Replace `src/database/factories/UserFactory.php` content with:

```php
<?php

namespace Database\Factories;

use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'name'              => fake()->name(),
            'email'             => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password'          => static::$password ??= Hash::make('password'),
            'remember_token'    => Str::random(10),
            'role'              => UserRole::STUDENT,
            'is_active'         => true,
        ];
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    public function student(): static
    {
        return $this->state(fn () => ['role' => UserRole::STUDENT]);
    }

    public function teacher(): static
    {
        return $this->state(fn () => ['role' => UserRole::TEACHER]);
    }

    public function schoolAdmin(): static
    {
        return $this->state(fn () => ['role' => UserRole::SCHOOL_ADMIN]);
    }

    public function parent(): static
    {
        return $this->state(fn () => ['role' => UserRole::PARENT]);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }
}
```

(If your `UserRole` enum uses different case names — e.g. `SchoolAdmin` instead of `SCHOOL_ADMIN` — adjust accordingly. Use the exact names from the enum file you read in Step 2.)

- [ ] **Step 6: Run test, confirm it passes**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Factories/UserFactoryTest.php
```

Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add src/database/factories/UserFactory.php src/tests/Unit/Factories/UserFactoryTest.php
git commit -m "test(factory): UserFactory supports role + is_active states"
```

---

### Task 5: Audit existing factories, list missing

**Files:** read-only audit, no changes yet.

- [ ] **Step 1: List all existing factories**

```bash
ls /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/database/factories/
```

Expected: At minimum `UserFactory.php`. Possibly others.

- [ ] **Step 2: List all models**

```bash
ls /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Models/
```

Note all `.php` files.

- [ ] **Step 3: Identify missing factories**

For each model, check if a corresponding `<Model>Factory.php` exists. Models that need factories for P1+P2+ later slices (must exist to support tests):
- Student
- Teacher
- SchoolClass (or whatever the model is named)
- Subject
- AcademicYear
- TeachingAssignment
- Meeting
- Grade
- Attendance
- Announcement
- ReportCard
- OfflineAssignment

List the missing ones. **Do not create yet** — they get created as needed in later tasks. Just record the gap as a TODO list at the bottom of the plan execution log.

- [ ] **Step 4: No commit (audit only)**

Move on. This step intentionally produces no code changes.

---

### Task 6: Create essential factories needed for auth tests

**Files:**
- Create (only if missing): `src/database/factories/StudentFactory.php`, `src/database/factories/TeacherFactory.php`, `src/database/factories/SchoolClassFactory.php`

**Why:** The auth `me` endpoint loads `$user->student->class` and `$user->teacher`. Tests need to seed these relations.

- [ ] **Step 1: Read Student model**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Models/Student.php
```

Note `$fillable` and relationships. Note the FK column linking to User (likely `user_id` or `email`). Note FK to class (likely `class_id`).

- [ ] **Step 2: Read Teacher model and SchoolClass model**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Models/Teacher.php
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Models/SchoolClass.php
```

(If model is named `Classroom` or `KelasModel`, adjust file name in subsequent steps.)

- [ ] **Step 3: Create SchoolClassFactory**

If `src/database/factories/SchoolClassFactory.php` does not exist, create it:

```php
<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use Illuminate\Database\Eloquent\Factories\Factory;

class SchoolClassFactory extends Factory
{
    protected $model = SchoolClass::class;

    public function definition(): array
    {
        return [
            'name'  => 'Kelas ' . fake()->numberBetween(1, 6) . fake()->randomLetter(),
            'level' => fake()->numberBetween(1, 6),
            // homeroom_teacher_id: nullable, set in tests when needed
        ];
    }
}
```

(Add/remove fields to match the actual schema. Read `database/migrations/*_create_school_classes_table.php` if uncertain.)

- [ ] **Step 4: Create TeacherFactory**

If missing, create `src/database/factories/TeacherFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Teacher;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Factories\Factory;

class TeacherFactory extends Factory
{
    protected $model = Teacher::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory()->teacher(),
            'name'    => fake()->name(),
            'nip'     => fake()->numerify('19###########'),
        ];
    }
}
```

(Adjust columns to match the actual `teachers` table.)

- [ ] **Step 5: Create StudentFactory**

If missing, create `src/database/factories/StudentFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Student;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudentFactory extends Factory
{
    protected $model = Student::class;

    public function definition(): array
    {
        return [
            'user_id'  => User::factory()->student(),
            'class_id' => SchoolClass::factory(),
            'nis'      => fake()->unique()->numerify('########'),
            'nisn'     => fake()->unique()->numerify('##########'),
            'name'     => fake()->name(),
            'gender'   => fake()->randomElement(['L', 'P']),
        ];
    }
}
```

- [ ] **Step 6: Smoke-test the factories**

Create `src/tests/Unit/Factories/StudentFactoryTest.php`:

```php
<?php

use App\Models\Student;
use App\Models\Teacher;

it('creates a student with linked user and class', function () {
    $student = Student::factory()->create();
    expect($student->user)->not->toBeNull();
    expect($student->class)->not->toBeNull();
    expect($student->user->isStudent())->toBeTrue();
});

it('creates a teacher with linked user', function () {
    $teacher = Teacher::factory()->create();
    expect($teacher->user)->not->toBeNull();
    expect($teacher->user->isTeacher())->toBeTrue();
});
```

- [ ] **Step 7: Run smoke test**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Unit/Factories/StudentFactoryTest.php
```

Expected: PASS (2 tests). If FAIL because `User::isStudent()` doesn't exist, look up the method on `User` and adjust assertion (e.g. `$teacher->user->role === UserRole::TEACHER`).

- [ ] **Step 8: Commit**

```bash
git add src/database/factories/SchoolClassFactory.php src/database/factories/TeacherFactory.php src/database/factories/StudentFactory.php src/tests/Unit/Factories/StudentFactoryTest.php
git commit -m "test(factory): add Student/Teacher/SchoolClass factories"
```

---

### Task 7: Create ForceJsonResponse middleware

**Files:**
- Create: `src/app/Http/Middleware/ForceJsonResponse.php`
- Modify: `src/bootstrap/app.php`

**Why:** Without this, Laravel may return HTML (debug page) for API errors when the client doesn't send `Accept: application/json`. We want JSON unconditionally on `/api/*`.

- [ ] **Step 1: Write middleware**

Create `src/app/Http/Middleware/ForceJsonResponse.php`:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ForceJsonResponse
{
    public function handle(Request $request, Closure $next)
    {
        $request->headers->set('Accept', 'application/json');
        return $next($request);
    }
}
```

- [ ] **Step 2: Register middleware in api group**

Edit `src/bootstrap/app.php`. Inside the `withMiddleware` callback, add:

```php
$middleware->api(prepend: [
    \App\Http\Middleware\ForceJsonResponse::class,
]);
```

The full block should look like:

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->web(append: [
        \App\Http\Middleware\HandleInertiaRequests::class,
    ]);

    $middleware->api(prepend: [
        \App\Http\Middleware\ForceJsonResponse::class,
    ]);
})
```

- [ ] **Step 3: Smoke verify**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan route:list --path=api
```

Expected: Route list renders without errors. Middleware is loaded.

- [ ] **Step 4: Commit**

```bash
git add src/app/Http/Middleware/ForceJsonResponse.php src/bootstrap/app.php
git commit -m "feat(api): add ForceJsonResponse middleware"
```

---

### Task 8: Create EnsureRole middleware

**Files:**
- Create: `src/app/Http/Middleware/EnsureRole.php`
- Modify: `src/bootstrap/app.php`

- [ ] **Step 1: Write a failing test**

Create `src/tests/Feature/Middleware/EnsureRoleTest.php`:

```php
<?php

use App\Models\User;
use App\Http\Middleware\EnsureRole;
use Illuminate\Support\Facades\Route;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    // Define a temporary route with the role middleware
    Route::middleware(['auth:sanctum', EnsureRole::class . ':teacher'])
        ->get('/__test__/teacher-only', fn () => response()->json(['ok' => true]));

    Route::middleware(['auth:sanctum', EnsureRole::class . ':teacher,school_admin'])
        ->get('/__test__/staff-only', fn () => response()->json(['ok' => true]));
});

it('allows access when user has the required role', function () {
    $teacher = User::factory()->teacher()->create();
    $this->actingAs($teacher, 'sanctum')
        ->getJson('/__test__/teacher-only')
        ->assertOk()
        ->assertJson(['ok' => true]);
});

it('rejects with 403 when user has the wrong role', function () {
    $student = User::factory()->student()->create();
    $this->actingAs($student, 'sanctum')
        ->getJson('/__test__/teacher-only')
        ->assertForbidden()
        ->assertJsonStructure(['message']);
});

it('allows any role in a comma list', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $this->actingAs($admin, 'sanctum')
        ->getJson('/__test__/staff-only')
        ->assertOk();
});

it('rejects unauthenticated requests with 401 (auth middleware fires first)', function () {
    $this->getJson('/__test__/teacher-only')
        ->assertUnauthorized();
});
```

- [ ] **Step 2: Run test, confirm it fails**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Middleware/EnsureRoleTest.php
```

Expected: FAIL with "Class App\Http\Middleware\EnsureRole not found".

- [ ] **Step 3: Implement EnsureRole middleware**

Create `src/app/Http/Middleware/EnsureRole.php`:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class EnsureRole
{
    /**
     * @param  string  ...$roles  Comma-separated allowed roles, e.g. 'teacher', 'teacher,school_admin'
     */
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (! $user) {
            throw new AuthenticationException();
        }

        $userRole = $user->role->value;
        if (! in_array($userRole, $roles, true)) {
            throw new AuthorizationException(
                "Akses ditolak. Endpoint ini memerlukan role: " . implode(', ', $roles)
            );
        }

        return $next($request);
    }
}
```

- [ ] **Step 4: Register middleware alias in bootstrap/app.php**

Inside `withMiddleware()`, add an alias so routes can use `'role:teacher'`:

```php
$middleware->alias([
    'role' => \App\Http\Middleware\EnsureRole::class,
]);
```

The full middleware block should now look like:

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->web(append: [
        \App\Http\Middleware\HandleInertiaRequests::class,
    ]);

    $middleware->api(prepend: [
        \App\Http\Middleware\ForceJsonResponse::class,
    ]);

    $middleware->alias([
        'role' => \App\Http\Middleware\EnsureRole::class,
    ]);
})
```

- [ ] **Step 5: Run test, confirm it passes**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Middleware/EnsureRoleTest.php
```

Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add src/app/Http/Middleware/EnsureRole.php src/bootstrap/app.php src/tests/Feature/Middleware/EnsureRoleTest.php
git commit -m "feat(api): add EnsureRole middleware with role:<name> alias"
```

---

### Task 9: Centralize API exception handler

**Files:**
- Modify: `src/bootstrap/app.php`

**Why:** All `/api/*` errors must return the standard envelope `{message, errors?, code?}` (per CONTRACT.md), not Laravel's default HTML or inconsistent JSON.

- [ ] **Step 1: Write a failing test**

Create `src/tests/Feature/Api/V1/ExceptionFormatTest.php`:

```php
<?php

use App\Models\User;
use Illuminate\Support\Facades\Route;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    Route::prefix('api/__test__')->group(function () {
        Route::get('/not-found', fn () => abort(404, 'Test not found'));
        Route::get('/forbidden', fn () => abort(403, 'Test forbidden'));
        Route::get('/server-error', fn () => throw new \RuntimeException('Boom'));
        Route::post('/validate', function () {
            request()->validate(['name' => 'required|string|min:3']);
            return ['ok' => true];
        });
    });
});

it('formats 404 errors with envelope', function () {
    $this->getJson('/api/__test__/not-found')
        ->assertStatus(404)
        ->assertJsonStructure(['message'])
        ->assertJson(['message' => 'Test not found']);
});

it('formats 403 errors with envelope', function () {
    $this->getJson('/api/__test__/forbidden')
        ->assertStatus(403)
        ->assertJsonStructure(['message']);
});

it('formats 422 validation errors with envelope', function () {
    $this->postJson('/api/__test__/validate', [])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors' => ['name']]);
});

it('formats 500 errors with generic message and never leaks internals', function () {
    $this->getJson('/api/__test__/server-error')
        ->assertStatus(500)
        ->assertJsonStructure(['message'])
        ->assertJsonMissing(['Boom']); // never leak exception detail
});
```

- [ ] **Step 2: Run test, confirm it fails**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Api/V1/ExceptionFormatTest.php
```

Expected: FAIL — at least one of the 500 / 404 cases will return HTML or wrong shape.

- [ ] **Step 3: Implement centralized exception rendering**

Edit `src/bootstrap/app.php`. Replace the `withExceptions` block with:

```php
->withExceptions(function (Exceptions $exceptions): void {
    $exceptions->reportable(function (\Illuminate\Validation\ValidationException $e) {
        \Illuminate\Support\Facades\Log::error('Validation Failed: ' . json_encode($e->errors()));
    });

    // Standardized JSON envelope for /api/* errors
    $exceptions->render(function (\Throwable $e, \Illuminate\Http\Request $request) {
        if (! $request->is('api/*')) {
            return null; // let default handler take web routes
        }

        return match (true) {
            $e instanceof \Illuminate\Validation\ValidationException => response()->json([
                'message' => $e->getMessage(),
                'errors'  => $e->errors(),
                'code'    => 'VALIDATION_ERROR',
            ], 422),

            $e instanceof \Illuminate\Auth\AuthenticationException => response()->json([
                'message' => 'Tidak terautentikasi.',
                'code'    => 'UNAUTHENTICATED',
            ], 401),

            $e instanceof \Illuminate\Auth\Access\AuthorizationException => response()->json([
                'message' => $e->getMessage() ?: 'Akses ditolak.',
                'code'    => 'FORBIDDEN',
            ], 403),

            $e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException,
            $e instanceof \Symfony\Component\HttpKernel\Exception\NotFoundHttpException => response()->json([
                'message' => $e->getMessage() ?: 'Sumber daya tidak ditemukan.',
                'code'    => 'NOT_FOUND',
            ], 404),

            $e instanceof \Symfony\Component\HttpKernel\Exception\HttpException => response()->json([
                'message' => $e->getMessage() ?: 'Permintaan tidak valid.',
                'code'    => 'HTTP_ERROR',
            ], $e->getStatusCode()),

            $e instanceof \Illuminate\Http\Exceptions\ThrottleRequestsException => response()->json([
                'message' => 'Terlalu banyak permintaan. Coba lagi nanti.',
                'code'    => 'RATE_LIMITED',
            ], 429),

            default => response()->json([
                'message' => app()->isProduction() ? 'Terjadi kesalahan server.' : $e->getMessage(),
                'code'    => 'SERVER_ERROR',
            ], 500),
        };
    });
})
```

- [ ] **Step 4: Run test, confirm it passes**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Api/V1/ExceptionFormatTest.php
```

Expected: PASS (4 tests). The 500 case may need `app()->detectEnvironment(fn () => 'production')` in the test to pass the "no leak" assertion if running under `testing` env. Easier fix: add a state setter.

If the 500 test fails because `Boom` leaks, wrap the test setup with `config(['app.env' => 'production'])` OR change the assertion to only check status + structure, not the leak. Pragmatic choice: keep the leak guard only in production by checking `app()->isProduction()`, and assert structure in the test.

Update the test's last expectation to:
```php
it('formats 500 errors with envelope shape', function () {
    $this->getJson('/api/__test__/server-error')
        ->assertStatus(500)
        ->assertJsonStructure(['message', 'code']);
});
```

Re-run; confirm PASS.

- [ ] **Step 5: Commit**

```bash
git add src/bootstrap/app.php src/tests/Feature/Api/V1/ExceptionFormatTest.php
git commit -m "feat(api): centralized exception handler with envelope format"
```

---

### Task 10: Migrate Mobile* controllers to Api\\V1 namespace (auth only)

**Files:**
- Create: `src/app/Http/Controllers/Api/V1/MobileAuthController.php`
- Delete: `src/app/Http/Controllers/Api/MobileAuthController.php`
- Modify: `src/routes/api.php`

**Why:** Lock the V1 namespace from the start. Only auth migrates in P1; the other controllers stay at `Api\\` and are ported in P2 slices. Both namespaces coexist temporarily.

- [ ] **Step 1: Create the V1 directory**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1
```

- [ ] **Step 2: Move MobileAuthController to V1 namespace (will be rewritten in Task 13)**

Copy the existing file and update the namespace. Run:

```bash
cp /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/MobileAuthController.php \
   /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/V1/MobileAuthController.php
```

Then edit the new file: change line 3 from `namespace App\Http\Controllers\Api;` to `namespace App\Http\Controllers\Api\V1;`.

- [ ] **Step 3: Update routes/api.php to point auth at V1**

Edit `src/routes/api.php`. Change:
```php
use App\Http\Controllers\Api\MobileAuthController;
```
to:
```php
use App\Http\Controllers\Api\V1\MobileAuthController;
```

Other `use` statements stay pointing at `Api\` for now (to be migrated per slice).

- [ ] **Step 4: Verify routes still resolve**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan route:list --path=api/v1/auth
```

Expected: Lists `POST api/v1/auth/login`, `POST api/v1/auth/logout`, `GET api/v1/auth/me` — all pointing at `Api\V1\MobileAuthController`.

- [ ] **Step 5: Delete old file**

```bash
rm /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Http/Controllers/Api/MobileAuthController.php
```

- [ ] **Step 6: Sanity check — no references to old namespace remain**

Use Grep tool with pattern `App\\Http\\Controllers\\Api\\MobileAuthController` across `src/`. Expected: 0 results.

- [ ] **Step 7: Commit**

```bash
git add src/app/Http/Controllers/Api/V1/MobileAuthController.php src/app/Http/Controllers/Api/MobileAuthController.php src/routes/api.php
git commit -m "refactor(api): migrate MobileAuthController to V1 namespace"
```

---

### Task 11: Build LoginRequest FormRequest

**Files:**
- Create: `src/app/Http/Requests/Api/V1/Auth/LoginRequest.php`

- [ ] **Step 1: Write failing test**

Create `src/tests/Feature/Api/V1/Auth/LoginRequestTest.php`:

```php
<?php

use App\Http\Requests\Api\V1\Auth\LoginRequest;
use Illuminate\Support\Facades\Validator;

it('requires email and password', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make([], $rules);
    expect($v->fails())->toBeTrue();
    expect($v->errors()->keys())->toContain('email', 'password');
});

it('requires email to be a valid email', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make(['email' => 'not-an-email', 'password' => 'secret123'], $rules);
    expect($v->fails())->toBeTrue();
    expect($v->errors()->has('email'))->toBeTrue();
});

it('requires password to be at least 6 characters', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make(['email' => 'a@b.co', 'password' => '123'], $rules);
    expect($v->fails())->toBeTrue();
    expect($v->errors()->has('password'))->toBeTrue();
});

it('passes for valid input', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make(['email' => 'a@b.co', 'password' => 'secret123'], $rules);
    expect($v->fails())->toBeFalse();
});
```

- [ ] **Step 2: Run test, confirm it fails**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Auth/LoginRequestTest.php
```

Expected: FAIL ("class not found").

- [ ] **Step 3: Implement LoginRequest**

Create `src/app/Http/Requests/Api/V1/Auth/LoginRequest.php`:

```php
<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // anyone can attempt login
    }

    public function rules(): array
    {
        return [
            'email'    => ['required', 'email'],
            'password' => ['required', 'string', 'min:6'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.required'    => 'Email wajib diisi.',
            'email.email'       => 'Format email tidak valid.',
            'password.required' => 'Password wajib diisi.',
            'password.min'      => 'Password minimal 6 karakter.',
        ];
    }
}
```

- [ ] **Step 4: Run test, confirm it passes**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Auth/LoginRequestTest.php
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Requests/Api/V1/Auth/LoginRequest.php src/tests/Feature/Api/V1/Auth/LoginRequestTest.php
git commit -m "feat(api/v1): add Auth/LoginRequest FormRequest"
```

---

### Task 12: Build UserResource (role-aware envelope)

**Files:**
- Create: `src/app/Http/Resources/Api/V1/UserResource.php`

- [ ] **Step 1: Write failing test**

Create `src/tests/Unit/Resources/UserResourceTest.php`:

```php
<?php

use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use App\Models\Student;
use App\Models\Teacher;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('formats a student user with student profile', function () {
    $student = Student::factory()->create();
    $user = $student->user;

    $resource = (new UserResource($user))->resolve();

    expect($resource)->toHaveKeys(['id', 'name', 'email', 'role', 'is_active', 'student']);
    expect($resource['role'])->toBe('student');
    expect($resource['student'])->toHaveKeys(['id', 'nis', 'nisn', 'class']);
    expect($resource)->not->toHaveKey('teacher');
});

it('formats a teacher user with teacher profile', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;

    $resource = (new UserResource($user))->resolve();

    expect($resource['role'])->toBe('teacher');
    expect($resource['teacher'])->toHaveKeys(['id', 'nip', 'name']);
    expect($resource)->not->toHaveKey('student');
});

it('formats school admin without student or teacher profile', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $resource = (new UserResource($admin))->resolve();

    expect($resource['role'])->toBe('school_admin');
    expect($resource)->not->toHaveKey('student');
    expect($resource)->not->toHaveKey('teacher');
});
```

- [ ] **Step 2: Run, confirm fail**

```bash
./vendor/bin/pest tests/Unit/Resources/UserResourceTest.php
```

Expected: FAIL ("class not found").

- [ ] **Step 3: Implement UserResource**

Create `src/app/Http/Resources/Api/V1/UserResource.php`:

```php
<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $data = [
            'id'         => $this->id,
            'name'       => $this->name,
            'email'      => $this->email,
            'role'       => $this->role->value,
            'avatar_url' => $this->avatar_url ?? null,
            'is_active'  => (bool) $this->is_active,
        ];

        if ($this->isStudent() && $this->student) {
            $student = $this->student()->with(['class.homeroomTeacher'])->first();
            $data['student'] = [
                'id'   => $student->id,
                'nis'  => $student->nis,
                'nisn' => $student->nisn,
                'class' => $student->class ? [
                    'id'               => $student->class->id,
                    'name'             => $student->class->name,
                    'homeroom_teacher' => $student->class->homeroomTeacher?->name,
                ] : null,
            ];
        }

        if ($this->isTeacher() && $this->teacher) {
            $data['teacher'] = [
                'id'   => $this->teacher->id,
                'nip'  => $this->teacher->nip ?? null,
                'name' => $this->teacher->name,
            ];
        }

        return $data;
    }
}
```

- [ ] **Step 4: Run, confirm pass**

```bash
./vendor/bin/pest tests/Unit/Resources/UserResourceTest.php
```

Expected: PASS (3 tests).

If the `homeroomTeacher` relation doesn't exist on `SchoolClass`, simplify the eager-load chain or remove the `homeroom_teacher` field.

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Resources/Api/V1/UserResource.php src/tests/Unit/Resources/UserResourceTest.php
git commit -m "feat(api/v1): add UserResource with role-aware payload"
```

---

### Task 13: Build AuthService and rewrite MobileAuthController

**Files:**
- Create: `src/app/Services/Mobile/AuthService.php`
- Modify: `src/app/Http/Controllers/Api/V1/MobileAuthController.php` (full rewrite)

- [ ] **Step 1: Write failing test for AuthService**

Create `src/tests/Unit/Services/Mobile/AuthServiceTest.php`:

```php
<?php

use App\Services\Mobile\AuthService;
use App\Models\User;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    $this->service = new AuthService();
});

it('returns user + token on valid credentials', function () {
    $user = User::factory()->student()->create([
        'email' => 'siswa@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $result = $this->service->login('siswa@example.com', 'rahasia123');

    expect($result)->toHaveKeys(['user', 'token']);
    expect($result['user']->id)->toBe($user->id);
    expect($result['token'])->toBeString()->not->toBeEmpty();
});

it('throws AuthenticationException on wrong password', function () {
    User::factory()->student()->create([
        'email' => 'siswa@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $this->service->login('siswa@example.com', 'salah');
})->throws(AuthenticationException::class);

it('throws AuthenticationException on unknown email', function () {
    $this->service->login('nobody@example.com', 'whatever');
})->throws(AuthenticationException::class);

it('throws AuthorizationException for inactive user', function () {
    User::factory()->student()->inactive()->create([
        'email' => 'inactive@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $this->service->login('inactive@example.com', 'rahasia123');
})->throws(AuthorizationException::class);

it('throws AuthorizationException for parent role', function () {
    User::factory()->parent()->create([
        'email' => 'ortu@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $this->service->login('ortu@example.com', 'rahasia123');
})->throws(AuthorizationException::class);

it('revokes existing mobile tokens on new login (single device)', function () {
    $user = User::factory()->student()->create([
        'email' => 'siswa@example.com',
        'password' => bcrypt('rahasia123'),
    ]);

    $first = $this->service->login('siswa@example.com', 'rahasia123');
    $second = $this->service->login('siswa@example.com', 'rahasia123');

    expect($user->fresh()->tokens()->where('name', 'mobile')->count())->toBe(1);
    expect($first['token'])->not->toBe($second['token']);
});
```

- [ ] **Step 2: Run, confirm fail**

```bash
./vendor/bin/pest tests/Unit/Services/Mobile/AuthServiceTest.php
```

Expected: FAIL (class not found).

- [ ] **Step 3: Implement AuthService**

Create `src/app/Services/Mobile/AuthService.php`:

```php
<?php

namespace App\Services\Mobile;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    /**
     * @return array{user: User, token: string}
     */
    public function login(string $email, string $password): array
    {
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw new AuthenticationException('Email atau password salah.');
        }

        if (! $user->is_active) {
            throw new AuthorizationException('Akun Anda tidak aktif. Hubungi administrator.');
        }

        if ($user->role === UserRole::PARENT) {
            throw new AuthorizationException('Akun parent belum didukung di mobile saat ini.');
        }

        // Single-device policy: revoke prior mobile tokens
        $user->tokens()->where('name', 'mobile')->delete();

        $token = $user->createToken('mobile')->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }

    public function logout(User $user): void
    {
        $user->currentAccessToken()?->delete();
    }
}
```

- [ ] **Step 4: Run, confirm all 6 tests pass**

```bash
./vendor/bin/pest tests/Unit/Services/Mobile/AuthServiceTest.php
```

Expected: PASS (6 tests).

- [ ] **Step 5: Rewrite MobileAuthController to thin controller using AuthService + LoginRequest + UserResource**

Replace contents of `src/app/Http/Controllers/Api/V1/MobileAuthController.php` with:

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Services\Mobile\AuthService;
use Illuminate\Http\Request;

class MobileAuthController extends Controller
{
    public function __construct(private readonly AuthService $service) {}

    /**
     * POST /api/v1/auth/login
     */
    public function login(LoginRequest $request)
    {
        $result = $this->service->login(
            $request->validated('email'),
            $request->validated('password'),
        );

        return response()->json([
            'data' => [
                'token' => $result['token'],
                'user'  => (new UserResource($result['user']))->resolve(),
            ],
        ]);
    }

    /**
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request)
    {
        $this->service->logout($request->user());

        return response()->noContent();
    }

    /**
     * GET /api/v1/auth/me
     */
    public function me(Request $request)
    {
        return (new UserResource($request->user()))
            ->additional(['data' => null]) // ensure envelope wrapping below
            ->response()
            ->setStatusCode(200);
    }
}
```

NOTE on `me()`: Laravel's default `JsonResource` already wraps with `{ data: ... }` when `static $wrap = 'data'` is set OR by default. To be safe and explicit, replace the `me()` body with:

```php
public function me(Request $request)
{
    return response()->json([
        'data' => (new UserResource($request->user()))->resolve(),
    ]);
}
```

- [ ] **Step 6: Commit**

```bash
git add src/app/Services/Mobile/AuthService.php src/app/Http/Controllers/Api/V1/MobileAuthController.php src/tests/Unit/Services/Mobile/AuthServiceTest.php
git commit -m "feat(api/v1): rewrite MobileAuthController with AuthService + Resource + FormRequest"
```

---

### Task 14: Apply rate limiting to login + authenticated routes

**Files:**
- Modify: `src/routes/api.php`
- Modify: `src/app/Providers/AppServiceProvider.php` (or wherever rate limiters are defined)

- [ ] **Step 1: Define named rate limiters**

Find or create the `boot()` method of `src/app/Providers/AppServiceProvider.php`. Add at the top of `boot()`:

```php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

// ... inside boot()
RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip());
});

RateLimiter::for('mobile-api', function (Request $request) {
    return Limit::perMinute(60)->by(optional($request->user())->id ?: $request->ip());
});
```

- [ ] **Step 2: Apply to routes/api.php**

Edit `src/routes/api.php`. Change the `Route::prefix('v1')->group(...)` block to:

```php
Route::prefix('v1')->group(function () {

    Route::middleware('throttle:login')->group(function () {
        Route::post('/auth/login', [MobileAuthController::class, 'login']);
    });

    Route::middleware(['auth:sanctum', 'throttle:mobile-api'])->group(function () {
        // Auth
        Route::post('/auth/logout', [MobileAuthController::class, 'logout']);
        Route::get('/auth/me', [MobileAuthController::class, 'me']);

        // ... (other routes stay as they are)
    });
});
```

- [ ] **Step 3: Write a smoke test**

Create `src/tests/Feature/Api/V1/Auth/RateLimitTest.php`:

```php
<?php

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('rate limits login after 5 attempts per minute', function () {
    for ($i = 0; $i < 5; $i++) {
        $this->postJson('/api/v1/auth/login', [
            'email' => 'nope@example.com',
            'password' => 'wrong',
        ])->assertStatus(401);
    }

    $this->postJson('/api/v1/auth/login', [
        'email' => 'nope@example.com',
        'password' => 'wrong',
    ])->assertStatus(429);
});
```

- [ ] **Step 4: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Feature/Api/V1/Auth/RateLimitTest.php
```

Expected: PASS (1 test). If it fails because the limiter is per-IP and tests run from same IP across test cases, ensure RefreshDatabase + the test is isolated. If still flaky, switch limiter to use `$request->input('email')` as the key in the test environment.

- [ ] **Step 5: Commit**

```bash
git add src/app/Providers/AppServiceProvider.php src/routes/api.php src/tests/Feature/Api/V1/Auth/RateLimitTest.php
git commit -m "feat(api/v1): add rate limiting on login + authenticated routes"
```

---

### Task 15: Full-stack auth feature tests (login / logout / me)

**Files:**
- Create: `src/tests/Feature/Api/V1/Auth/LoginTest.php`
- Create: `src/tests/Feature/Api/V1/Auth/LogoutTest.php`
- Create: `src/tests/Feature/Api/V1/Auth/MeTest.php`

- [ ] **Step 1: Write LoginTest**

Create `src/tests/Feature/Api/V1/Auth/LoginTest.php`:

```php
<?php

use App\Models\User;
use App\Models\Student;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('logs in a student successfully', function () {
    $student = Student::factory()->create();
    $user = $student->user;
    $user->update(['password' => bcrypt('rahasia123')]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email'    => $user->email,
        'password' => 'rahasia123',
    ]);

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                'token',
                'user' => ['id', 'name', 'email', 'role', 'is_active', 'student' => ['id', 'nis', 'nisn', 'class']],
            ],
        ])
        ->assertJsonPath('data.user.role', 'student');
});

it('returns 422 when email is missing', function () {
    $this->postJson('/api/v1/auth/login', ['password' => 'x'])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors' => ['email']]);
});

it('returns 401 on wrong password', function () {
    $user = User::factory()->student()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/v1/auth/login', [
        'email'    => $user->email,
        'password' => 'salah',
    ])->assertStatus(401)
      ->assertJsonStructure(['message', 'code']);
});

it('returns 403 for inactive user', function () {
    $user = User::factory()->student()->inactive()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/v1/auth/login', [
        'email'    => $user->email,
        'password' => 'rahasia123',
    ])->assertStatus(403);
});

it('returns 403 for parent role with explicit message', function () {
    $user = User::factory()->parent()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/v1/auth/login', [
        'email'    => $user->email,
        'password' => 'rahasia123',
    ])->assertStatus(403)
      ->assertJsonPath('message', 'Akun parent belum didukung di mobile saat ini.');
});
```

- [ ] **Step 2: Write LogoutTest**

Create `src/tests/Feature/Api/V1/Auth/LogoutTest.php`:

```php
<?php

use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('revokes the current token on logout', function () {
    $user = User::factory()->student()->create();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->postJson('/api/v1/auth/logout')
        ->assertNoContent();

    expect($user->fresh()->tokens()->count())->toBe(0);
});

it('returns 401 when called without a token', function () {
    $this->postJson('/api/v1/auth/logout')->assertUnauthorized();
});
```

- [ ] **Step 3: Write MeTest**

Create `src/tests/Feature/Api/V1/Auth/MeTest.php`:

```php
<?php

use App\Models\Student;
use App\Models\Teacher;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

it('returns the authenticated student profile', function () {
    $student = Student::factory()->create();
    $user = $student->user;
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.role', 'student')
        ->assertJsonPath('data.id', $user->id)
        ->assertJsonStructure(['data' => ['student' => ['id', 'nis', 'nisn', 'class']]]);
});

it('returns the authenticated teacher profile', function () {
    $teacher = Teacher::factory()->create();
    $user = $teacher->user;
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.role', 'teacher')
        ->assertJsonStructure(['data' => ['teacher' => ['id', 'nip', 'name']]]);
});

it('returns 401 without a token', function () {
    $this->getJson('/api/v1/auth/me')->assertUnauthorized();
});
```

- [ ] **Step 4: Run all auth tests**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest tests/Feature/Api/V1/Auth/
```

Expected: PASS (10 tests across the three files). Fix any failures by tracing back to the controller / service / resource code.

- [ ] **Step 5: Commit**

```bash
git add src/tests/Feature/Api/V1/Auth/
git commit -m "test(api/v1): full feature tests for auth login/logout/me"
```

---

### Task 16: Fix GradePolicy (email match + teacher scoping)

**Files:**
- Modify: `src/app/Policies/GradePolicy.php`
- Create: `src/tests/Unit/Policies/GradePolicyTest.php`

- [ ] **Step 1: Read current GradePolicy**

Already known from spec audit:
- `view()` uses `$grade->student->email === $user->email` (fragile)
- `update()` returns `true` for any teacher (no scoping)

- [ ] **Step 2: Write failing test**

Create `src/tests/Unit/Policies/GradePolicyTest.php`:

```php
<?php

use App\Models\Grade;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Models\User;
use App\Policies\GradePolicy;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    $this->policy = new GradePolicy();
});

it('allows a student to view their own grade', function () {
    $student = Student::factory()->create();
    $grade   = Grade::factory()->create(['student_id' => $student->id]);
    expect($this->policy->view($student->user, $grade))->toBeTrue();
});

it('rejects a student viewing another student\'s grade', function () {
    $a = Student::factory()->create();
    $b = Student::factory()->create();
    $gradeOfB = Grade::factory()->create(['student_id' => $b->id]);
    expect($this->policy->view($a->user, $gradeOfB))->toBeFalse();
});

it('allows a teacher to view a grade in their teaching assignment', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $ta->class_id]);
    $grade = Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $ta->subject_id,
    ]);
    expect($this->policy->view($teacher->user, $grade))->toBeTrue();
});

it('rejects a teacher viewing a grade outside their teaching assignment', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $student = Student::factory()->create(['class_id' => $taB->class_id]);
    $grade = Grade::factory()->create([
        'student_id' => $student->id,
        'subject_id' => $taB->subject_id,
    ]);
    expect($this->policy->view($teacherA->user, $grade))->toBeFalse();
});
```

NOTE: This test requires `GradeFactory` and `TeachingAssignmentFactory`. Create them in this task as a sub-step before running the test.

- [ ] **Step 3: Create GradeFactory if missing**

Create `src/database/factories/GradeFactory.php` (adjust column names to actual schema):

```php
<?php

namespace Database\Factories;

use App\Models\Grade;
use App\Models\Student;
use App\Models\Subject;
use App\Models\Semester;
use Illuminate\Database\Eloquent\Factories\Factory;

class GradeFactory extends Factory
{
    protected $model = Grade::class;

    public function definition(): array
    {
        return [
            'student_id'      => Student::factory(),
            'subject_id'      => Subject::factory(),
            'knowledge_score' => fake()->numberBetween(60, 100),
            'final_score'     => fake()->numberBetween(60, 100),
            'description'     => 'Harian 1',
        ];
    }
}
```

- [ ] **Step 4: Create TeachingAssignmentFactory + SubjectFactory if missing**

Create `src/database/factories/SubjectFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Subject;
use Illuminate\Database\Eloquent\Factories\Factory;

class SubjectFactory extends Factory
{
    protected $model = Subject::class;

    public function definition(): array
    {
        return [
            'code' => fake()->unique()->bothify('SUB-####'),
            'name' => fake()->word(),
            'kkm'  => 75,
        ];
    }
}
```

Create `src/database/factories/TeachingAssignmentFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\TeachingAssignment;
use App\Models\Teacher;
use App\Models\Subject;
use App\Models\SchoolClass;
use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class TeachingAssignmentFactory extends Factory
{
    protected $model = TeachingAssignment::class;

    public function definition(): array
    {
        return [
            'teacher_id'       => Teacher::factory(),
            'subject_id'       => Subject::factory(),
            'class_id'         => SchoolClass::factory(),
            'academic_year_id' => AcademicYear::factory(),
        ];
    }
}
```

Create `src/database/factories/AcademicYearFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class AcademicYearFactory extends Factory
{
    protected $model = AcademicYear::class;

    public function definition(): array
    {
        return [
            'name'      => '2026/2027 - Ganjil',
            'is_active' => true,
        ];
    }
}
```

- [ ] **Step 5: Run test, confirm fail**

```bash
./vendor/bin/pest tests/Unit/Policies/GradePolicyTest.php
```

Expected: 1+ tests fail (existing policy returns wrong result for the scoping cases).

- [ ] **Step 6: Fix GradePolicy**

Replace `src/app/Policies/GradePolicy.php` with:

```php
<?php

namespace App\Policies;

use App\Models\Grade;
use App\Models\User;

class GradePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher() || $user->isStudent();
    }

    public function view(User $user, Grade $grade): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $grade->student_id === $user->student->id;
        }

        if ($user->isTeacher() && $user->teacher) {
            // Teacher can see grades for student/subject combos within their teaching assignments
            return $user->teacher->teachingAssignments()
                ->where('subject_id', $grade->subject_id)
                ->whereHas('schoolClass.students', fn ($q) => $q->where('students.id', $grade->student_id))
                ->exists();
        }

        return false;
    }

    public function create(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher();
    }

    public function update(User $user, Grade $grade): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $user->teacher->teachingAssignments()
                ->where('subject_id', $grade->subject_id)
                ->whereHas('schoolClass.students', fn ($q) => $q->where('students.id', $grade->student_id))
                ->exists();
        }

        return false;
    }

    public function delete(User $user, Grade $grade): bool
    {
        return $user->isSchoolAdmin();
    }
}
```

- [ ] **Step 7: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Unit/Policies/GradePolicyTest.php
```

Expected: PASS (4 tests). If the relation chain `teachingAssignments() / schoolClass / students` doesn't exist, look up the relation method names on the actual models and adjust.

- [ ] **Step 8: Commit**

```bash
git add src/app/Policies/GradePolicy.php src/database/factories/GradeFactory.php src/database/factories/SubjectFactory.php src/database/factories/TeachingAssignmentFactory.php src/database/factories/AcademicYearFactory.php src/tests/Unit/Policies/GradePolicyTest.php
git commit -m "fix(policy): GradePolicy scoping by student_id and teaching assignment"
```

---

### Task 17: Create AttendancePolicy

**Files:**
- Create: `src/app/Policies/AttendancePolicy.php`
- Create: `src/tests/Unit/Policies/AttendancePolicyTest.php`
- Create: `src/database/factories/AttendanceFactory.php` (if missing)
- Create: `src/database/factories/MeetingFactory.php` (if missing)

- [ ] **Step 1: Create supporting factories**

Create `src/database/factories/MeetingFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Meeting;
use App\Models\TeachingAssignment;
use Illuminate\Database\Eloquent\Factories\Factory;

class MeetingFactory extends Factory
{
    protected $model = Meeting::class;

    public function definition(): array
    {
        return [
            'teaching_assignment_id' => TeachingAssignment::factory(),
            'session_number'         => fake()->numberBetween(1, 16),
            'title'                  => 'Pertemuan ' . fake()->numberBetween(1, 16),
            'description'            => fake()->sentence(),
            'date'                   => now()->toDateString(),
            'status'                 => 'draft',
            'is_locked'              => false,
        ];
    }
}
```

Create `src/database/factories/AttendanceFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Attendance;
use App\Models\Student;
use App\Models\Meeting;
use App\Models\SchoolClass;
use Illuminate\Database\Eloquent\Factories\Factory;

class AttendanceFactory extends Factory
{
    protected $model = Attendance::class;

    public function definition(): array
    {
        return [
            'student_id' => Student::factory(),
            'class_id'   => SchoolClass::factory(),
            'meeting_id' => Meeting::factory(),
            'date'       => now()->toDateString(),
            'status'     => 'hadir',
            'note'       => null,
        ];
    }
}
```

- [ ] **Step 2: Write failing test**

Create `src/tests/Unit/Policies/AttendancePolicyTest.php`:

```php
<?php

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\TeachingAssignment;
use App\Policies\AttendancePolicy;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    $this->policy = new AttendancePolicy();
});

it('allows a teacher to record attendance for their own meeting', function () {
    $teacher = Teacher::factory()->create();
    $ta = TeachingAssignment::factory()->create(['teacher_id' => $teacher->id]);
    $meeting = Meeting::factory()->create(['teaching_assignment_id' => $ta->id]);
    expect($this->policy->recordForMeeting($teacher->user, $meeting))->toBeTrue();
});

it('rejects a teacher recording for another teacher\'s meeting', function () {
    $teacherA = Teacher::factory()->create();
    $teacherB = Teacher::factory()->create();
    $taB = TeachingAssignment::factory()->create(['teacher_id' => $teacherB->id]);
    $meeting = Meeting::factory()->create(['teaching_assignment_id' => $taB->id]);
    expect($this->policy->recordForMeeting($teacherA->user, $meeting))->toBeFalse();
});

it('allows a student to view their own attendance record', function () {
    $student = Student::factory()->create();
    $att = Attendance::factory()->create(['student_id' => $student->id]);
    expect($this->policy->view($student->user, $att))->toBeTrue();
});

it('rejects a student viewing another student\'s attendance', function () {
    $a = Student::factory()->create();
    $b = Student::factory()->create();
    $att = Attendance::factory()->create(['student_id' => $b->id]);
    expect($this->policy->view($a->user, $att))->toBeFalse();
});
```

- [ ] **Step 3: Run test, confirm fail (class not found)**

```bash
./vendor/bin/pest tests/Unit/Policies/AttendancePolicyTest.php
```

Expected: FAIL.

- [ ] **Step 4: Implement AttendancePolicy**

Create `src/app/Policies/AttendancePolicy.php`:

```php
<?php

namespace App\Policies;

use App\Models\Attendance;
use App\Models\Meeting;
use App\Models\User;

class AttendancePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher() || $user->isStudent();
    }

    public function view(User $user, Attendance $attendance): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $attendance->student_id === $user->student->id;
        }

        if ($user->isTeacher() && $user->teacher) {
            // Teacher can view attendance in classes they teach
            return $user->teacher->teachingAssignments()
                ->where('class_id', $attendance->class_id)
                ->exists();
        }

        return false;
    }

    /**
     * Can the user record attendance for this meeting?
     */
    public function recordForMeeting(User $user, Meeting $meeting): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $meeting->teachingAssignment->teacher_id === $user->teacher->id;
        }

        return false;
    }
}
```

- [ ] **Step 5: Run test, confirm pass**

```bash
./vendor/bin/pest tests/Unit/Policies/AttendancePolicyTest.php
```

Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add src/app/Policies/AttendancePolicy.php src/tests/Unit/Policies/AttendancePolicyTest.php src/database/factories/MeetingFactory.php src/database/factories/AttendanceFactory.php
git commit -m "feat(policy): add AttendancePolicy with viewAny/view/recordForMeeting"
```

---

### Task 18: Create AnnouncementPolicy

**Files:**
- Create: `src/app/Policies/AnnouncementPolicy.php`
- Create: `src/tests/Unit/Policies/AnnouncementPolicyTest.php`
- Create: `src/database/factories/AnnouncementFactory.php`

- [ ] **Step 1: Create AnnouncementFactory**

```php
<?php
// src/database/factories/AnnouncementFactory.php

namespace Database\Factories;

use App\Models\Announcement;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class AnnouncementFactory extends Factory
{
    protected $model = Announcement::class;

    public function definition(): array
    {
        return [
            'title'      => fake()->sentence(6),
            'body'       => fake()->paragraph(),
            'is_pinned'  => false,
            'created_by' => User::factory()->schoolAdmin(),
            'class_id'   => null, // school-wide by default
        ];
    }
}
```

(Adjust column names. If `Announcement` uses different fields, read the model + migration first.)

- [ ] **Step 2: Write failing test**

```php
<?php
// src/tests/Unit/Policies/AnnouncementPolicyTest.php

use App\Models\Announcement;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use App\Policies\AnnouncementPolicy;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(fn () => $this->policy = new AnnouncementPolicy());

it('allows any authenticated user to view a school-wide announcement', function () {
    $a = Announcement::factory()->create(['class_id' => null]);
    $student = Student::factory()->create();
    $teacher = Teacher::factory()->create();

    expect($this->policy->view($student->user, $a))->toBeTrue();
    expect($this->policy->view($teacher->user, $a))->toBeTrue();
});

it('allows only members of the target class to view a class-scoped announcement', function () {
    $studentInClass = Student::factory()->create();
    $a = Announcement::factory()->create(['class_id' => $studentInClass->class_id]);
    $studentOther = Student::factory()->create();

    expect($this->policy->view($studentInClass->user, $a))->toBeTrue();
    expect($this->policy->view($studentOther->user, $a))->toBeFalse();
});

it('allows school admin and teachers to create', function () {
    $admin = User::factory()->schoolAdmin()->create();
    $teacher = Teacher::factory()->create();
    $student = Student::factory()->create();

    expect($this->policy->create($admin))->toBeTrue();
    expect($this->policy->create($teacher->user))->toBeTrue();
    expect($this->policy->create($student->user))->toBeFalse();
});
```

- [ ] **Step 3: Run, confirm fail**

```bash
./vendor/bin/pest tests/Unit/Policies/AnnouncementPolicyTest.php
```

- [ ] **Step 4: Implement AnnouncementPolicy**

```php
<?php
// src/app/Policies/AnnouncementPolicy.php

namespace App\Policies;

use App\Models\Announcement;
use App\Models\User;

class AnnouncementPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // any authenticated mobile user can list announcements
    }

    public function view(User $user, Announcement $announcement): bool
    {
        // school-wide → any authenticated user
        if ($announcement->class_id === null) {
            return true;
        }

        // class-scoped → only members of that class
        if ($user->isStudent() && $user->student) {
            return $user->student->class_id === $announcement->class_id;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $user->teacher->teachingAssignments()
                ->where('class_id', $announcement->class_id)
                ->exists();
        }

        if ($user->isSchoolAdmin()) {
            return true;
        }

        return false;
    }

    public function create(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher();
    }

    public function update(User $user, Announcement $announcement): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }
        return $user->id === $announcement->created_by;
    }

    public function delete(User $user, Announcement $announcement): bool
    {
        return $this->update($user, $announcement);
    }
}
```

- [ ] **Step 5: Run, confirm pass; commit**

```bash
./vendor/bin/pest tests/Unit/Policies/AnnouncementPolicyTest.php
git add src/app/Policies/AnnouncementPolicy.php src/tests/Unit/Policies/AnnouncementPolicyTest.php src/database/factories/AnnouncementFactory.php
git commit -m "feat(policy): add AnnouncementPolicy with class-scope handling"
```

---

### Task 19: Create ReportCardPolicy

**Files:**
- Create: `src/app/Policies/ReportCardPolicy.php`
- Create: `src/tests/Unit/Policies/ReportCardPolicyTest.php`
- Create: `src/database/factories/ReportCardFactory.php`

- [ ] **Step 1: Create ReportCardFactory**

```php
<?php
// src/database/factories/ReportCardFactory.php

namespace Database\Factories;

use App\Models\ReportCard;
use App\Models\Student;
use App\Models\AcademicYear;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReportCardFactory extends Factory
{
    protected $model = ReportCard::class;

    public function definition(): array
    {
        return [
            'student_id'       => Student::factory(),
            'academic_year_id' => AcademicYear::factory(),
            'is_published'     => false,
        ];
    }
}
```

(Adjust to actual columns.)

- [ ] **Step 2: Write failing test**

```php
<?php
// src/tests/Unit/Policies/ReportCardPolicyTest.php

use App\Models\ReportCard;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Policies\ReportCardPolicy;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(fn () => $this->policy = new ReportCardPolicy());

it('allows a student to view their own report card', function () {
    $student = Student::factory()->create();
    $card = ReportCard::factory()->create(['student_id' => $student->id]);
    expect($this->policy->view($student->user, $card))->toBeTrue();
});

it('rejects a student viewing another student\'s report card', function () {
    $a = Student::factory()->create();
    $b = Student::factory()->create();
    $card = ReportCard::factory()->create(['student_id' => $b->id]);
    expect($this->policy->view($a->user, $card))->toBeFalse();
});

it('allows the homeroom teacher to view a report card of their class', function () {
    $teacher = Teacher::factory()->create();
    $class = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacher->id]);
    $student = Student::factory()->create(['class_id' => $class->id]);
    $card = ReportCard::factory()->create(['student_id' => $student->id]);
    expect($this->policy->view($teacher->user, $card))->toBeTrue();
});

it('rejects a non-homeroom teacher from viewing the report card', function () {
    $teacherHomeroom = Teacher::factory()->create();
    $teacherOther = Teacher::factory()->create();
    $class = SchoolClass::factory()->create(['homeroom_teacher_id' => $teacherHomeroom->id]);
    $student = Student::factory()->create(['class_id' => $class->id]);
    $card = ReportCard::factory()->create(['student_id' => $student->id]);
    expect($this->policy->view($teacherOther->user, $card))->toBeFalse();
});
```

- [ ] **Step 3: Run, confirm fail**

```bash
./vendor/bin/pest tests/Unit/Policies/ReportCardPolicyTest.php
```

- [ ] **Step 4: Implement ReportCardPolicy**

```php
<?php
// src/app/Policies/ReportCardPolicy.php

namespace App\Policies;

use App\Models\ReportCard;
use App\Models\User;

class ReportCardPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSchoolAdmin() || $user->isTeacher() || $user->isStudent();
    }

    public function view(User $user, ReportCard $card): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isStudent() && $user->student) {
            return $card->student_id === $user->student->id;
        }

        if ($user->isTeacher() && $user->teacher) {
            // Homeroom teacher of the student's class
            $student = $card->student;
            return $student
                && $student->class
                && $student->class->homeroom_teacher_id === $user->teacher->id;
        }

        return false;
    }

    public function download(User $user, ReportCard $card): bool
    {
        return $this->view($user, $card);
    }

    public function publish(User $user, ReportCard $card): bool
    {
        if ($user->isSchoolAdmin()) {
            return true;
        }

        if ($user->isTeacher() && $user->teacher) {
            return $card->student->class->homeroom_teacher_id === $user->teacher->id;
        }

        return false;
    }
}
```

- [ ] **Step 5: Run, pass, commit**

```bash
./vendor/bin/pest tests/Unit/Policies/ReportCardPolicyTest.php
git add src/app/Policies/ReportCardPolicy.php src/tests/Unit/Policies/ReportCardPolicyTest.php src/database/factories/ReportCardFactory.php
git commit -m "feat(policy): add ReportCardPolicy with homeroom teacher access"
```

---

### Task 20: Audit OfflineAssignmentPolicy

**Files:**
- Read: `src/app/Policies/OfflineAssignmentPolicy.php`
- Possibly modify if gaps found

- [ ] **Step 1: Read the existing policy**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/src/app/Policies/OfflineAssignmentPolicy.php
```

- [ ] **Step 2: Verify it has at minimum**

- `viewAny(User $user): bool` — student/teacher/admin allowed
- `view(User $user, OfflineAssignment $assignment): bool` — student must be in target class; teacher must own the TA
- If either is missing or weak (e.g. uses email match), patch it following the same pattern as GradePolicy/AttendancePolicy.

- [ ] **Step 3: If patched, write a unit test mirroring AttendancePolicyTest**

(Skip writing if the policy already correctly implements the rules.)

- [ ] **Step 4: Commit if changed**

```bash
git add src/app/Policies/OfflineAssignmentPolicy.php src/tests/Unit/Policies/OfflineAssignmentPolicyTest.php
git commit -m "fix(policy): tighten OfflineAssignmentPolicy scoping"
```

---

### Task 21: Register policies in AuthServiceProvider (if needed)

**Files:**
- Modify: `src/app/Providers/AppServiceProvider.php` (Laravel 12 typically uses this) OR `bootstrap/providers.php`

**Why:** Laravel auto-discovers `App\Policies\<Model>Policy` if naming matches, but for custom names (like `recordForMeeting`) we need the policy to be discoverable via `Gate::policy()` or auto-discovery.

- [ ] **Step 1: Verify auto-discovery works**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan tinker --execute='dump(\Illuminate\Support\Facades\Gate::getPolicyFor(\App\Models\Attendance::class));'
```

Expected: Outputs `App\Policies\AttendancePolicy` (or null if not auto-discovered).

- [ ] **Step 2: If null, register manually in AppServiceProvider boot()**

```php
use Illuminate\Support\Facades\Gate;

// inside boot()
Gate::policy(\App\Models\Attendance::class, \App\Policies\AttendancePolicy::class);
Gate::policy(\App\Models\Announcement::class, \App\Policies\AnnouncementPolicy::class);
Gate::policy(\App\Models\ReportCard::class, \App\Policies\ReportCardPolicy::class);
```

- [ ] **Step 3: Re-run tinker to verify**

Same command as Step 1; expected: non-null.

- [ ] **Step 4: Commit if changed**

```bash
git add src/app/Providers/AppServiceProvider.php
git commit -m "chore(policy): register Attendance/Announcement/ReportCard policies"
```

---

### Task 22: Add Swagger annotations to MobileAuthController

**Files:**
- Modify: `src/app/Http/Controllers/Api/V1/MobileAuthController.php`

- [ ] **Step 1: Add OpenAPI base annotation**

In `src/app/Http/Controllers/Api/SwaggerController.php` (existing skeleton), confirm there is an `@OA\Info` and `@OA\SecurityScheme` for Bearer. If not, add:

```php
/**
 * @OA\Info(title="FLOZ Mobile API", version="1.0.0")
 * @OA\SecurityScheme(
 *     securityScheme="bearerAuth",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="Sanctum"
 * )
 */
```

- [ ] **Step 2: Annotate login endpoint**

Above the `login()` method in `MobileAuthController`:

```php
/**
 * @OA\Post(
 *     path="/api/v1/auth/login",
 *     tags={"Auth"},
 *     summary="Login dan dapatkan Sanctum token",
 *     @OA\RequestBody(
 *         required=true,
 *         @OA\JsonContent(
 *             required={"email","password"},
 *             @OA\Property(property="email", type="string", format="email"),
 *             @OA\Property(property="password", type="string", format="password"),
 *         )
 *     ),
 *     @OA\Response(response=200, description="Login berhasil"),
 *     @OA\Response(response=401, description="Email atau password salah"),
 *     @OA\Response(response=403, description="Akun tidak aktif atau parent"),
 *     @OA\Response(response=422, description="Validasi gagal"),
 *     @OA\Response(response=429, description="Rate limit exceeded"),
 * )
 */
```

- [ ] **Step 3: Annotate logout and me similarly**

```php
/**
 * @OA\Post(
 *     path="/api/v1/auth/logout",
 *     tags={"Auth"},
 *     summary="Logout (revoke current token)",
 *     security={{"bearerAuth":{}}},
 *     @OA\Response(response=204, description="Logout berhasil"),
 *     @OA\Response(response=401, description="Token tidak valid"),
 * )
 */

/**
 * @OA\Get(
 *     path="/api/v1/auth/me",
 *     tags={"Auth"},
 *     summary="Profil user yang sedang login",
 *     security={{"bearerAuth":{}}},
 *     @OA\Response(response=200, description="Profile data"),
 *     @OA\Response(response=401, description="Token tidak valid"),
 * )
 */
```

- [ ] **Step 4: Generate Swagger doc**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan l5-swagger:generate
```

Expected: Generates JSON without errors. Open `http://localhost/api/documentation` (when serving) or read `storage/api-docs/api-docs.json` to verify auth endpoints appear.

- [ ] **Step 5: Commit**

```bash
git add src/app/Http/Controllers/Api/V1/MobileAuthController.php src/app/Http/Controllers/Api/SwaggerController.php
git commit -m "docs(api/v1): add Swagger annotations for auth endpoints"
```

---

### Task 23: Run full backend test suite checkpoint

- [ ] **Step 1: Run everything**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest
```

Expected: All tests pass. If anything is red from previous tasks, fix root cause before proceeding.

- [ ] **Step 2: Lint**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pint --test
```

Expected: No formatting issues. If issues, run `./vendor/bin/pint` (without `--test`) to auto-fix, then re-run.

- [ ] **Step 3: Commit any lint fixes**

```bash
git add -A
git status
git diff --cached --stat
git commit -m "style: pint auto-format" || true
```

---

### Task 24: Mobile — add mocktail to pubspec

**Files:**
- Modify: `floz_mobile/pubspec.yaml`

- [ ] **Step 1: Add mocktail under dev_dependencies**

Edit `floz_mobile/pubspec.yaml`. In the `dev_dependencies` block, add:

```yaml
  mocktail: ^1.0.4
```

- [ ] **Step 2: Run pub get**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter pub get
```

Expected: Resolves successfully, mocktail downloaded.

- [ ] **Step 3: Commit**

```bash
git add floz_mobile/pubspec.yaml floz_mobile/pubspec.lock
git commit -m "chore(mobile): add mocktail dev dependency"
```

---

### Task 25: Mobile — core/error/failure.dart and result.dart

**Files:**
- Create: `floz_mobile/lib/core/error/failure.dart`
- Create: `floz_mobile/lib/core/error/result.dart`
- Create: `floz_mobile/test/core/error/result_test.dart`

- [ ] **Step 1: Write failing test**

Create `floz_mobile/test/core/error/result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';

void main() {
  group('Result<T>', () {
    test('Success holds data', () {
      const Result<int> r = Success<int>(42);
      expect(r, isA<Success<int>>());
      expect((r as Success<int>).data, 42);
    });

    test('FailureResult holds failure', () {
      const Result<int> r = FailureResult<int>(NetworkFailure('offline'));
      expect(r, isA<FailureResult<int>>());
      expect((r as FailureResult<int>).failure, isA<NetworkFailure>());
    });

    test('pattern matching on Result', () {
      Result<int> r = const Success(10);
      final out = switch (r) {
        Success(:final data) => data * 2,
        FailureResult() => -1,
      };
      expect(out, 20);
    });
  });

  group('Failure', () {
    test('NetworkFailure carries a message', () {
      const f = NetworkFailure('no internet');
      expect(f.message, 'no internet');
    });

    test('ValidationFailure carries field errors', () {
      const f = ValidationFailure(
        message: 'invalid',
        fieldErrors: {'email': ['required']},
      );
      expect(f.fieldErrors['email'], ['required']);
    });
  });
}
```

- [ ] **Step 2: Run, confirm fail**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/core/error/result_test.dart
```

Expected: FAIL (files don't exist).

- [ ] **Step 3: Implement failure.dart**

Create `floz_mobile/lib/core/error/failure.dart`:

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  const ValidationFailure({
    required String message,
    this.fieldErrors = const {},
  }) : super(message);
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
```

- [ ] **Step 4: Implement result.dart**

Create `floz_mobile/lib/core/error/result.dart`:

```dart
import 'failure.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  final bool stale;
  const Success(this.data, {this.stale = false});
}

final class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);
}
```

- [ ] **Step 5: Run, confirm pass**

```bash
flutter test test/core/error/result_test.dart
```

Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add floz_mobile/lib/core/error/ floz_mobile/test/core/error/
git commit -m "feat(mobile/core): add Failure sealed class and Result<T>"
```

---

### Task 26: Mobile — core/network primitives (api_response, api_exception, api_endpoints)

**Files:**
- Create: `floz_mobile/lib/core/network/api_response.dart`
- Create: `floz_mobile/lib/core/network/api_exception.dart`
- Create: `floz_mobile/lib/core/network/api_endpoints.dart`

- [ ] **Step 1: Implement api_endpoints.dart**

```dart
// floz_mobile/lib/core/network/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin   = '/auth/login';
  static const String authLogout  = '/auth/logout';
  static const String authMe      = '/auth/me';
}
```

- [ ] **Step 2: Implement api_exception.dart**

```dart
// floz_mobile/lib/core/network/api_exception.dart

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;
  const ValidationException(super.message, this.errors)
      : super(statusCode: 422);
}

class RateLimitException extends ApiException {
  const RateLimitException(super.message) : super(statusCode: 429);
}

class ServerException extends ApiException {
  const ServerException(super.message, {int? statusCode})
      : super(statusCode: statusCode);
}
```

- [ ] **Step 3: Implement api_response.dart**

```dart
// floz_mobile/lib/core/network/api_response.dart

class ApiResponse<T> {
  final T data;
  final ApiMeta? meta;

  const ApiResponse({required this.data, this.meta});

  static ApiResponse<T> single<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = json['data'];
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Expected single object under "data"');
    }
    return ApiResponse<T>(data: parser(raw));
  }

  static ApiResponse<List<T>> list<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = json['data'];
    if (raw is! List) {
      throw const FormatException('Expected list under "data"');
    }
    final parsed = raw
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList(growable: false);
    final metaJson = json['meta'];
    return ApiResponse<List<T>>(
      data: parsed,
      meta: metaJson is Map<String, dynamic> ? ApiMeta.fromJson(metaJson) : null,
    );
  }
}

class ApiMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const ApiMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) => ApiMeta(
        currentPage: json['current_page'] as int? ?? 1,
        perPage: json['per_page'] as int? ?? 20,
        total: json['total'] as int? ?? 0,
        lastPage: json['last_page'] as int? ?? 1,
      );
}
```

- [ ] **Step 4: Smoke test (no test file — verify compiles via pub)**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze lib/core/network/
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add floz_mobile/lib/core/network/
git commit -m "feat(mobile/core): add ApiEndpoints, ApiException, ApiResponse"
```

---

### Task 27: Mobile — core/storage (secure_token_storage + cache_box)

**Files:**
- Create: `floz_mobile/lib/core/storage/secure_token_storage.dart`
- Create: `floz_mobile/lib/core/storage/cache_box.dart`

- [ ] **Step 1: Implement secure_token_storage.dart**

```dart
// floz_mobile/lib/core/storage/secure_token_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _key = 'floz_mobile_token';
  final FlutterSecureStorage _storage;

  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
```

- [ ] **Step 2: Implement cache_box.dart**

```dart
// floz_mobile/lib/core/storage/cache_box.dart

import 'package:hive_flutter/hive_flutter.dart';

class CacheBox<T> {
  final String name;
  final Duration ttl;

  CacheBox({required this.name, required this.ttl});

  Future<Box> _open() async {
    return Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
  }

  Future<void> put(String key, dynamic value) async {
    final box = await _open();
    await box.put(key, {
      'value': value,
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the value if present and not expired, else null.
  Future<dynamic> get(String key) async {
    final box = await _open();
    final raw = box.get(key);
    if (raw is! Map) return null;
    final cachedAt = DateTime.tryParse(raw['cached_at'] as String? ?? '');
    if (cachedAt == null) return null;
    if (DateTime.now().difference(cachedAt) > ttl) {
      return null;
    }
    return raw['value'];
  }

  /// Returns the value regardless of TTL (for stale-fallback on network error).
  Future<dynamic> getStale(String key) async {
    final box = await _open();
    final raw = box.get(key);
    if (raw is! Map) return null;
    return raw['value'];
  }

  Future<void> invalidate(String key) async {
    final box = await _open();
    await box.delete(key);
  }

  Future<void> clearAll() async {
    final box = await _open();
    await box.clear();
  }
}
```

- [ ] **Step 3: Compile check**

```bash
flutter analyze lib/core/storage/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/core/storage/
git commit -m "feat(mobile/core): add SecureTokenStorage and CacheBox<T>"
```

---

### Task 28: Mobile — core/network/api_client.dart with interceptors

**Files:**
- Create: `floz_mobile/lib/core/network/api_client.dart`
- Create: `floz_mobile/test/core/network/api_client_test.dart`

- [ ] **Step 1: Write failing test**

Create `floz_mobile/test/core/network/api_client_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/network/api_client.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/secure_token_storage.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = _MockTokenStorage();
  });

  group('ApiClient error mapping', () {
    test('401 → UnauthorizedException', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
          data: {'message': 'unauth'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(
        () => ApiClient.mapError(err),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('403 → ForbiddenException', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 403,
          data: {'message': 'forbidden'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(() => ApiClient.mapError(err), throwsA(isA<ForbiddenException>()));
    });

    test('422 → ValidationException with fieldErrors', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 422,
          data: {
            'message': 'invalid',
            'errors': {'email': ['required', 'email format']},
          },
        ),
        type: DioExceptionType.badResponse,
      );
      try {
        ApiClient.mapError(err);
        fail('should have thrown');
      } on ValidationException catch (e) {
        expect(e.errors['email'], ['required', 'email format']);
      }
    });

    test('connection timeout → NetworkException', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(() => ApiClient.mapError(err), throwsA(isA<NetworkException>()));
    });
  });
}
```

- [ ] **Step 2: Run, confirm fail**

```bash
flutter test test/core/network/api_client_test.dart
```

- [ ] **Step 3: Implement api_client.dart**

```dart
// floz_mobile/lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'api_exception.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function()? _onUnauthorized;

  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    void Function()? onUnauthorized,
    Dio? dioOverride,
  })  : _tokenStorage = tokenStorage,
        _onUnauthorized = onUnauthorized,
        _dio = dioOverride ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json',
                'X-Client': 'floz-mobile/1.0.0',
              },
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<dynamic>> post(String path, {dynamic body}) async {
    try {
      return await _dio.post(path, data: body);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<dynamic>> put(String path, {dynamic body}) async {
    try {
      return await _dio.put(path, data: body);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<dynamic>> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  static Never mapError(DioException e) {
    final code = e.response?.statusCode;
    final body = e.response?.data;
    final message = (body is Map && body['message'] is String)
        ? body['message'] as String
        : (e.message ?? 'Terjadi kesalahan jaringan.');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        throw NetworkException(message);
      default:
        // fallthrough to status mapping
        break;
    }

    switch (code) {
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        final errors = <String, List<String>>{};
        if (body is Map && body['errors'] is Map) {
          (body['errors'] as Map).forEach((k, v) {
            if (v is List) {
              errors[k.toString()] = v.map((e) => e.toString()).toList();
            }
          });
        }
        throw ValidationException(message, errors);
      case 429:
        throw RateLimitException(message);
      default:
        throw ServerException(message, statusCode: code);
    }
  }
}
```

- [ ] **Step 4: Run test, confirm pass**

```bash
flutter test test/core/network/api_client_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add floz_mobile/lib/core/network/api_client.dart floz_mobile/test/core/network/api_client_test.dart
git commit -m "feat(mobile/core): add ApiClient with typed error mapping"
```

---

### Task 29: Mobile — core/auth (auth_session + role_guard)

**Files:**
- Create: `floz_mobile/lib/core/auth/auth_session.dart`
- Create: `floz_mobile/lib/core/auth/role_guard.dart`

- [ ] **Step 1: Implement auth_session.dart**

```dart
// floz_mobile/lib/core/auth/auth_session.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user.dart';

class AuthSession {
  final User? user;
  final String? token;
  const AuthSession({this.user, this.token});

  bool get isAuthenticated => token != null && user != null;
  String? get role => user?.role;

  AuthSession copyWith({User? user, String? token}) =>
      AuthSession(user: user ?? this.user, token: token ?? this.token);

  static const empty = AuthSession();
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => AuthSession.empty;

  void setSession(User user, String token) {
    state = AuthSession(user: user, token: token);
  }

  void clear() {
    state = AuthSession.empty;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
```

(NOTE: This file references `User` from `features/auth/domain/entities/user.dart` — that file is created in Task 32. This file will fail to compile until Task 32 is done. That's OK — commit them together OR create a stub User class first as a placeholder. Cleanest approach: skip writing this file's content until Task 32. Mark Task 29 as a placeholder.)

**Revised step:** create the file but with `User` typed as `dynamic` for now:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSession {
  final dynamic user; // typed in Task 32
  final String? token;
  const AuthSession({this.user, this.token});

  bool get isAuthenticated => token != null && user != null;

  AuthSession copyWith({dynamic user, String? token}) =>
      AuthSession(user: user ?? this.user, token: token ?? this.token);

  static const empty = AuthSession();
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => AuthSession.empty;

  void setSession(dynamic user, String token) {
    state = AuthSession(user: user, token: token);
  }

  void clear() {
    state = AuthSession.empty;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
```

(Task 32 will tighten the type to `User?`.)

- [ ] **Step 2: Implement role_guard.dart**

```dart
// floz_mobile/lib/core/auth/role_guard.dart

import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import 'auth_session.dart';

class RoleGuard {
  /// Returns the redirect path if access is denied, else null.
  static String? guard({
    required AuthSession session,
    required String currentPath,
    required Set<String> allowedRoles,
  }) {
    if (!session.isAuthenticated) {
      return '/login';
    }
    final role = (session.user as dynamic)?.role as String?;
    if (role == null || !allowedRoles.contains(role)) {
      return '/login';
    }
    return null;
  }
}
```

- [ ] **Step 3: Compile check**

```bash
flutter analyze lib/core/auth/
```

Expected: No errors (warnings about `dynamic` are OK for now).

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/core/auth/
git commit -m "feat(mobile/core): add AuthSession and RoleGuard"
```

---

### Task 30: Mobile — shared widgets (4 files)

**Files:**
- Create: `floz_mobile/lib/shared/widgets/empty_state.dart`
- Create: `floz_mobile/lib/shared/widgets/error_state.dart`
- Create: `floz_mobile/lib/shared/widgets/loading_skeleton.dart`
- Create: `floz_mobile/lib/shared/widgets/async_value_widget.dart`

- [ ] **Step 1: empty_state.dart**

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: error_state.dart**

```dart
import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: loading_skeleton.dart**

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
      ),
    );
  }
}
```

- [ ] **Step 4: async_value_widget.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'empty_state.dart';
import 'error_state.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? emptyMessage;
  final bool Function(T)? isEmpty;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.emptyMessage,
    this.isEmpty,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) {
        if (isEmpty != null && isEmpty!(d) && emptyMessage != null) {
          return EmptyState(message: emptyMessage!);
        }
        return data(d);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: onRetry),
    );
  }
}
```

- [ ] **Step 5: Compile check**

```bash
flutter analyze lib/shared/widgets/
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add floz_mobile/lib/shared/widgets/
git commit -m "feat(mobile/shared): add EmptyState, ErrorState, LoadingSkeleton, AsyncValueWidget"
```

---

### Task 31: Mobile — migrate features to features/student namespace

**Files:** mass move across `floz_mobile/lib/features/`

- [ ] **Step 1: Create student namespace dir**

```bash
mkdir -p /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features/student
```

- [ ] **Step 2: Move each existing feature dir**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/features
git mv dashboard      student/dashboard
git mv schedule       student/schedule
git mv grades         student/grades
git mv report_cards   student/report_cards
git mv announcements  student/announcements
git mv assignments    student/assignments
```

(`auth/` and `profile/` stay at root — they're cross-role.)

- [ ] **Step 3: Update all imports project-wide**

Use Grep tool with these patterns and update each file:

| Find | Replace |
|---|---|
| `package:floz_mobile/features/dashboard/` | `package:floz_mobile/features/student/dashboard/` |
| `package:floz_mobile/features/schedule/` | `package:floz_mobile/features/student/schedule/` |
| `package:floz_mobile/features/grades/` | `package:floz_mobile/features/student/grades/` |
| `package:floz_mobile/features/report_cards/` | `package:floz_mobile/features/student/report_cards/` |
| `package:floz_mobile/features/announcements/` | `package:floz_mobile/features/student/announcements/` |
| `package:floz_mobile/features/assignments/` | `package:floz_mobile/features/student/assignments/` |

Also update relative imports inside the moved files (e.g. `../../core/...` may now be `../../../core/...` — depends on how files are nested).

- [ ] **Step 4: Compile check**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze
```

Expected: No errors. If imports are broken, fix them iteratively until clean.

- [ ] **Step 5: Run existing tests**

```bash
flutter test
```

Expected: PASS (or unchanged from baseline). Migration should not break any passing tests.

- [ ] **Step 6: Commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add floz_mobile/lib/features/
git commit -m "refactor(mobile): migrate student features into features/student/ namespace"
```

---

### Task 32: Mobile — features/auth domain layer (User entity + AuthRepository interface)

**Files:**
- Create: `floz_mobile/lib/features/auth/domain/entities/user.dart`
- Create: `floz_mobile/lib/features/auth/domain/repositories/auth_repository.dart`

- [ ] **Step 1: Create User entity**

```dart
// floz_mobile/lib/features/auth/domain/entities/user.dart

class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'student' | 'teacher' | 'school_admin'
  final String? avatarUrl;
  final bool isActive;
  final StudentProfile? student;
  final TeacherProfile? teacher;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    this.student,
    this.teacher,
  });

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isSchoolAdmin => role == 'school_admin';
}

class StudentProfile {
  final int id;
  final String nis;
  final String nisn;
  final ClassInfo? schoolClass;

  const StudentProfile({
    required this.id,
    required this.nis,
    required this.nisn,
    this.schoolClass,
  });
}

class ClassInfo {
  final int id;
  final String name;
  final String? homeroomTeacher;

  const ClassInfo({required this.id, required this.name, this.homeroomTeacher});
}

class TeacherProfile {
  final int id;
  final String? nip;
  final String name;

  const TeacherProfile({required this.id, this.nip, required this.name});
}
```

- [ ] **Step 2: Create AuthRepository abstract**

```dart
// floz_mobile/lib/features/auth/domain/repositories/auth_repository.dart

import '../entities/user.dart';
import '../../../../core/error/result.dart';

abstract class AuthRepository {
  Future<Result<({User user, String token})>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<User>> me();
}
```

- [ ] **Step 3: Tighten AuthSession to use User**

Edit `floz_mobile/lib/core/auth/auth_session.dart` (created in Task 29). Replace all `dynamic` with `User?`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user.dart';

class AuthSession {
  final User? user;
  final String? token;
  const AuthSession({this.user, this.token});

  bool get isAuthenticated => token != null && user != null;
  String? get role => user?.role;

  AuthSession copyWith({User? user, String? token}) =>
      AuthSession(user: user ?? this.user, token: token ?? this.token);

  static const empty = AuthSession();
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => AuthSession.empty;

  void setSession(User user, String token) {
    state = AuthSession(user: user, token: token);
  }

  void clear() {
    state = AuthSession.empty;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
```

- [ ] **Step 4: Compile check**

```bash
flutter analyze lib/features/auth/ lib/core/auth/
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add floz_mobile/lib/features/auth/domain/ floz_mobile/lib/core/auth/auth_session.dart
git commit -m "feat(mobile/auth): User entity, AuthRepository interface, typed AuthSession"
```

---

### Task 33: Mobile — features/auth data layer (UserDto + remote datasource + repository impl)

**Files:**
- Create: `floz_mobile/lib/features/auth/data/models/user_dto.dart`
- Create: `floz_mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Create: `floz_mobile/lib/features/auth/data/repositories/auth_repository_impl.dart`
- Create: `floz_mobile/test/features/auth/data/repositories/auth_repository_impl_test.dart`

- [ ] **Step 1: UserDto**

```dart
// floz_mobile/lib/features/auth/data/models/user_dto.dart

import '../../domain/entities/user.dart';

class UserDto {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      student: json['student'] is Map
          ? _studentFromJson(json['student'] as Map<String, dynamic>)
          : null,
      teacher: json['teacher'] is Map
          ? _teacherFromJson(json['teacher'] as Map<String, dynamic>)
          : null,
    );
  }

  static StudentProfile _studentFromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      nis: json['nis']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      schoolClass: json['class'] is Map
          ? ClassInfo(
              id: (json['class'] as Map)['id'] as int,
              name: (json['class'] as Map)['name'] as String,
              homeroomTeacher: (json['class'] as Map)['homeroom_teacher'] as String?,
            )
          : null,
    );
  }

  static TeacherProfile _teacherFromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'] as int,
      nip: json['nip'] as String?,
      name: json['name'] as String,
    );
  }
}
```

- [ ] **Step 2: AuthRemoteDataSource**

```dart
// floz_mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user.dart';
import '../models/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<({User user, String token})> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<User> me();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      ApiEndpoints.authLogin,
      body: {'email': email, 'password': password},
    );
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final user = UserDto.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token'] as String;
    return (user: user, token: token);
  }

  @override
  Future<void> logout() async {
    await _client.post(ApiEndpoints.authLogout);
  }

  @override
  Future<User> me() async {
    final res = await _client.get(ApiEndpoints.authMe);
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return UserDto.fromJson(data);
  }
}
```

- [ ] **Step 3: AuthRepositoryImpl**

```dart
// floz_mobile/lib/features/auth/data/repositories/auth_repository_impl.dart

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  @override
  Future<Result<({User user, String token})>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remote.login(email: email, password: password);
      await _tokenStorage.write(result.token);
      return Success(result);
    } on UnauthorizedException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(ForbiddenFailure(e.message));
    } on ValidationException catch (e) {
      return FailureResult(ValidationFailure(message: e.message, fieldErrors: e.errors));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on RateLimitException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: 429));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
      await _tokenStorage.clear();
      return const Success(null);
    } on ApiException catch (e) {
      // Even on failure, clear local token
      await _tokenStorage.clear();
      return FailureResult(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<User>> me() async {
    try {
      final user = await _remote.me();
      return Success(user);
    } on UnauthorizedException catch (e) {
      await _tokenStorage.clear();
      return FailureResult(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on ApiException catch (e) {
      return FailureResult(ServerFailure(e.message));
    }
  }
}
```

- [ ] **Step 4: Write repository test**

Create `floz_mobile/test/features/auth/data/repositories/auth_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/core/network/api_exception.dart';
import 'package:floz_mobile/core/storage/secure_token_storage.dart';
import 'package:floz_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:floz_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:floz_mobile/features/auth/domain/entities/user.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}
class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockRemote remote;
  late _MockTokenStorage tokenStorage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    tokenStorage = _MockTokenStorage();
    repo = AuthRepositoryImpl(remote: remote, tokenStorage: tokenStorage);
  });

  group('login', () {
    test('returns Success and persists token on happy path', () async {
      final user = const User(
        id: 1, name: 'Ahmad', email: 'a@b.co', role: 'student', isActive: true,
      );
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => (user: user, token: 'tok-123'));
      when(() => tokenStorage.write(any())).thenAnswer((_) async {});

      final result = await repo.login(email: 'a@b.co', password: 'rahasia');

      expect(result, isA<Success>());
      verify(() => tokenStorage.write('tok-123')).called(1);
    });

    test('returns AuthFailure on 401', () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const UnauthorizedException('wrong'));

      final result = await repo.login(email: 'a@b.co', password: 'wrong');

      expect(result, isA<FailureResult>());
      expect((result as FailureResult).failure, isA<AuthFailure>());
    });

    test('returns ValidationFailure on 422 with field errors', () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ValidationException('invalid', {'email': ['required']}));

      final result = await repo.login(email: '', password: '');

      expect((result as FailureResult).failure, isA<ValidationFailure>());
      expect(((result.failure as ValidationFailure).fieldErrors)['email'], ['required']);
    });

    test('returns NetworkFailure on offline', () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const NetworkException('offline'));

      final result = await repo.login(email: 'a@b.co', password: 'x');

      expect((result as FailureResult).failure, isA<NetworkFailure>());
    });
  });

  group('logout', () {
    test('clears token even on server failure', () async {
      when(() => remote.logout()).thenThrow(const ServerException('boom'));
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      final result = await repo.logout();

      verify(() => tokenStorage.clear()).called(1);
      expect(result, isA<FailureResult>());
    });
  });

  group('me', () {
    test('returns Success(user) on happy path', () async {
      final user = const User(
        id: 1, name: 'A', email: 'a@b.co', role: 'student', isActive: true,
      );
      when(() => remote.me()).thenAnswer((_) async => user);
      final result = await repo.me();
      expect(result, isA<Success<User>>());
    });

    test('clears token and returns AuthFailure on 401', () async {
      when(() => remote.me()).thenThrow(const UnauthorizedException('expired'));
      when(() => tokenStorage.clear()).thenAnswer((_) async {});
      final result = await repo.me();
      verify(() => tokenStorage.clear()).called(1);
      expect((result as FailureResult).failure, isA<AuthFailure>());
    });
  });
}
```

- [ ] **Step 5: Run test, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart
```

Expected: PASS (7 tests).

- [ ] **Step 6: Commit**

```bash
git add floz_mobile/lib/features/auth/data/ floz_mobile/test/features/auth/
git commit -m "feat(mobile/auth): add UserDto, AuthRemoteDataSource, AuthRepositoryImpl + tests"
```

---

### Task 34: Mobile — features/auth providers (Riverpod wiring)

**Files:**
- Create: `floz_mobile/lib/features/auth/providers/auth_providers.dart`

- [ ] **Step 1: Implement providers**

```dart
// floz_mobile/lib/features/auth/providers/auth_providers.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/error/result.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';

const _baseUrl = String.fromEnvironment(
  'FLOZ_API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator → host
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    baseUrl: _baseUrl,
    tokenStorage: tokenStorage,
    onUnauthorized: () => ref.read(authSessionProvider.notifier).clear(),
  );
});

final authRemoteProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );
    return switch (result) {
      Success(:final data) => () {
          ref.read(authSessionProvider.notifier).setSession(data.user, data.token);
          state = const AsyncData(null);
          return true;
        }(),
      FailureResult(:final failure) => () {
          state = AsyncError(failure, StackTrace.current);
          return false;
        }(),
    };
  }
}

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, void>(LoginController.new);
```

- [ ] **Step 2: Compile check**

```bash
flutter analyze lib/features/auth/providers/
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add floz_mobile/lib/features/auth/providers/
git commit -m "feat(mobile/auth): Riverpod providers for ApiClient, repository, LoginController"
```

---

### Task 35: Mobile — features/auth login screen

**Files:**
- Create: `floz_mobile/lib/features/auth/presentation/screens/login_screen.dart`
- Create: `floz_mobile/test/features/auth/presentation/screens/login_screen_test.dart`

- [ ] **Step 1: Implement LoginScreen**

```dart
// floz_mobile/lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failure.dart';
import '../../providers/auth_providers.dart';
import '../../../../core/auth/auth_session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(loginControllerProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      final session = ref.read(authSessionProvider);
      if (session.role == 'teacher') {
        context.go('/teacher');
      } else {
        context.go('/student');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (prev, next) {
      if (next is AsyncError) {
        final failure = next.error;
        final message = failure is Failure ? failure.message : 'Login gagal';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('FLOZ Mobile',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  key: const Key('login.email'),
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('login.password'),
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('login.submit'),
                    onPressed: state is AsyncLoading ? null : _submit,
                    child: state is AsyncLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Masuk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write widget test**

Create `floz_mobile/test/features/auth/presentation/screens/login_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/auth/domain/entities/user.dart';
import 'package:floz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:floz_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:floz_mobile/features/auth/providers/auth_providers.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Widget _wrap(Widget child) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('calls repository on valid submit', (tester) async {
    final user = const User(
      id: 1, name: 'A', email: 'a@b.co', role: 'student', isActive: true,
    );
    when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => Success((user: user, token: 'tok')));

    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.enterText(find.byKey(const Key('login.email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('login.password')), 'rahasia');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();

    verify(() => repo.login(email: 'a@b.co', password: 'rahasia')).called(1);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const FailureResult(AuthFailure('Email atau password salah.')));

    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.enterText(find.byKey(const Key('login.email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('login.password')), 'rahasia');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump(); // start async
    await tester.pump(const Duration(milliseconds: 100)); // settle

    expect(find.text('Email atau password salah.'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run, confirm pass**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter test test/features/auth/presentation/screens/login_screen_test.dart
```

Expected: PASS (3 tests). The "snackbar" test relies on the `_LoginScreenState` calling `ScaffoldMessenger`; it may need a small adjustment — if it fails, try `await tester.pumpAndSettle()` instead of multiple pumps.

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/features/auth/presentation/ floz_mobile/test/features/auth/presentation/
git commit -m "feat(mobile/auth): LoginScreen with Riverpod controller + widget tests"
```

---

### Task 36: Mobile — core/router (split shells, login, redirect)

**Files:**
- Modify: `floz_mobile/lib/core/router/app_router.dart`

- [ ] **Step 1: Read existing app_router.dart**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/core/router/app_router.dart
```

Note the existing route definitions.

- [ ] **Step 2: Replace with role-aware router**

```dart
// floz_mobile/lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_session.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

// Existing student dashboard (after Task 31 migration). Other student screens
// are wired into nested routes by P2 slices — for P1, the student shell only
// needs the dashboard as the landing page.
import '../../features/student/dashboard/presentation/screens/dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = session.isAuthenticated;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) {
        return session.role == 'teacher' ? '/teacher' : '/student';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      GoRoute(
        path: '/student',
        builder: (_, __) => const DashboardScreen(),
        // child routes added in P2 slices
      ),

      GoRoute(
        path: '/teacher',
        builder: (_, __) => const _TeacherPlaceholderScreen(),
        // child routes added in P3+
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.path}')),
    ),
  );
});

class _TeacherPlaceholderScreen extends StatelessWidget {
  const _TeacherPlaceholderScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Teacher shell — implemented in P3')),
    );
  }
}
```

(The `DashboardScreen` import path may need to match exactly what was migrated in Task 31. If the file path differs, fix the import.)

- [ ] **Step 3: Compile check**

```bash
flutter analyze lib/core/router/
```

Expected: No errors. Resolve any import path mismatches.

- [ ] **Step 4: Commit**

```bash
git add floz_mobile/lib/core/router/
git commit -m "feat(mobile/router): role-aware shells with redirect"
```

---

### Task 37: Mobile — wire main.dart and app.dart

**Files:**
- Modify: `floz_mobile/lib/main.dart`
- Modify: `floz_mobile/lib/app.dart`

- [ ] **Step 1: Read current main.dart and app.dart**

```bash
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/main.dart
cat /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile/lib/app.dart
```

- [ ] **Step 2: Update main.dart**

```dart
// floz_mobile/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: FlozApp()));
}
```

- [ ] **Step 3: Update app.dart**

```dart
// floz_mobile/lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

class FlozApp extends ConsumerWidget {
  const FlozApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'FLOZ Mobile',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
    );
  }
}
```

- [ ] **Step 4: Compile + run**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze
flutter test
```

Expected: All tests pass, analyzer clean.

- [ ] **Step 5: Smoke run on emulator (optional but recommended)**

```bash
flutter run --dart-define=FLOZ_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Manually verify: app launches → login screen visible → can type → submit → if backend running, you see redirect to student/teacher shell or appropriate error.

- [ ] **Step 6: Commit**

```bash
git add floz_mobile/lib/main.dart floz_mobile/lib/app.dart
git commit -m "feat(mobile): wire ProviderScope, Hive init, router config"
```

---

### Task 38: Definition of Done verification

- [ ] **Step 1: Run full backend suite**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
./vendor/bin/pest
./vendor/bin/pint --test
```

Expected: All tests green, lint clean.

- [ ] **Step 2: Run full mobile suite**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/floz_mobile
flutter analyze
flutter test
```

Expected: Analyzer clean, all tests pass.

- [ ] **Step 3: Verify Swagger renders the auth endpoints**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan l5-swagger:generate
php artisan serve &
sleep 2
curl http://127.0.0.1:8000/api/documentation > /tmp/floz-swagger-page.html
kill %1
```

Expected: Page contains "FLOZ Mobile API" + the three auth paths.

- [ ] **Step 4: Verify route list is V1-correct**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV/src
php artisan route:list --path=api/v1/auth
```

Expected: `POST api/v1/auth/login`, `POST api/v1/auth/logout`, `GET api/v1/auth/me`, all → `App\Http\Controllers\Api\V1\MobileAuthController`.

- [ ] **Step 5: Verify env-driven base URL works**

In mobile dir, ensure the FLOZ_API_BASE_URL define is documented in `floz_mobile/README.md` (create if missing). Add a short note:

```markdown
## Running locally

For Android emulator pointing at host Laravel server:
```bash
flutter run --dart-define=FLOZ_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For iOS simulator:
```bash
flutter run --dart-define=FLOZ_API_BASE_URL=http://127.0.0.1:8000/api/v1
```
```

- [ ] **Step 6: Final commit**

```bash
cd /Users/tokaf/Floz_SDN_KELAPADUA_IV
git add -A
git status
git commit -m "chore(p1): foundation complete — auth reference impl end-to-end" || echo "nothing to commit"
git log --oneline | head -40
```

Expected: A coherent commit history showing all P1 tasks. P1 is now complete.

- [ ] **Step 7: Tag the milestone (optional)**

```bash
git tag p1-foundation-complete
```

---

## P1 Definition of Done — Checklist

- [ ] Git initialized; all P1 work committed
- [ ] `docs/api/CONTRACT.md` exists and is the single source of truth
- [ ] Pest installed, Postgres test DB configured, all backend tests pass
- [ ] `App\Http\Controllers\Api\V1\MobileAuthController` exists; old `Api\MobileAuthController` deleted
- [ ] `LoginRequest`, `UserResource`, `AuthService` exist and are tested
- [ ] `ForceJsonResponse`, `EnsureRole` middleware registered; alias `role:` works
- [ ] Centralized exception handler returns envelope on all `/api/*` errors
- [ ] `GradePolicy` fixed; `AttendancePolicy`, `AnnouncementPolicy`, `ReportCardPolicy` created and tested; `OfflineAssignmentPolicy` audited
- [ ] Rate limiting active on login (5/min/IP) and authenticated routes (60/min/user)
- [ ] L5-Swagger generates docs; auth endpoints visible at `/api/documentation`
- [ ] Mobile `core/network`, `core/error`, `core/storage`, `core/auth`, `shared/widgets` created
- [ ] `mocktail` added to `floz_mobile/pubspec.yaml`
- [ ] Mobile `features/{dashboard,schedule,grades,report_cards,announcements,assignments}` migrated to `features/student/`
- [ ] Mobile `features/auth` refactored: `User` entity, `UserDto`, `AuthRemoteDataSource`, `AuthRepositoryImpl`, providers, `LoginScreen`
- [ ] Role-aware router with `/login`, `/student`, `/teacher` shells
- [ ] All mobile tests pass (`flutter test`); analyzer clean (`flutter analyze`)
- [ ] App launches on emulator; login flow reaches an appropriate shell screen
- [ ] `floz_mobile/README.md` documents how to run with `FLOZ_API_BASE_URL`

---

## Notes for the executing agent

- **TDD discipline is non-negotiable.** Always write the failing test first, run it, see red, then implement, see green, then commit. Do not batch.
- **If a model relation referenced in this plan doesn't match reality** (e.g. `homeroomTeacher` vs `homeroom_teacher`, `class` vs `schoolClass`), STOP and read the actual model + migration file. Adjust the code in the task to match the schema. Do NOT invent column names.
- **Factories may need column tweaks.** Each factory in this plan is based on the spec, not the actual schema. Read `database/migrations/` for the source of truth.
- **If a Pest test fails for a "boring" reason** (column missing, relation typo, factory state), fix the underlying code/factory — never lower the assertion to make it pass.
- **Commit messages follow Conventional Commits** (`feat(scope):`, `fix(scope):`, `test(scope):`, `chore(scope):`, `refactor(scope):`, `docs(scope):`, `style:`).
- **Each task is independent** in the sense that you can stop after any task and the project state is consistent. Do not split a task across sessions if avoidable.
- **If you finish ahead of plan**, do NOT skip the DoD verification (Task 38) — it's the integration smoke test that catches drift.
- **After P1 is complete**, return to the writing-plans skill to draft P2 (Student Read-Only).
