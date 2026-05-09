<script setup>
import { ref, computed } from 'vue';
import { router, usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import BaseChart from '@/Components/Charts/BaseChart.vue';

defineOptions({ layout: AppLayout });

const page = usePage();
const isAdmin = computed(() => page.props.auth?.permissions?.manage_analytics === true);

const props = defineProps({
  todaysAttendance: { type: Object, default: () => null },
  classAvgComparison: { type: Object, default: () => null },
  classesMissingAttendance: { type: Array, default: () => [] },
  topClass: { type: Object, default: () => null },
  atRiskClass: { type: Object, default: () => null },
});

const refreshing = ref(false);

const refresh = () => {
  refreshing.value = true;
  router.reload({ onFinish: () => { refreshing.value = false; } });
};

// Normalize backend wrapper: backend returns {data: {...}, meta: {...}}
const todays = computed(() => {
  const raw = props.todaysAttendance?.data ?? props.todaysAttendance ?? null;
  if (!raw) return null;
  // Map English snake_case from backend to Indonesian aliases used in template
  const present = raw.present ?? raw.hadir ?? 0;
  const sick = raw.sick ?? raw.sakit ?? 0;
  const permit = raw.permit ?? raw.izin ?? 0;
  const absent = raw.absent ?? raw.alpha ?? 0;
  const percentage = raw.percentage ?? raw.attendance_rate ?? 0;
  const total = raw.total ?? (present + sick + permit + absent);
  return { hadir: present, sakit: sick, izin: permit, alpha: absent, total, percentage };
});

const comparison = computed(() => {
  const list = props.classAvgComparison?.data ?? props.classAvgComparison ?? [];
  return Array.isArray(list) ? list.map(d => ({
    class_id: d.class_id,
    class_name: d.class_name,
    // Backend may return either avg (grade) or avg_percent (attendance)
    avg: d.avg_percent ?? d.avg ?? 0,
  })) : [];
});

const missingClasses = computed(() => {
  const raw = props.classesMissingAttendance ?? props.missingAttendance?.data ?? props.missingAttendance ?? [];
  return Array.isArray(raw) ? raw : [];
});

// Derive topClass/atRiskClass from comparison if backend didn't provide explicit ones
const topClassDerived = computed(() => {
  if (props.topClass) return props.topClass;
  if (comparison.value.length === 0) return null;
  const top = [...comparison.value].sort((a, b) => b.avg - a.avg)[0];
  return top ? { name: top.class_name, avg_percent: top.avg } : null;
});
const atRiskClassDerived = computed(() => {
  if (props.atRiskClass) return props.atRiskClass;
  if (comparison.value.length === 0) return null;
  const bottom = [...comparison.value].sort((a, b) => a.avg - b.avg)[0];
  return bottom ? { name: bottom.class_name, avg_percent: bottom.avg } : null;
});

// W1: Attendance gauge data
const attendanceSeries = computed(() => {
  const a = todays.value;
  if (!a) return [];
  return [a.hadir, a.sakit, a.izin, a.alpha];
});

const attendanceOptions = computed(() => ({
  labels: ['Hadir', 'Sakit', 'Izin', 'Alpha'],
  colors: ['#22c55e', '#3b82f6', '#f59e0b', '#ef4444'],
  legend: { position: 'bottom' },
  plotOptions: {
    pie: {
      donut: {
        size: '65%',
        labels: {
          show: true,
          total: {
            show: true,
            label: 'Total Siswa',
            fontSize: '13px',
            color: '#64748b',
            formatter: () => todays.value?.total ?? 0,
          },
        },
      },
    },
  },
}));

const attendancePercent = computed(() => {
  const a = todays.value;
  if (!a) return 0;
  if (a.percentage) return Math.round(a.percentage);
  if (!a.total) return 0;
  return Math.round((a.hadir / a.total) * 100);
});

// W3: Class avg comparison horizontal bar
const comparisonSeries = computed(() => {
  if (comparison.value.length === 0) return [];
  return [{ name: 'Rata-rata', data: comparison.value.map(d => d.avg) }];
});

const comparisonOptions = computed(() => ({
  chart: { type: 'bar' },
  plotOptions: { bar: { horizontal: true, borderRadius: 4 } },
  xaxis: {
    categories: comparison.value.map(d => d.class_name),
  },
  dataLabels: { enabled: true, formatter: (v) => Number(v).toFixed(1) },
  colors: ['#f97316'],
}));

const hasMissingAttendance = computed(() => missingClasses.value.length > 0);
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Dasbor Analitik</h2>
        <p class="mt-0.5 text-sm text-slate-400">
          {{ isAdmin ? 'Ringkasan seluruh sekolah' : 'Menampilkan kelas yang Anda ampu' }}
        </p>
      </div>
      <Button variant="secondary" size="sm" :disabled="refreshing" @click="refresh">
        <svg
          :class="['h-4 w-4 mr-1.5', refreshing && 'animate-spin']"
          fill="none" stroke="currentColor" viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
        </svg>
        {{ refreshing ? 'Memuat...' : 'Segarkan' }}
      </Button>
    </div>

    <!-- 2-col grid -->
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">

      <!-- W1: Today's Attendance -->
      <Card title="Kehadiran Hari Ini" subtitle="Rekap absensi seluruh kelas">
        <div v-if="todays">
          <!-- Big stat -->
          <div class="mb-4 flex items-center gap-4">
            <div class="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-orange-50">
              <span class="text-2xl font-bold text-orange-600">{{ attendancePercent }}%</span>
            </div>
            <div>
              <p class="text-sm font-medium text-slate-700">Tingkat Kehadiran</p>
              <p class="text-xs text-slate-400">{{ todays?.total ?? 0 }} siswa terdaftar</p>
            </div>
          </div>

          <!-- H/S/I/A breakdown -->
          <div class="mb-4 grid grid-cols-4 gap-2">
            <div class="rounded-lg bg-green-50 p-3 text-center">
              <p class="text-lg font-bold text-green-600">{{ todays?.hadir ?? 0 }}</p>
              <p class="text-xs text-green-500">Hadir</p>
            </div>
            <div class="rounded-lg bg-blue-50 p-3 text-center">
              <p class="text-lg font-bold text-blue-600">{{ todays?.sakit ?? 0 }}</p>
              <p class="text-xs text-blue-500">Sakit</p>
            </div>
            <div class="rounded-lg bg-amber-50 p-3 text-center">
              <p class="text-lg font-bold text-amber-600">{{ todays?.izin ?? 0 }}</p>
              <p class="text-xs text-amber-500">Izin</p>
            </div>
            <div class="rounded-lg bg-red-50 p-3 text-center">
              <p class="text-lg font-bold text-red-600">{{ todays?.alpha ?? 0 }}</p>
              <p class="text-xs text-red-500">Alpha</p>
            </div>
          </div>

          <!-- Donut chart -->
          <BaseChart
            v-if="attendanceSeries.length"
            type="donut"
            :series="attendanceSeries"
            :options="attendanceOptions"
            :height="220"
          />
        </div>
        <div v-else class="flex flex-col items-center justify-center py-12 text-center">
          <svg class="h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
          </svg>
          <p class="mt-2 text-sm text-slate-400">Belum ada data absensi hari ini.</p>
        </div>
      </Card>

      <!-- W2: Missing Attendance Alert (admin only) -->
      <Card v-if="isAdmin" title="Status Absensi Kelas" subtitle="Kelas yang belum mengisi absensi hari ini">
        <div v-if="hasMissingAttendance">
          <div class="mb-3 flex items-center gap-2">
            <span class="flex h-6 w-6 items-center justify-center rounded-full bg-red-100">
              <svg class="h-3.5 w-3.5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
            </span>
            <span class="text-sm font-medium text-red-700">
              {{ classesMissingAttendance.length }} kelas belum isi absensi
            </span>
          </div>
          <ul class="space-y-2 max-h-64 overflow-y-auto">
            <li
              v-for="cls in classesMissingAttendance"
              :key="cls.id ?? cls.name"
              class="flex items-center justify-between rounded-lg border border-red-100 bg-red-50/60 px-3 py-2"
            >
              <span class="text-sm font-medium text-slate-700">{{ cls.name }}</span>
              <Badge variant="danger" size="sm">Belum</Badge>
            </li>
          </ul>
        </div>
        <div v-else class="flex flex-col items-center justify-center py-12 text-center">
          <span class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
            <svg class="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
          </span>
          <p class="mt-3 text-sm font-medium text-green-700">Semua kelas sudah mengisi absensi!</p>
          <p class="mt-1 text-xs text-slate-400">Tidak ada kelas yang tertinggal.</p>
        </div>
      </Card>

      <!-- W3: Class Avg Comparison -->
      <Card title="Perbandingan Rata-rata Kehadiran" subtitle="Rata-rata kehadiran per kelas semester ini">
        <div v-if="comparison.length">
          <BaseChart
            type="bar"
            :series="comparisonSeries"
            :options="comparisonOptions"
            :height="300"
          />
          <p v-if="classAvgComparison?.meta?.note" class="mt-2 text-xs text-slate-400 text-center">
            {{ classAvgComparison.meta.note }}
          </p>
        </div>
        <div v-else class="flex flex-col items-center justify-center py-12 text-center">
          <svg class="h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
          </svg>
          <p class="mt-2 text-sm text-slate-400">Belum ada data perbandingan kelas.</p>
        </div>
      </Card>

      <!-- W8: Top + At-risk Class (admin only) -->
      <Card v-if="isAdmin" title="Performa Kelas" subtitle="Kelas terbaik dan kelas berisiko">
        <div class="space-y-4">
          <!-- Top class -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Kelas Terbaik</p>
            <div v-if="topClassDerived" class="flex items-center gap-3 rounded-xl border border-green-100 bg-green-50 p-4">
              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-green-100">
                <svg class="h-5 w-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/>
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-800">{{ topClassDerived.name }}</p>
                <p class="text-xs text-slate-500">
                  Kehadiran: <span class="font-medium text-green-600">{{ Number(topClassDerived.avg_percent ?? 0).toFixed(1) }}</span>
                </p>
              </div>
              <Badge variant="success" size="sm">Terbaik</Badge>
            </div>
            <div v-else class="rounded-xl border border-slate-100 bg-slate-50 p-4 text-center">
              <p class="text-xs text-slate-400">Belum ada data.</p>
            </div>
          </div>

          <!-- At-risk class -->
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Kelas Berisiko</p>
            <div v-if="atRiskClassDerived" class="flex items-center gap-3 rounded-xl border border-red-100 bg-red-50 p-4">
              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-100">
                <svg class="h-5 w-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-800">{{ atRiskClassDerived.name }}</p>
                <p class="text-xs text-slate-500">
                  Kehadiran: <span class="font-medium text-red-600">{{ Number(atRiskClassDerived.avg_percent ?? 0).toFixed(1) }}</span>
                </p>
              </div>
              <Badge variant="danger" size="sm">Berisiko</Badge>
            </div>
            <div v-else class="rounded-xl border border-slate-100 bg-slate-50 p-4 text-center">
              <p class="text-xs text-slate-400">Belum ada data.</p>
            </div>
          </div>
        </div>
      </Card>

    </div>
  </div>
</template>
