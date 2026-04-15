# FLOZ Mobile — Theme & Style Guide

> **Versi**: 1.0.0  
> **Tanggal**: 19 Februari 2026  
> **Tujuan**: Referensi definitif agar seluruh UI mobile konsisten dengan branding FLOZ Web  
> **Target**: AI developer / developer manusia yang mengimplementasi Flutter app

---

## 1. Brand Identity

| Atribut | Nilai |
|:--------|:------|
| **Nama** | FLOZ |
| **Tagline** | Learning Management System |
| **Logo Text** | "FLOZ." — titik di akhir, font Space Grotesk Bold |
| **Logo Icon** | Huruf "F" putih bold di atas rounded-square bergradien orange |
| **Personality** | Modern, bersih, hangat, profesional tapi ramah |

---

## 2. Color Palette

### 2.1 Primary Colors (Orange)

```dart
// Primary
static const Color primary50  = Color(0xFFFFF7ED); // bg-orange-50
static const Color primary100 = Color(0xFFFFEDD5); // bg-orange-100
static const Color primary200 = Color(0xFFFED7AA); // bg-orange-200
static const Color primary300 = Color(0xFFFDBA74); // bg-orange-300
static const Color primary400 = Color(0xFFFB923C); // bg-orange-400
static const Color primary500 = Color(0xFFF97316); // bg-orange-500  ← MAIN
static const Color primary600 = Color(0xFFEA580C); // bg-orange-600  ← MAIN DARK
static const Color primary700 = Color(0xFFC2410C); // bg-orange-700
static const Color primary800 = Color(0xFF9A3412); // bg-orange-800
static const Color primary900 = Color(0xFF7C2D12); // bg-orange-900
```

> [!IMPORTANT]
> **Primary-500 (`#F97316`)** digunakan sebagai warna utama tombol, ikon aktif, dan accent.  
> **Primary-600 (`#EA580C`)** digunakan untuk hover state / pressed state.

### 2.2 Neutral Colors (Slate)

```dart
// Neutral / Slate
static const Color slate50  = Color(0xFFF8FAFC);
static const Color slate100 = Color(0xFFF1F5F9);
static const Color slate200 = Color(0xFFE2E8F0); // border default
static const Color slate300 = Color(0xFFCBD5E1);
static const Color slate400 = Color(0xFF94A3B8); // label/caption text
static const Color slate500 = Color(0xFF64748B); // secondary text
static const Color slate600 = Color(0xFF475569); // body text
static const Color slate700 = Color(0xFF334155); // title text
static const Color slate800 = Color(0xFF1E293B); // heading text
static const Color slate900 = Color(0xFF0F172A); // darkest text
```

### 2.3 Semantic Colors

```dart
// Success (Emerald)
static const Color success50  = Color(0xFFECFDF5);
static const Color success500 = Color(0xFF10B981);
static const Color success600 = Color(0xFF059669);
static const Color success700 = Color(0xFF047857);

// Warning (Amber)
static const Color warning50  = Color(0xFFFFFBEB);
static const Color warning500 = Color(0xFFF59E0B);
static const Color warning600 = Color(0xFFD97706);
static const Color warning700 = Color(0xFFB45309);

// Danger (Red)
static const Color danger50  = Color(0xFFFEF2F2);
static const Color danger500 = Color(0xFFEF4444);
static const Color danger600 = Color(0xFFDC2626);
static const Color danger700 = Color(0xFFB91C1C);

// Info (Blue)
static const Color info50  = Color(0xFFEFF6FF);
static const Color info500 = Color(0xFF3B82F6);
static const Color info600 = Color(0xFF2563EB);
static const Color info700 = Color(0xFF1D4ED8);

// Purple (accent)
static const Color purple50  = Color(0xFFFAF5FF);
static const Color purple500 = Color(0xFF8B5CF6);
static const Color purple600 = Color(0xFF7C3AED);
static const Color purple700 = Color(0xFF6D28D9);
```

### 2.4 Background Gradients

```dart
// Page background (light mode)
final pageGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [slate50, Colors.white, primary50.withOpacity(0.3)],
);

// Hero/Header gradient
final heroGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [primary500, Color(0xFFF59E0B)], // orange-500 → amber-500
);

// Logo icon gradient
final logoGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primary500, primary600],
);

// Dark mode (landing page style)
static const Color darkBg = Color(0xFF09090B);     // zinc-950
static const Color darkSurface = Color(0xFF18181B); // zinc-900
```

---

## 3. Typography

### 3.1 Font Families

| Penggunaan | Font | Fallback |
|:-----------|:-----|:---------|
| **Brand/Logo** | Space Grotesk Bold | sans-serif |
| **Body/UI** | Inter | Roboto, sans-serif |
| **Monospace** | JetBrains Mono | monospace |

> [!NOTE]
> Gunakan package `google_fonts` untuk load Inter dari Google Fonts. Space Grotesk di-bundle sebagai asset lokal untuk logo.

### 3.2 Font Scale (Mobile)

```dart
// Display
TextStyle displayLarge  = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
TextStyle displayMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25);
TextStyle displaySmall  = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);

// Headline
TextStyle headlineMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35);
TextStyle headlineSmall  = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

// Title
TextStyle titleLarge  = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
TextStyle titleMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.45);
TextStyle titleSmall  = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.45);

// Body
TextStyle bodyLarge  = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
TextStyle bodySmall  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

// Label (uppercase tracking)
TextStyle labelLarge  = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5);
TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4);
TextStyle labelSmall  = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8,
  textTransform: TextTransform.uppercase); // untuk stat label
```

### 3.3 Text Colors

| Penggunaan | Warna | Hex |
|:-----------|:------|:----|
| Heading / Judul | `slate800` | `#1E293B` |
| Body text | `slate600` | `#475569` |
| Secondary / Caption | `slate400` | `#94A3B8` |
| Link / Active | `primary600` | `#EA580C` |
| Disabled | `slate300` | `#CBD5E1` |
| On-primary (text di atas bg orange) | `Colors.white` | `#FFFFFF` |
| Error text | `danger600` | `#DC2626` |

---

## 4. Spacing & Layout

### 4.1 Spacing Scale

```dart
// Base unit: 4px
static const double space2  = 2;   // micro (2px)
static const double space4  = 4;   // xxs
static const double space6  = 6;   // xs
static const double space8  = 8;   // sm
static const double space10 = 10;  // sm+
static const double space12 = 12;  // md-
static const double space16 = 16;  // md  (page padding)
static const double space20 = 20;  // md+
static const double space24 = 24;  // lg  (section spacing)
static const double space32 = 32;  // xl
static const double space40 = 40;  // 2xl
static const double space48 = 48;  // 3xl
```

### 4.2 Screen Padding

```dart
// Page content padding
EdgeInsets pagePadding = EdgeInsets.all(16); // 16px semua sisi

// Card internal padding
EdgeInsets cardPadding = EdgeInsets.all(20); // 20px (5 unit * 4)

// Section gap di dalam page
double sectionGap = 24; // gap antar section card
```

### 4.3 Grid

- List items: **full-width** per baris
- Stat cards pada dashboard: **2 kolom** (mobile), **3 kolom** (tablet)
- Grid gap: **16px**

---

## 5. Component Specs

### 5.1 Card

```dart
// Standard Card
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),  // rounded-xl
    border: Border.all(color: slate200),       // border 1px
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  ),
)
```

| Properti | Nilai |
|:---------|:------|
| Border radius | 12dp (`rounded-xl`) |
| Border | 1px `slate200` |
| Shadow | Halus, `0 2px 6px rgba(0,0,0,0.04)` |
| Header padding | `20dp horizontal, 14dp vertical` |
| Body padding | `20dp` semua sisi |
| Header border | Bottom 1px `slate100` |

### 5.2 Button

| Variant | Background | Text | Border | Shadow |
|:--------|:-----------|:-----|:-------|:-------|
| **primary** | `primary600` | White | — | `0 1px 3px orange-600/20` |
| **secondary** | `slate100` | `slate700` | — | — |
| **outline** | Transparent | `slate600` | 1px `slate200` | — |
| **ghost** | Transparent | `slate500` | — | — |
| **danger** | `danger600` | White | — | Subtle |
| **success** | `success600` | White | — | Subtle |

```dart
// Button sizing
Size sm = Size(height: 36, paddingH: 12, fontSize: 13);
Size md = Size(height: 40, paddingH: 16, fontSize: 14);
Size lg = Size(height: 48, paddingH: 20, fontSize: 16);

// Border radius: 8dp (rounded-lg)
// Loading state: opacity 0.6 + CircularProgressIndicator
```

### 5.3 Badge

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
    color: /* variant bg — misal success50 */,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: /* variant ring */),
  ),
  child: Text(label, style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: /* variant text color */,
  )),
)
```

| Variant | Background | Text | Ring/Border |
|:--------|:-----------|:-----|:------------|
| default | `slate50` | `slate600` | `slate200` |
| success | `success50` | `success700` | `success-200` |
| warning | `warning50` | `warning700` | `warning-200` |
| danger | `danger50` | `danger700` | `danger-200` |
| info | `info50` | `info700` | `info-200` |
| orange | `primary50` | `primary700` | `primary-200` |
| purple | `purple50` | `purple700` | `purple-200` |

### 5.4 Stat Card

```
┌─────────────────────────────────┐
│  LABEL (uppercase, 10px)    📊  │ ← emoji di rounded square bg
│  42                             │ ← value (24px, bold)
│  Subtitle text                  │ ← optional (12px, slate400)
│▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬│ ← accent bar (2px height)
└─────────────────────────────────┘
```

- Border: 1px `{color}100`
- Icon bg: `{color}50` with `{color}600` icon
- Accent bar: `{color}500` → `{color}600` on hover
- Color options: orange, blue, green, purple, yellow, rose

### 5.5 Bottom Navigation Bar

```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.white,
  selectedItemColor: primary600,
  unselectedItemColor: slate400,
  selectedFontSize: 11,
  unselectedFontSize: 11,
  elevation: 8,
  // Use outlined icons for unselected, filled for selected
)
```

### 5.6 AppBar / Top Bar

```dart
AppBar(
  backgroundColor: Colors.white.withOpacity(0.8),
  elevation: 0,
  scrolledUnderElevation: 0.5,
  title: Text(title, style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: slate700,
  )),
  // Glassmorphism effect: backdrop-blur + semi-transparent bg
)
```

### 5.7 Form Input

```dart
TextFormField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: slate200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primary500, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: danger500),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    labelStyle: TextStyle(fontSize: 14, color: slate400),
  ),
)
```

### 5.8 Empty State

```
     ┌──── dashed border container ────┐
     │                                  │
     │         🏖️ (emoji 32px)         │
     │                                  │
     │    Tidak ada data               │ ← bold, slate900
     │    Subtitle text here           │ ← normal, slate500
     │                                  │
     └──────────────────────────────────┘
```

- Container: dashed border 2px `slate300`
- Centered content, padding 32px vertical

### 5.9 Toast / Snackbar

| Type | Background | Icon | Text |
|:-----|:-----------|:-----|:-----|
| success | `success50` | ✅ Green checkmark | `success700` |
| error | `danger50` | ❌ Red exclamation | `danger700` |
| info | `info50` | ℹ️ Blue info | `info700` |

- Position: top of screen
- Duration: 3 seconds auto-dismiss
- Border radius: 12dp
- Shadow: medium

### 5.10 Modal / Bottom Sheet

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  // Handle indicator: center, 32x4dp, slate300, rounded
  // Overlay: slate900/40 with backdrop-blur
)
```

---

## 6. Iconography

### 6.1 Icon Style
- **Library**: Gunakan `heroicons_flutter` atau `lucide_icons` (outline style by default)
- **Stroke width**: 1.8px (konsisten dengan web)
- **Size default**: 20dp untuk navigasi, 24dp untuk toolbar
- **Active color**: `primary600`
- **Inactive color**: `slate400`

### 6.2 Icon Mapping

| Fitur | Icon | Section |
|:------|:-----|:--------|
| Dashboard | `Squares2x2` (grid) | Nav |
| Siswa | `UserGroup` | Nav |
| Guru & Staff | `Users` | Nav |
| Nilai | `ClipboardCheck` | Nav |
| Rapor | `DocumentText` | Nav |
| Kelas | `BuildingOffice` | Nav |
| Mata Pelajaran | `BookOpen` | Nav |
| Penugasan | `ClipboardList` | Nav |
| Absensi | `CalendarDays` | Nav |
| Jadwal | `Clock` | Nav |
| Pengumuman | `Megaphone` | Nav |
| Profil | `UserCircle` | Nav |
| Notifikasi | `Bell` | TopBar |
| Logout | `ArrowRightOnRectangle` | Menu |

---

## 7. Animation & Motion

### 7.1 Durations

| Type | Duration | Curve |
|:-----|:---------|:------|
| Fade in/out | 150ms | `Curves.easeOut` |
| Slide transition | 200ms | `Curves.easeInOut` |
| Page transition | 300ms | `Curves.easeInOutCubic` |
| Bottom sheet | 250ms | `Curves.fastOutSlowIn` |
| Toast enter | 100ms | `Curves.easeOut` |
| Toast exit | 75ms | `Curves.easeIn` |

### 7.2 Page Transitions

- **Tab switch**: Fade + subtle horizontal slide
- **Push navigation**: Material slide from right
- **Bottom sheet**: Slide up from bottom
- **Modal**: Scale from 0.95 → 1.0 + fade

### 7.3 Micro-animations

- **Stat card hover**: Translate Y -2dp (elevasi)
- **Active nav indicator**: Left bar 6dp height × 4px width, rounded-r, `primary500`
- **Loading**: `CircularProgressIndicator` with `primary500` color
- **Skeleton loading**: Shimmer effect `slate100` → `slate200` → `slate100`
- **Pull to refresh**: Standard Material PTR with `primary500` indicator

---

## 8. Dark Mode (Optional — Phase 2)

| Element | Light | Dark |
|:--------|:------|:-----|
| Page bg | `slate50` → white gradient | `zinc-950` (`#09090B`) |
| Card bg | White | `zinc-900` (`#18181B`) |
| Card border | `slate200` | `zinc-800` (`#27272A`) |
| Heading text | `slate800` | `slate100` |
| Body text | `slate600` | `slate300` |
| Primary | `primary500` | `primary400` (sedikit lebih terang) |
| Bottom nav | White | `zinc-900` |

> [!NOTE]
> Dark mode bersifat **opsional** dan dijadwalkan di Phase 2. Prioritas awal semua light mode.

---

## 9. Responsive Breakpoints

| Device | Width | Layout |
|:-------|:------|:-------|
| Small phone | < 360dp | Single column, compact |
| Phone (target) | 360-428dp | Single column, standard |
| Large phone | 428-600dp | Slightly wider cards |
| Tablet (portrait) | 600-840dp | 2-column grid |
| Tablet (landscape) | > 840dp | 2-3 column, sidebar nav |

---

## 10. Logo Spec (App Icon)

```
┌──────────────────────┐
│    ╭──────────────╮   │
│    │              │   │
│    │    F         │   │ ← White "F" bold,
│    │              │   │   centered
│    ╰──────────────╯   │
│   Gradient bg:        │
│   orange-500 →        │
│   orange-600          │
│   Corner radius: 22%  │
└──────────────────────┘

Size: 1024×1024 (source)
Foreground: White "F" (Space Grotesk Bold)
Background: Linear gradient top-left to bottom-right
  from #F97316 (orange-500) to #EA580C (orange-600)
Shadow: subtle drop shadow rgba(249,115,22,0.2)
```

---

## 11. Do's and Don'ts

### ✅ DO
- Gunakan `rounded-xl` (12dp) untuk card dan container utama
- Gunakan `rounded-lg` (8dp) untuk button dan input
- Gunakan Inter sebagai font utama untuk semua teks
- Gunakan Space Grotesk HANYA untuk logo/brand text
- Gunakan orange sebagai accent warna utama
- Berikan shadow halus (subtle) — jangan dramatic
- Berikan border 1px slate-200 pada card
- Gunakan gradien orange-to-amber untuk header/banner
- Tampilkan empty state yang informatif dengan emoji
- Gunakan uppercase + letter-spacing untuk label stat

### ❌ DON'T
- Jangan gunakan plain red/blue/green sebagai primary color
- Jangan gunakan shadow yang terlalu tebal/gelap
- Jangan gunakan font selain Inter untuk body text
- Jangan ubah warna primary dari orange ke warna lain
- Jangan gunakan border-radius > 16dp (kecuali circular)
- Jangan letakkan terlalu banyak informasi dalam satu card
- Jangan gunakan pure black (`#000000`) untuk teks — use slate variants
- Jangan abaikan spacing/padding — konsistensi adalah kunci
