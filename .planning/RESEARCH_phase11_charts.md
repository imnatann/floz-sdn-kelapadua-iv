# Phase 11 Chart Library Choice

_Diteliti: 2026-05-09 | Stack: Vue 3 + Inertia.js + Vite + Tailwind CSS_

## Comparison Matrix

| Library | Gzip Bundle (total) | Vue 3 wrapper | Maturity | Theming | A11y | License |
|---------|---------------------|---------------|----------|---------|------|---------|
| **chart.js v4.5** + vue-chartjs v5.3 | **~71 KB** | vue-chartjs (official) | Sangat matang (2013, v4 stable) | CSS vars + config object | ARIA labels via plugin | MIT |
| **apexcharts v5.11** + vue3-apexcharts v1.11 | ~138 KB | vue3-apexcharts (official) | Matang (2018, aktif) | Theme object + CSS vars | Built-in title/desc | MIT |
| **echarts v6.0** + vue-echarts v8.0 | ~110 KB (tree-shaken) | vue-echarts (official) | Sangat matang (Apache, 2013) | Option API penuh | Terbatas | Apache 2.0 |
| **D3 v7** (native SVG) | ~80 KB | Tidak ada (manual) | Sangat matang tapi low-level | Penuh (kode sendiri) | Manual | ISC |

> Gzip chart.js = 68 KB + 3 KB wrapper. ApexCharts = 135 KB + 3 KB. ECharts tree-shaken untuk 4 chart type ~100 KB + 10 KB wrapper. D3 full build ~80 KB tapi perlu kode lebih banyak.

> npm downloads/minggu (Mei 2026): chart.js 10.6 jt | echarts 2.5 jt | apexcharts 1.7 jt | vue-chartjs 779 rb | vue-echarts 242 rb | vue3-apexcharts 256 rb.

## Compatibility (Vite / Inertia / Tailwind)

| Library | Vite | Inertia SSR | Tailwind |
|---------|------|-------------|----------|
| chart.js + vue-chartjs | Bersih — ESM native, zero config | Wajib `{ ssr: false }` (canvas tidak ada di Node) | Warna Tailwind bisa dipetakan manual ke dataset colors |
| apexcharts + vue3-apexcharts | Bersih — ESM, Vite-friendly | Wajib `{ ssr: false }` (window/document access) | Sama seperti di atas |
| echarts + vue-echarts | Bersih — tree-shakeable ESM di v6 | Wajib `{ ssr: false }` (canvas/DOM) | Sama |
| D3 | Bersih | Bisa SSR sebagian (JSDOM), tapi kompleks | Manual 100% |

**Catatan SSR Inertia:** Semua canvas/SVG library butuh `defineAsyncComponent` + `{ ssr: false }` atau kondisi `onMounted`. Ini standar, bukan hambatan nyata.

Tidak ada library yang memerlukan perubahan `vite.config.js` — plugin Vue sudah cukup.

## Print-Friendliness

| Library | Render | Print / PDF |
|---------|--------|-------------|
| chart.js | Canvas | Canvas tercetak baik di Chrome (`@media print`). Gunakan `canvas.toDataURL()` untuk export PNG manual. Tidak ada SVG fallback. |
| apexcharts | SVG | SVG langsung di-print — resolusi tinggi, tajam di PDF. Ada API `exportToSVG()` dan `dataURI()` bawaan. **Terbaik untuk print.** |
| echarts | Canvas (default) atau SVG | Bisa set `renderer: 'svg'` — lalu print setara ApexCharts. Perlu satu baris config tambahan. |
| D3 | SVG | SVG native, print sempurna. Tapi butuh CSS `@media print` manual. |

**Kesimpulan print:** ApexCharts SVG-first paling mudah. ECharts dengan SVG renderer setara. Chart.js (canvas) perlu workaround.

## Recommendation: ApexCharts + vue3-apexcharts

ApexCharts dipilih karena empat alasan kunci untuk kebutuhan FLOZ LMS Phase 11:

1. **Print-first by default** — SVG renderer menghasilkan laporan PDF/print tajam tanpa workaround canvas; admin yang cetak laporan bulanan mendapat hasil langsung bagus.
2. **Beautiful out-of-box** — Default theme responsif dan profesional cocok untuk dashboard sekolah tanpa perlu banyak kustomisasi Tailwind-ke-chart.
3. **API sederhana, cukup powerful** — Mendukung semua 4 chart type yang dibutuhkan (bar horizontal, line, doughnut, stacked bar) dengan konfigurasi deklaratif yang mudah dipahami tim kecil.
4. **Bundle 138 KB gzip wajar** — Lebih besar dari Chart.js (71 KB) tapi masih layak untuk admin dashboard yang tidak diakses publik; tradeoff bundle vs fitur print+theming sepadan.
5. **Vite + Vue 3 terintegrasi mulus** — `vue3-apexcharts` adalah wrapper resmi, aktif dirawat, zero Vite config tambahan.

## Fallback

Jika ApexCharts bermasalah (misal konflik dependency atau performa lambat di tablet):
- Ganti ke **chart.js + vue-chartjs** — bundle terkecil (71 KB), API paling sederhana, ekosistem terbesar (10.6 jt download/minggu).
- Untuk print di Chart.js: tambahkan hook `@media print` yang capture `canvas.toDataURL()` dan ganti dengan `<img>` — implementasi ~20 baris.
- ECharts + SVG renderer adalah opsi ketiga jika butuh fleksibilitas maksimal.

## Suggested Charts Mapped to Lib API

| Widget | Chart type | ApexCharts component | Chart.js fallback |
|--------|------------|----------------------|-------------------|
| Perbandingan rata-rata kelas | Horizontal bar | `<apexchart type="bar" :options="{plotOptions:{bar:{horizontal:true}}}">` | `Bar` (horizontal via indexAxis) |
| Tren kehadiran bulanan | Line | `<apexchart type="line">` | `Line` |
| Distribusi nilai | Doughnut | `<apexchart type="donut">` | `Doughnut` |
| Kehadiran stacked (hadir/izin/alpa) | Stacked bar | `<apexchart type="bar" :options="{chart:{stacked:true}}">` | `Bar` (stacked via datasets) |

## Install

```bash
# ApexCharts (pilihan utama)
npm install apexcharts vue3-apexcharts

# Fallback — Chart.js
npm install chart.js vue-chartjs
```

**Vite wiring:** Tidak perlu ubah `vite.config.js`. Daftarkan sebagai komponen lokal di setiap Vue SFC atau global di `app.js`:

```js
// app.js (opsional global registration)
import VueApexCharts from 'vue3-apexcharts'
createApp(App).use(VueApexCharts)

// Atau lazy per-component (direkomendasikan untuk Inertia):
const ApexChart = defineAsyncComponent(() => import('vue3-apexcharts'))
```
