# FLOZ LMS - Learning Management System for K-12 Report Cards

## 🎯 Project Overview

**FLOZ** is a SaaS-based Learning Management System specifically designed for managing student report cards (KHS - Kartu Hasil Studi) across multiple educational institutions (SD/Elementary, SMP/Junior High, SMA/Senior High School) in Indonesia.

**Business Model:** Multi-tenant SaaS platform where FLOZ is the service provider and schools are partners/tenants.

**Tech Stack:**
- Backend: Laravel 12 + PostgreSQL 16
- Frontend: Inertia.js + Vue 3 + Tailwind CSS
- DevOps: Docker + Docker Compose
- Cache/Queue: Redis
- Storage: MinIO (S3-compatible)

---

## 🏗️ Architecture Overview

### Multi-Tenancy Strategy
**Database-per-Tenant Approach:**
- Central database (`floz_central`) - manages tenants, subscriptions, platform users
- Separate database per school (`floz_tenant_{id}`) - complete data isolation
- Benefits: Better security, independent backups, easier scaling

### Domain Strategy
```
Platform (Super Admin):
- admin.floz.id

Tenant (Schools):
- {school-slug}.floz.id
- Or custom domain: sma-negeri-1.sch.id
```

---

## 📦 Project Structure

```
floz-lms/
├── docker/                          # Docker configurations
│   ├── nginx/
│   │   └── default.conf            # Nginx config for Laravel
│   ├── php/
│   │   ├── Dockerfile              # PHP 8.3 + extensions
│   │   └── php.ini                 # PHP configurations
│   ├── postgres/
│   │   └── init.sql                # Initial DB setup
│   └── supervisor/
│       └── supervisord.conf        # Queue worker config
│
├── src/                            # Laravel application root
│   ├── app/
│   │   ├── Models/
│   │   │   ├── Central/           # Models for central DB
│   │   │   │   ├── Tenant.php
│   │   │   │   ├── Subscription.php
│   │   │   │   └── Payment.php
│   │   │   └── Tenant/            # Models for tenant DBs
│   │   │       ├── Student.php
│   │   │       ├── Teacher.php
│   │   │       ├── Class.php
│   │   │       ├── Subject.php
│   │   │       ├── Grade.php
│   │   │       └── ReportCard.php
│   │   │
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   │   ├── Platform/      # Super admin controllers
│   │   │   │   │   ├── DashboardController.php
│   │   │   │   │   ├── TenantController.php
│   │   │   │   │   └── SubscriptionController.php
│   │   │   │   ├── Tenant/        # School admin/teacher controllers
│   │   │   │   │   ├── DashboardController.php
│   │   │   │   │   ├── StudentController.php
│   │   │   │   │   ├── GradeController.php
│   │   │   │   │   └── ReportCardController.php
│   │   │   │   └── Api/           # API endpoints
│   │   │   │       └── V1/
│   │   │   │
│   │   │   └── Middleware/
│   │   │       ├── IdentifyTenant.php
│   │   │       ├── TenantAccess.php
│   │   │       └── CheckSubscription.php
│   │   │
│   │   ├── Services/
│   │   │   ├── TenantService.php              # Tenant management
│   │   │   ├── GradeCalculationService.php    # Grade calculation logic
│   │   │   ├── ReportCardService.php          # Report card generation
│   │   │   ├── PdfGeneratorService.php        # PDF export
│   │   │   └── NotificationService.php        # Notification handling
│   │   │
│   │   ├── Traits/
│   │   │   ├── UsesTenantConnection.php
│   │   │   └── HasAcademicYear.php
│   │   │
│   │   └── Enums/
│   │       ├── UserRole.php
│   │       ├── EducationLevel.php
│   │       ├── GradeType.php
│   │       └── SubscriptionStatus.php
│   │
│   ├── database/
│   │   ├── migrations/
│   │   │   ├── central/                       # Central DB migrations
│   │   │   │   ├── 2024_01_01_create_tenants_table.php
│   │   │   │   ├── 2024_01_02_create_subscriptions_table.php
│   │   │   │   └── 2024_01_03_create_payments_table.php
│   │   │   └── tenant/                        # Tenant DB migrations
│   │   │       ├── 2024_01_01_create_students_table.php
│   │   │       ├── 2024_01_02_create_teachers_table.php
│   │   │       ├── 2024_01_03_create_classes_table.php
│   │   │       ├── 2024_01_04_create_subjects_table.php
│   │   │       ├── 2024_01_05_create_academic_years_table.php
│   │   │       ├── 2024_01_06_create_grades_table.php
│   │   │       └── 2024_01_07_create_report_cards_table.php
│   │   │
│   │   └── seeders/
│   │       ├── CentralDatabaseSeeder.php
│   │       └── TenantDatabaseSeeder.php
│   │
│   ├── resources/
│   │   ├── js/
│   │   │   ├── Pages/
│   │   │   │   ├── Platform/              # Super admin pages
│   │   │   │   │   ├── Dashboard.vue
│   │   │   │   │   ├── Tenants/
│   │   │   │   │   └── Subscriptions/
│   │   │   │   ├── Tenant/                # School pages
│   │   │   │   │   ├── Dashboard.vue
│   │   │   │   │   ├── Students/
│   │   │   │   │   ├── Grades/
│   │   │   │   │   └── ReportCards/
│   │   │   │   └── Auth/
│   │   │   │
│   │   │   ├── Components/
│   │   │   │   ├── Common/
│   │   │   │   ├── Forms/
│   │   │   │   ├── Tables/
│   │   │   │   └── Charts/
│   │   │   │
│   │   │   └── Layouts/
│   │   │       ├── PlatformLayout.vue
│   │   │       ├── TenantLayout.vue
│   │   │       └── GuestLayout.vue
│   │   │
│   │   └── views/
│   │       └── pdf/
│   │           ├── report-card-sd.blade.php
│   │           ├── report-card-smp.blade.php
│   │           └── report-card-sma.blade.php
│   │
│   ├── routes/
│   │   ├── platform.php               # Routes for super admin
│   │   ├── tenant.php                 # Routes for school users
│   │   ├── api.php                    # API routes
│   │   └── web.php                    # Public routes
│   │
│   ├── config/
│   │   ├── tenancy.php               # Tenancy configuration
│   │   └── floz.php                  # Custom app config
│   │
│   └── tests/
│       ├── Feature/
│       │   ├── Platform/
│       │   └── Tenant/
│       └── Unit/
│           └── Services/
│
├── docker-compose.yml                 # Production docker setup
├── docker-compose.dev.yml             # Development docker setup
├── .env.example                       # Environment template
└── README.md                          # This file
```

---

## 🗄️ Database Schema

### Central Database (`floz_central`)

#### `tenants` table
```sql
id                  BIGSERIAL PRIMARY KEY
name                VARCHAR(255) NOT NULL           -- School name
slug                VARCHAR(255) UNIQUE NOT NULL    -- URL slug
database_name       VARCHAR(255) UNIQUE NOT NULL    -- Tenant DB name
domain              VARCHAR(255) UNIQUE             -- Custom domain
education_level     VARCHAR(50) NOT NULL            -- SD/SMP/SMA
npsn                VARCHAR(20) UNIQUE              -- National School ID
email               VARCHAR(255) NOT NULL
phone               VARCHAR(20)
address             TEXT
logo_url            VARCHAR(255)
status              VARCHAR(20) DEFAULT 'active'    -- active/suspended/inactive
subscription_plan   VARCHAR(50)                     -- starter/professional/enterprise
max_students        INTEGER DEFAULT 100
expires_at          TIMESTAMP
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `subscriptions` table
```sql
id                  BIGSERIAL PRIMARY KEY
tenant_id           BIGINT REFERENCES tenants(id)
plan_name           VARCHAR(50) NOT NULL
price               DECIMAL(10,2) NOT NULL
billing_cycle       VARCHAR(20)                     -- monthly/yearly
starts_at           TIMESTAMP NOT NULL
ends_at             TIMESTAMP NOT NULL
status              VARCHAR(20) DEFAULT 'active'    -- active/expired/cancelled
auto_renew          BOOLEAN DEFAULT true
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `payments` table
```sql
id                  BIGSERIAL PRIMARY KEY
subscription_id     BIGINT REFERENCES subscriptions(id)
amount              DECIMAL(10,2) NOT NULL
payment_method      VARCHAR(50)
payment_status      VARCHAR(20)                     -- pending/success/failed
transaction_id      VARCHAR(255)
paid_at             TIMESTAMP
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

### Tenant Database (`floz_tenant_{id}`)

#### `students` table
```sql
id                  BIGSERIAL PRIMARY KEY
nis                 VARCHAR(20) UNIQUE NOT NULL     -- Student ID Number
nisn                VARCHAR(20) UNIQUE              -- National Student ID
name                VARCHAR(255) NOT NULL
gender              VARCHAR(10)                     -- male/female
birth_place         VARCHAR(100)
birth_date          DATE
religion            VARCHAR(20)
address             TEXT
parent_name         VARCHAR(255)
parent_phone        VARCHAR(20)
email               VARCHAR(255)
class_id            BIGINT REFERENCES classes(id)
status              VARCHAR(20) DEFAULT 'active'    -- active/graduated/transferred/dropout
photo_url           VARCHAR(255)
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `teachers` table
```sql
id                  BIGSERIAL PRIMARY KEY
nip                 VARCHAR(20) UNIQUE              -- Teacher ID Number
nuptk               VARCHAR(20) UNIQUE              -- National Teacher ID
name                VARCHAR(255) NOT NULL
gender              VARCHAR(10)
birth_place         VARCHAR(100)
birth_date          DATE
email               VARCHAR(255) NOT NULL UNIQUE
phone               VARCHAR(20)
address             TEXT
is_homeroom         BOOLEAN DEFAULT false
photo_url           VARCHAR(255)
status              VARCHAR(20) DEFAULT 'active'
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `classes` table
```sql
id                  BIGSERIAL PRIMARY KEY
name                VARCHAR(50) NOT NULL            -- e.g., "7A", "X IPA 1"
grade_level         INTEGER NOT NULL                -- 1-6 (SD), 7-9 (SMP), 10-12 (SMA)
academic_year_id    BIGINT REFERENCES academic_years(id)
homeroom_teacher_id BIGINT REFERENCES teachers(id)
max_students        INTEGER DEFAULT 40
status              VARCHAR(20) DEFAULT 'active'
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `subjects` table
```sql
id                  BIGSERIAL PRIMARY KEY
code                VARCHAR(20) UNIQUE NOT NULL
name                VARCHAR(255) NOT NULL           -- e.g., "Matematika", "Bahasa Indonesia"
education_level     VARCHAR(10) NOT NULL            -- SD/SMP/SMA
grade_level         INTEGER                         -- applicable grade (1-12)
kkm                 DECIMAL(5,2) DEFAULT 70.00      -- Minimum passing grade
category            VARCHAR(50)                     -- general/religion/specialty
description         TEXT
status              VARCHAR(20) DEFAULT 'active'
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `academic_years` table
```sql
id                  BIGSERIAL PRIMARY KEY
name                VARCHAR(50) NOT NULL            -- e.g., "2024/2025"
start_date          DATE NOT NULL
end_date            DATE NOT NULL
is_active           BOOLEAN DEFAULT false
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `semesters` table
```sql
id                  BIGSERIAL PRIMARY KEY
academic_year_id    BIGINT REFERENCES academic_years(id)
semester_number     INTEGER NOT NULL                -- 1 or 2
start_date          DATE NOT NULL
end_date            DATE NOT NULL
is_active           BOOLEAN DEFAULT false
created_at          TIMESTAMP
updated_at          TIMESTAMP
```

#### `grades` table
```sql
id                  BIGSERIAL PRIMARY KEY
student_id          BIGINT REFERENCES students(id)
subject_id          BIGINT REFERENCES subjects(id)
class_id            BIGINT REFERENCES classes(id)
semester_id         BIGINT REFERENCES semesters(id)
teacher_id          BIGINT REFERENCES teachers(id)

-- For SD (Elementary)
daily_test_avg      DECIMAL(5,2)                    -- Nilai harian
mid_test            DECIMAL(5,2)                    -- UTS
final_test          DECIMAL(5,2)                    -- UAS
final_score         DECIMAL(5,2)                    -- Nilai akhir
description         TEXT                            -- Deskripsi capaian

-- For SMP/SMA (Junior/Senior High)
knowledge_score     DECIMAL(5,2)                    -- Pengetahuan (KI-3)
skill_score         DECIMAL(5,2)                    -- Keterampilan (KI-4)
final_score         DECIMAL(5,2)                    -- Nilai akhir
predicate           VARCHAR(2)                      -- A/B/C/D
description         TEXT                            -- Deskripsi capaian

-- Common fields
attendance_score    DECIMAL(5,2)                    -- Nilai kehadiran
attitude_score      VARCHAR(2)                      -- SB/B/C/K (Sangat Baik/Baik/Cukup/Kurang)
notes               TEXT
created_at          TIMESTAMP
updated_at          TIMESTAMP

UNIQUE(student_id, subject_id, semester_id)
```

#### `report_cards` table
```sql
id                  BIGSERIAL PRIMARY KEY
student_id          BIGINT REFERENCES students(id)
class_id            BIGINT REFERENCES classes(id)
semester_id         BIGINT REFERENCES semesters(id)
rank                INTEGER                         -- Class ranking (optional)
total_score         DECIMAL(5,2)
average_score       DECIMAL(5,2)
attendance_present  INTEGER DEFAULT 0
attendance_sick     INTEGER DEFAULT 0
attendance_permit   INTEGER DEFAULT 0
attendance_absent   INTEGER DEFAULT 0
achievements        TEXT                            -- Prestasi
notes               TEXT                            -- Catatan wali kelas
behavior_notes      TEXT                            -- Catatan sikap
homeroom_comment    TEXT                            -- Komentar wali kelas
principal_comment   TEXT                            -- Komentar kepala sekolah
status              VARCHAR(20) DEFAULT 'draft'     -- draft/published
published_at        TIMESTAMP
pdf_url             VARCHAR(255)
created_at          TIMESTAMP
updated_at          TIMESTAMP

UNIQUE(student_id, semester_id)
```

#### `attendance` table
```sql
id                  BIGSERIAL PRIMARY KEY
student_id          BIGINT REFERENCES students(id)
date                DATE NOT NULL
status              VARCHAR(20) NOT NULL            -- present/sick/permit/absent
notes               TEXT
created_at          TIMESTAMP
updated_at          TIMESTAMP

UNIQUE(student_id, date)
```

---

## 👥 User Roles & Permissions

### Platform Level (Central System)

#### 1. Super Admin
**Access:** Full system control
**Responsibilities:**
- Manage all tenants (schools)
- Create/suspend/delete school accounts
- Monitor system health and usage
- Manage subscription plans and pricing
- View analytics across all schools
- Handle support tickets
- System configuration

**Permissions:**
```php
'platform.tenants.*'
'platform.subscriptions.*'
'platform.analytics.*'
'platform.settings.*'
```

### Tenant Level (Per School)

#### 2. School Admin
**Access:** Full school management
**Responsibilities:**
- Manage school profile and settings
- Create academic years and semesters
- Manage teachers and students
- Manage classes and subjects
- Set up KKM (minimum passing grades)
- Configure report card templates
- View school-wide reports
- Manage school users

**Permissions:**
```php
'tenant.settings.*'
'tenant.teachers.*'
'tenant.students.*'
'tenant.classes.*'
'tenant.subjects.*'
'tenant.reports.view'
'tenant.users.*'
```

#### 3. Teacher / Homeroom Teacher
**Access:** Limited to assigned classes/subjects
**Responsibilities:**
- Input grades for assigned subjects
- View student data in assigned classes
- Generate report cards for students
- Input attendance (homeroom teacher)
- Add notes and comments
- Export report cards to PDF

**Permissions:**
```php
'tenant.grades.create'
'tenant.grades.update'
'tenant.grades.view.own'
'tenant.students.view.assigned'
'tenant.reportcards.generate'
'tenant.reportcards.export'
'tenant.attendance.manage' // homeroom only
```

#### 4. Student
**Access:** Personal academic data only
**Responsibilities:**
- View own grades and report cards
- Download report cards
- View attendance record
- View academic progress charts

**Permissions:**
```php
'tenant.grades.view.own'
'tenant.reportcards.view.own'
'tenant.reportcards.download.own'
'tenant.attendance.view.own'
```

#### 5. Parent/Guardian
**Access:** Child's academic data
**Responsibilities:**
- View child's grades and report cards
- Download child's report cards
- View attendance record
- Receive notifications about grades

**Permissions:**
```php
'tenant.grades.view.child'
'tenant.reportcards.view.child'
'tenant.reportcards.download.child'
'tenant.attendance.view.child'
```

---

## 🔐 Authentication & Authorization

### Authentication Flow

1. **Platform (Super Admin):**
   - Login at: `admin.floz.id`
   - Uses central database
   - Laravel Sanctum for API tokens

2. **Tenant (School Users):**
   - Login at: `{school-slug}.floz.id`
   - Middleware identifies tenant from subdomain
   - Switch connection to tenant database
   - Authenticate against tenant's users table
   - Session stores tenant context

### Middleware Stack

```php
// Route: platform.php (Super Admin)
Route::middleware(['auth:sanctum', 'platform'])->group(function () {
    // Platform routes
});

// Route: tenant.php (School Users)
Route::middleware(['tenant', 'auth:sanctum', 'subscription.active'])->group(function () {
    // Tenant routes
});
```

### Key Middleware

**1. IdentifyTenant:**
- Extracts tenant from subdomain/domain
- Loads tenant data from central DB
- Switches database connection
- Stores tenant in container

**2. TenantAccess:**
- Verifies user belongs to current tenant
- Checks user roles and permissions
- Prevents cross-tenant access

**3. CheckSubscription:**
- Verifies tenant subscription is active
- Checks feature limits (max students, etc.)
- Redirects to upgrade page if expired

---

## 🧮 Grade Calculation Logic

### For SD (Elementary School)

**Components:**
- Daily tests (Ulangan Harian)
- Mid-semester test (UTS)
- Final semester test (UAS)

**Formula:**
```php
$finalScore = (
    $dailyTestAverage * 0.40 +
    $midTest * 0.30 +
    $finalTest * 0.30
);

// Generate description based on score
if ($finalScore >= 90) {
    $description = "Sangat baik dalam memahami {subject}...";
} elseif ($finalScore >= 80) {
    $description = "Baik dalam memahami {subject}...";
} // etc.
```

### For SMP/SMA (Junior/Senior High)

**Components:**
- Knowledge Score (Pengetahuan - KI 3)
- Skill Score (Keterampilan - KI 4)

**Formula:**
```php
$finalScore = ($knowledgeScore + $skillScore) / 2;

// Determine predicate
$predicate = match(true) {
    $finalScore >= 90 => 'A',
    $finalScore >= 80 => 'B',
    $finalScore >= 70 => 'C',
    default => 'D'
};

// Generate description based on predicate
```

### KKM (Minimum Passing Grade)

- Each subject has its own KKM (typically 70-75)
- Students must achieve >= KKM to pass
- Below KKM triggers remedial flag

---

## 📊 Report Card Generation

### Process Flow

1. **Input Stage:**
   - Teacher inputs grades per subject
   - System validates against KKM
   - Auto-calculate final scores

2. **Review Stage:**
   - Homeroom teacher reviews all grades
   - Add homeroom comments
   - Add behavior notes
   - Calculate class ranking (optional)

3. **Approval Stage:**
   - School admin reviews
   - Principal adds comments
   - Mark as "published"

4. **Distribution Stage:**
   - Generate PDF
   - Send notification to students/parents
   - Enable download

### PDF Template

**Structure:**
- School header (logo, name, address)
- Student information
- Academic year and semester
- Grade table (all subjects)
- Attendance summary
- Behavior notes
- Homeroom teacher comment
- Principal's note
- Digital signatures
- QR code for verification (optional)

**Customization:**
- Per education level (SD/SMP/SMA)
- School branding
- Custom fields
- Language options

---

## 🚀 Key Features Implementation

### 1. Tenant Onboarding

**Process:**
```
1. Super admin creates tenant
   - Input school details
   - Choose subscription plan
   - Set expiry date

2. System creates:
   - Tenant record in central DB
   - New database for tenant
   - Run tenant migrations
   - Create default admin user
   - Send welcome email

3. School admin setup:
   - Login with credentials
   - Complete school profile
   - Upload logo
   - Set academic year
   - Import students (Excel)
   - Create classes and subjects
```

### 2. Bulk Import (Excel)

**Students Import:**
```
Columns required:
- NIS, NISN, Name, Gender
- Birth Place, Birth Date
- Religion, Address
- Parent Name, Parent Phone
- Class Name

Process:
- Validate data
- Check duplicates
- Create/update records
- Generate report
```

### 3. Grade Input Interface

**Batch Input:**
- Select: Class + Subject + Semester
- Display: Student list with input fields
- Validate: KKM compliance
- Save: All grades in one transaction
- Auto-calculate: Final scores and predicates

**Individual Input:**
- Student profile view
- All subjects for selected semester
- Historical data visible
- Progress charts

### 4. Report Card Templates

**Template System:**
- Multiple templates per education level
- Blade templates with variables
- CSS styling for print
- Dynamic content injection
- Preview before publish

### 5. Notification System

**Triggers:**
- New grades posted
- Report card published
- Low grades alert
- Subscription expiring
- System announcements

**Channels:**
- Email
- WhatsApp (via API)
- In-app notification
- SMS (optional)

### 6. Analytics Dashboard

**Platform Level:**
- Total tenants
- Active subscriptions
- Revenue metrics
- System usage stats
- Growth charts

**Tenant Level:**
- Total students per class
- Average grades per subject
- Pass/fail ratio
- Attendance statistics
- Teacher performance

---

## 🐳 Docker Setup

### Services Architecture

```yaml
services:
  # Laravel Application
  app:
    - PHP 8.3-FPM
    - Composer dependencies
    - Laravel installed
    - Cron jobs configured
    
  # Web Server
  nginx:
    - Serves static files
    - Proxies to PHP-FPM
    - SSL ready
    
  # Database
  postgres:
    - PostgreSQL 16
    - Multiple databases support
    - Persistent volume
    
  # Cache & Queue
  redis:
    - Cache driver
    - Queue driver
    - Session storage
    
  # Queue Worker
  horizon:
    - Process queued jobs
    - Monitor queues
    - Web dashboard
    
  # Object Storage
  minio:
    - S3-compatible
    - Store PDFs, photos
    - Bucket per tenant
    
  # Email Testing (Dev only)
  mailpit:
    - Catch all emails
    - Web interface
```

### Environment Variables

```env
# Application
APP_NAME=FLOZ
APP_ENV=production
APP_KEY=base64:...
APP_URL=https://floz.id

# Central Database
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=floz_central
DB_USERNAME=floz_user
DB_PASSWORD=secure_password

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Queue
QUEUE_CONNECTION=redis

# Cache
CACHE_DRIVER=redis

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525

# Storage
FILESYSTEM_DISK=minio
AWS_ACCESS_KEY_ID=minio_access_key
AWS_SECRET_ACCESS_KEY=minio_secret_key
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=floz
AWS_ENDPOINT=http://minio:9000

# Tenancy
TENANCY_DATABASE_PREFIX=floz_tenant_
```

---

## 🔄 Development Workflow

### Setup Development Environment

```bash
# 1. Clone repository
git clone https://github.com/yourusername/floz-lms.git
cd floz-lms

# 2. Copy environment file
cp .env.example .env

# 3. Start Docker containers
docker-compose -f docker-compose.dev.yml up -d

# 4. Install dependencies
docker-compose exec app composer install
docker-compose exec app npm install

# 5. Generate app key
docker-compose exec app php artisan key:generate

# 6. Run migrations
docker-compose exec app php artisan migrate --database=central
docker-compose exec app php artisan tenants:migrate

# 7. Seed databases
docker-compose exec app php artisan db:seed --class=CentralDatabaseSeeder

# 8. Start frontend dev server
docker-compose exec app npm run dev

# Access:
# - Platform: http://admin.localhost:8080
# - Tenant: http://demo.localhost:8080
```

### Common Commands

```bash
# Create new migration (central)
php artisan make:migration create_xxx_table --path=database/migrations/central

# Create new migration (tenant)
php artisan make:migration create_xxx_table --path=database/migrations/tenant

# Run tenant migrations for specific tenant
php artisan tenants:migrate --tenants=1,2,3

# Create new tenant
php artisan tenants:create

# List all tenants
php artisan tenants:list

# Run queue worker
php artisan horizon

# Run tests
php artisan test

# Generate IDE helper
php artisan ide-helper:generate
php artisan ide-helper:models
```

### Code Standards

**PHP:**
- PSR-12 coding standard
- Type hints required
- DocBlocks for all methods
- Use service classes for business logic
- Keep controllers thin

**JavaScript/Vue:**
- Composition API preferred
- TypeScript recommended
- Component naming: PascalCase
- Props validation required
- Emit events with clear names

**Database:**
- Always use migrations
- Never edit migrations after deploy
- Use seeders for test data
- Foreign keys required
- Indexes on foreign keys

---

## 🧪 Testing Strategy

### Test Structure

```
tests/
├── Feature/
│   ├── Platform/
│   │   ├── TenantManagementTest.php
│   │   └── SubscriptionTest.php
│   └── Tenant/
│       ├── GradeInputTest.php
│       ├── ReportCardTest.php
│       └── StudentManagementTest.php
├── Unit/
│   ├── GradeCalculationServiceTest.php
│   ├── ReportCardServiceTest.php
│   └── TenantServiceTest.php
└── Browser/
    └── GradeInputFlowTest.php
```

### Key Test Cases

**Platform Tests:**
- [ ] Create tenant with database
- [ ] Suspend tenant access
- [ ] Process subscription payment
- [ ] Generate platform analytics

**Tenant Tests:**
- [ ] Import students from Excel
- [ ] Input grades with validation
- [ ] Calculate final scores correctly
- [ ] Generate report card PDF
- [ ] Send notifications
- [ ] Export data to Excel

**Unit Tests:**
- [ ] Grade calculation for SD
- [ ] Grade calculation for SMP/SMA
- [ ] Predicate assignment
- [ ] KKM validation
- [ ] Tenant isolation

### Running Tests

```bash
# All tests
php artisan test

# Specific suite
php artisan test --testsuite=Feature

# With coverage
php artisan test --coverage

# Browser tests (Dusk)
php artisan dusk
```

---

## 📈 Performance Optimization

### Database Optimization

1. **Indexes:**
   - Foreign keys
   - Search fields (NIS, NISN, name)
   - Filter fields (status, class_id)
   - Sorting fields (created_at)

2. **Query Optimization:**
   - Eager loading relationships
   - Select only needed columns
   - Use database transactions
   - Implement cursor pagination

3. **Caching Strategy:**
   - Cache tenant configuration
   - Cache academic year/semester
   - Cache report card PDFs
   - Cache aggregated statistics

### Application Optimization

1. **Queue Jobs:**
   - PDF generation
   - Excel imports/exports
   - Email sending
   - Notification broadcasting

2. **Asset Optimization:**
   - Minify CSS/JS
   - Image optimization
   - Lazy loading
   - CDN for static assets

3. **Code Optimization:**
   - Use Laravel's built-in caching
   - Optimize N+1 queries
   - Use chunks for large datasets
   - Implement API rate limiting

---

## 🔒 Security Measures

### Application Security

- [x] CSRF protection (Laravel default)
- [x] XSS prevention (Blade escaping)
- [x] SQL injection prevention (Eloquent ORM)
- [x] Rate limiting on API endpoints
- [x] Two-factor authentication (2FA)
- [x] Password hashing (bcrypt)
- [x] Secure session handling
- [x] HTTPS enforcement

### Data Security

- [x] Database encryption at rest
- [x] API token encryption
- [x] Sensitive data masking in logs
- [x] Regular backups
- [x] Tenant data isolation
- [x] Audit logging for critical actions

### Access Control

- [x] Role-based permissions
- [x] Tenant boundary enforcement
- [x] API authentication (Sanctum)
- [x] IP whitelisting (optional)
- [x] Session timeout
- [x] Failed login tracking

---

## 📦 Deployment

### Production Requirements

**Server:**
- Ubuntu 22.04 LTS or later
- 4 CPU cores minimum
- 8GB RAM minimum
- 100GB SSD storage
- Docker & Docker Compose installed

**Services:**
- Domain with SSL certificate
- Email service (SMTP)
- WhatsApp Business API (optional)
- Payment gateway (Midtrans/Xendit)

### Deployment Steps

```bash
# 1. Clone repository on server
git clone https://github.com/yourusername/floz-lms.git
cd floz-lms

# 2. Setup environment
cp .env.example .env
# Edit .env with production values

# 3. Build and start containers
docker-compose up -d --build

# 4. Run migrations
docker-compose exec app php artisan migrate --force

# 5. Optimize Laravel
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache

# 6. Setup SSL (Let's Encrypt)
# Configure nginx with certbot

# 7. Setup backup cron job
# Add to crontab for daily backups
```

### Monitoring

**Tools:**
- Laravel Telescope (development)
- Laravel Horizon (queue monitoring)
- Database query logging
- Error tracking (Sentry/Bugsnag)
- Server monitoring (New Relic/DataDog)
- Uptime monitoring (Pingdom)

### Backup Strategy

**Daily Backups:**
- PostgreSQL databases (all)
- Uploaded files (MinIO)
- .env configuration
- Docker volumes

**Retention:**
- Daily: 7 days
- Weekly: 4 weeks
- Monthly: 12 months

**Backup Command:**
```bash
# Automated backup script
php artisan backup:run
```

---

## 📝 API Documentation

### Base URLs

```
Platform API: https://api.floz.id/v1/platform
Tenant API:   https://api.floz.id/v1/tenant
```

### Authentication

```
Authorization: Bearer {token}
X-Tenant-ID: {tenant_id}  // For tenant endpoints
```

### Example Endpoints

**Platform:**
```
GET    /api/v1/platform/tenants
POST   /api/v1/platform/tenants
GET    /api/v1/platform/tenants/{id}
PUT    /api/v1/platform/tenants/{id}
DELETE /api/v1/platform/tenants/{id}
```

**Tenant:**
```
GET    /api/v1/tenant/students
POST   /api/v1/tenant/students
GET    /api/v1/tenant/students/{id}
PUT    /api/v1/tenant/students/{id}
DELETE /api/v1/tenant/students/{id}

POST   /api/v1/tenant/grades
GET    /api/v1/tenant/grades?class_id={id}&semester_id={id}

POST   /api/v1/tenant/report-cards/generate
GET    /api/v1/tenant/report-cards/{id}/pdf
```

---

## 🎨 UI/UX Guidelines

### Design System

**Colors:**
- Primary: #3B82F6 (Blue)
- Secondary: #10B981 (Green)
- Accent: #F59E0B (Amber)
- Danger: #EF4444 (Red)
- Success: #22C55E (Green)

**Typography:**
- Headings: Inter (Bold)
- Body: Inter (Regular)
- Code: Fira Code

**Components:**
- Use Tailwind CSS utility classes
- DaisyUI components for common UI
- Custom components in /Components folder
- Responsive design (mobile-first)

### Key Screens

1. **Platform Dashboard:**
   - Tenant overview cards
   - Revenue charts
   - Recent activities
   - System health

2. **Tenant Dashboard:**
   - Student statistics
   - Recent grades
   - Upcoming deadlines
   - Quick actions

3. **Grade Input:**
   - Bulk input table
   - Real-time validation
   - KKM indicators
   - Auto-save draft

4. **Report Card View:**
   - Clean, printable layout
   - School branding
   - Grade table
   - Charts and graphs
   - Export options

---

## 🚀 Roadmap

### Phase 1: MVP (Month 1-2)
- [x] Docker environment setup
- [x] Database design
- [x] Multi-tenancy implementation
- [x] Authentication system
- [ ] Basic CRUD operations
- [ ] Grade input
- [ ] Simple report card generation

### Phase 2: Core Features (Month 3)
- [ ] Excel import/export
- [ ] PDF generation with templates
- [ ] Student/parent portal
- [ ] Notification system
- [ ] Analytics dashboard
- [ ] Mobile responsive

### Phase 3: Enhancement (Month 4)
- [ ] Advanced reporting
- [ ] Custom report templates
- [ ] WhatsApp integration
- [ ] Email notifications
- [ ] Activity logging
- [ ] Data export tools

### Phase 4: Scale (Month 5+)
- [ ] Payment gateway integration
- [ ] Mobile app (Flutter)
- [ ] E-learning module
- [ ] Online examination
- [ ] Parent-teacher chat
- [ ] Attendance tracking
- [ ] Performance optimization

---

## 🤝 Contributing

### Branch Strategy

```
main         - Production-ready code
develop      - Integration branch
feature/*    - New features
bugfix/*     - Bug fixes
hotfix/*     - Urgent production fixes
```

### Pull Request Process

1. Create feature branch from `develop`
2. Write tests for new features
3. Ensure all tests pass
4. Update documentation
5. Submit PR to `develop`
6. Code review by team
7. Merge after approval

### Commit Message Convention

```
feat: Add student import feature
fix: Fix grade calculation bug
docs: Update API documentation
style: Format code with PSR-12
refactor: Restructure grade service
test: Add report card tests
chore: Update dependencies
```

---

## 📞 Support & Contact

### For Developers
- Documentation: https://docs.floz.id
- API Reference: https://api.floz.id/docs
- GitHub Issues: https://github.com/yourusername/floz-lms/issues

### For Schools
- Help Center: https://help.floz.id
- Email: support@floz.id
- WhatsApp: +62 XXX XXXX XXXX

---

## 📄 License

This project is proprietary software. All rights reserved.

© 2024 FLOZ LMS. Unauthorized copying, distribution, or modification is prohibited.

---

## 🎯 Quick Reference for AI Agents

### When Creating New Features:

1. **Identify Context:**
   - Platform or Tenant feature?
   - Which role(s) can access?

2. **Create Required Files:**
   - Migration (central/ or tenant/)
   - Model with relationships
   - Service class for business logic
   - Controller (thin, delegates to service)
   - Vue component/page
   - API endpoint (if needed)
   - Tests (Feature + Unit)

3. **Follow Patterns:**
   - Use existing code as template
   - Maintain consistent naming
   - Keep logic in services
   - Use repositories for complex queries
   - Validate all inputs
   - Handle errors gracefully

4. **Update Documentation:**
   - Add API endpoint to docs
   - Update database schema if changed
   - Add to relevant section in README

### Common Patterns:

**Multi-tenancy:**
```php
// Switch to tenant database
DB::connection('tenant')->table('students')->get();

// Or use trait
use UsesTenantConnection;
```

**Permission Check:**
```php
if (Gate::allows('tenant.grades.create')) {
    // Allow
}
```

**Queue Job:**
```php
GenerateReportCardPdf::dispatch($reportCard);
```

**Cache:**
```php
Cache::remember('tenant.' . $tenantId . '.settings', 3600, function () {
    return TenantSettings::all();
});
```

---

**Last Updated:** 2024-01-15
**Version:** 1.0.0
**Author:** FLOZ Development Team
