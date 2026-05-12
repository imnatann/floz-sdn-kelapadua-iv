<script setup>
import { ref, reactive, computed, watch } from 'vue';
import axios from 'axios';
import { usePage } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import BaseChart from '@/Components/Charts/BaseChart.vue';

defineOptions({ layout: AppLayout });

const page = usePage();
const isAdmin = computed(() => page.props.auth?.permissions?.manage_analytics === true);

const props = defineProps({
  classes: { type: Array, default: () => [] },
  semesters: { type: Array, default: () => [] },
  subjects: { type: Array, default: () => [] },
  defaultFilters: { type: Object, default: () => ({}) },
});

// Filters
const filters = reactive({
  class_id: props.defaultFilters?.class_id ?? '',
  semester_id: props.defaultFilters?.semester_id ?? '',
  subject_id: props.defaultFilters?.subject_id ?? '',
});

// Widget data
const widgets = reactive({
  w4: { data: null, meta: null, loading: false },
  w5: { data: null, meta: null, loading: false },
  w6: { data: null, meta: null, loading: false },
  w7: { data: null, meta: null, loading: false },
});

// W6 pagination
const w6Page = ref(1);

// W7 sort
const w7Sort = reactive({ key: 'teacher_name', dir: 'asc' });

// Fetch widget data
const fetchWidget = async (widget) => {
  widgets[widget].loading = true;
  try {
    const { data } = await axios.get(`/analytics/data/${widget}`, {
      params: {
        class_id: filters.class_id || undefined,
        semester_id: filters.semester_id || undefined,
        subject_id: filters.subject_id || undefined,
      },
    });
    widgets[widget].data = data.data;
    widgets[widget].meta = data.meta;
  } catch (e) {
    widgets[widget].data = null;
    widgets[widget].meta = null;
  } finally {
    widgets[widget].loading = false;
  }
};

const fetchAll = () => {
  fetchWidget('w4');
  fetchWidget('w5');
  fetchWidget('w6');
  fetchWidget('w7');
};

// Trigger on mount + filter changes
fetchAll();

watch(filters, () => {
  w6Page.value = 1;
  fetchAll();
}, { deep: true });

// Export Excel (Kehadiran)
const exporting = ref(false);
const exportExcel = () => {
  const params = new URLSearchParams();
  if (filters.semester_id) params.append('semester_id', filters.semester_id);
  if (filters.class_id) params.append('class_id', filters.class_id);
  window.location.href = `/analytics/export/attendance?${params.toString()}`;
};

// Export Nilai
const exportingGrades = ref(false);
const exportGrades = () => {
  const params = new URLSearchParams();
  if (filters.semester_id) params.append('semester_id', filters.semester_id);
  if (filters.class_id) params.append('class_id', filters.class_id);
  if (filters.subject_id) params.append('subject_id', filters.subject_id);
  window.location.href = `/analytics/export/grades?${params.toString()}`;
};

// W4: Grade distribution stacked bar
const w4Series = computed(() => {
  if (!widgets.w4.data) return [];
  const grades = ['A', 'B', 'C', 'D'];
  return grades.map(g => ({
    name: `Nilai ${g}`,
    data: widgets.w4.data.map(d => d[`grade_${g.toLowerCase()}`] ?? d[g] ?? 0),
  }));
});

const w4Options = computed(() => ({
  chart: { type: 'bar', stacked: true },
  plotOptions: { bar: { borderRadius: 2 } },
  colors: ['#22c55e', '#3b82f6', '#f59e0b', '#ef4444'],
  xaxis: { categories: widgets.w4.data?.map(d => d.class_name) ?? [] },
  dataLabels: { enabled: false },
  legend: { position: 'bottom' },
}));

// W5: Attendance trend line
const w5Series = computed(() => {
  if (!widgets.w5.data) return [];
  return [{
    name: 'Kehadiran (%)',
    data: widgets.w5.data.map(d => d.percent ?? d.value ?? 0),
  }];
});

const w5Options = computed(() => ({
  chart: { type: 'area' },
  colors: ['#f97316'],
  fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.3, opacityTo: 0.05 } },
  stroke: { curve: 'smooth', width: 2 },
  xaxis: {
    categories: widgets.w5.data?.map(d => d.week_label ?? d.label) ?? [],
  },
  yaxis: { min: 0, max: 100, labels: { formatter: (v) => `${v}%` } },
  dataLabels: { enabled: false },
}));

// W6 sorted + paginated data
const w6PerPage = 10;
const w6Sorted = computed(() => (widgets.w6.data ?? []).slice().sort((a, b) => {
  const fieldA = a.student_name ?? '';
  const fieldB = b.student_name ?? '';
  return fieldA.localeCompare(fieldB);
}));
const w6Paginated = computed(() => {
  const start = (w6Page.value - 1) * w6PerPage;
  return w6Sorted.value.slice(start, start + w6PerPage);
});
const w6TotalPages = computed(() => Math.ceil((w6Sorted.value.length) / w6PerPage));

// W7 sorted data
const w7Sorted = computed(() => {
  if (!widgets.w7.data) return [];
  return [...widgets.w7.data].sort((a, b) => {
    const va = a[w7Sort.key] ?? '';
    const vb = b[w7Sort.key] ?? '';
    const cmp = typeof va === 'string' ? va.localeCompare(vb) : (va - vb);
    return w7Sort.dir === 'asc' ? cmp : -cmp;
  });
});

const w7Totals = computed(() => {
  if (!widgets.w7.data?.length) return null;
  return {
    ta_count: widgets.w7.data.reduce((s, r) => s + (r.ta_count ?? 0), 0),
    hours_per_week: widgets.w7.data.reduce((s, r) => s + (r.hours_per_week ?? 0), 0),
  };
});

const sortW7 = (key) => {
  if (w7Sort.key === key) {
    w7Sort.dir = w7Sort.dir === 'asc' ? 'desc' : 'asc';
  } else {
    w7Sort.key = key;
    w7Sort.dir = 'asc';
  }
};

const w7SortIcon = (key) => {
  if (w7Sort.key !== key) return '↕';
  return w7Sort.dir === 'asc' ? '↑' : '↓';
};

// Select options
const classOptions = computed(() => [
  { value: '', label: 'Semua Kelas' },
  ...props.classes.map(c => ({ value: c.id, label: c.name })),
]);
const semesterOptions = computed(() => [
  { value: '', label: 'Semua Semester' },
  ...props.semesters.map(s => ({ value: s.id, label: s.name })),
]);
const subjectOptions = computed(() => [
  { value: '', label: 'Semua Mata Pelajaran' },
  ...props.subjects.map(s => ({ value: s.id, label: s.name })),
]);
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Laporan Analitik</h2>
        <p class="mt-0.5 text-sm text-slate-400">Analisis nilai, kehadiran, dan beban kerja guru</p>
      </div>
      <div class="flex flex-col items-end gap-1">
        <div class="flex gap-2">
          <Button variant="secondary" size="sm" :disabled="exporting" @click="exportExcel">
            <svg class="h-4 w-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
            </svg>
            Export Kehadiran
          </Button>
          <Button variant="primary" size="sm" :disabled="exportingGrades" @click="exportGrades">
            <svg class="h-4 w-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
            </svg>
            Export Nilai
          </Button>
        </div>
        <span v-if="!isAdmin" class="text-[10px] text-slate-400">Hanya kelas yang Anda ampu</span>
      </div>
    </div>

    <!-- Filter Panel -->
    <Card>
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Kelas</label>
          <FormSelect v-model="filters.class_id" :options="classOptions" />
        </div>
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Semester</label>
          <FormSelect v-model="filters.semester_id" :options="semesterOptions" />
        </div>
        <div>
          <label class="mb-1 block text-xs font-medium text-slate-600">Mata Pelajaran</label>
          <FormSelect v-model="filters.subject_id" :options="subjectOptions" />
        </div>
      </div>
    </Card>

    <!-- W4: Subject Grade Distribution -->
    <Card title="W4 — Distribusi Nilai per Kelas" subtitle="Distribusi nilai A/B/C/D berdasarkan mata pelajaran">
      <BaseChart
        v-if="!widgets.w4.loading && w4Series.length"
        type="bar"
        :series="w4Series"
        :options="w4Options"
        :height="300"
      />
      <div v-else-if="widgets.w4.loading" class="animate-pulse h-[300px] rounded-xl bg-slate-100" />
      <div v-else class="flex flex-col items-center justify-center py-12 text-center">
        <svg class="h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
        </svg>
        <p class="mt-2 text-sm text-slate-400">Belum ada data nilai. Pilih filter untuk menampilkan data.</p>
      </div>
    </Card>

    <!-- W5: Attendance Trend -->
    <Card title="W5 — Tren Kehadiran" subtitle="Persentase kehadiran 12 minggu terakhir">
      <BaseChart
        v-if="!widgets.w5.loading && w5Series.length"
        type="area"
        :series="w5Series"
        :options="w5Options"
        :height="280"
      />
      <div v-else-if="widgets.w5.loading" class="animate-pulse h-[280px] rounded-xl bg-slate-100" />
      <div v-else class="flex flex-col items-center justify-center py-12 text-center">
        <svg class="h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z"/>
        </svg>
        <p class="mt-2 text-sm text-slate-400">Belum ada data tren kehadiran.</p>
      </div>
    </Card>

    <!-- W6: At-risk Students Table -->
    <Card title="W6 — Siswa Berisiko" subtitle="Siswa dengan kehadiran di bawah batas minimum">
      <div v-if="widgets.w6.loading" class="space-y-2">
        <div v-for="i in 5" :key="i" class="animate-pulse h-10 rounded-lg bg-slate-100" />
      </div>
      <div v-else-if="w6Sorted.length">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-slate-100 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                <th class="py-3 pr-4">Nama Siswa</th>
                <th class="py-3 pr-4">Kelas</th>
                <th class="py-3 pr-4">Kehadiran</th>
                <th class="py-3">Status</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
              <tr v-for="student in w6Paginated" :key="student.student_id ?? student.id">
                <td class="py-3 pr-4 font-medium text-slate-800">{{ student.student_name }}</td>
                <td class="py-3 pr-4 text-slate-500">{{ student.class_name ?? '-' }}</td>
                <td class="py-3 pr-4">
                  <div class="flex items-center gap-2">
                    <div class="h-1.5 w-24 overflow-hidden rounded-full bg-slate-100">
                      <div
                        class="h-full rounded-full bg-red-500"
                        :style="`width: ${Math.min(student.attendance_percent ?? 0, 100)}%`"
                      />
                    </div>
                    <span class="text-xs font-medium text-red-600">{{ student.attendance_percent ?? 0 }}%</span>
                  </div>
                </td>
                <td class="py-3">
                  <Badge variant="danger" size="sm">Berisiko</Badge>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Simple pagination -->
        <div v-if="w6TotalPages > 1" class="mt-4 flex items-center justify-center gap-1">
          <button
            :disabled="w6Page <= 1"
            class="rounded-lg px-3 py-1.5 text-xs font-medium border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            @click="w6Page--"
          >
            &lsaquo; Sebelumnya
          </button>
          <span class="px-3 text-xs text-slate-500">{{ w6Page }} / {{ w6TotalPages }}</span>
          <button
            :disabled="w6Page >= w6TotalPages"
            class="rounded-lg px-3 py-1.5 text-xs font-medium border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            @click="w6Page++"
          >
            Berikutnya &rsaquo;
          </button>
        </div>
      </div>
      <div v-else class="flex flex-col items-center justify-center py-12 text-center">
        <svg class="h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        <p class="mt-2 text-sm text-slate-400">Tidak ada siswa berisiko dengan filter ini.</p>
      </div>
    </Card>

    <!-- W7: Teacher Workload Table (admin only) -->
    <Card v-if="isAdmin" title="W7 — Beban Kerja Guru" subtitle="Jumlah tugas ajar dan total jam per minggu">
      <div v-if="widgets.w7.loading" class="space-y-2">
        <div v-for="i in 5" :key="i" class="animate-pulse h-10 rounded-lg bg-slate-100" />
      </div>
      <div v-else-if="w7Sorted.length">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-slate-100 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">
                <th
                  class="cursor-pointer select-none py-3 pr-4 hover:text-slate-600 transition-colors"
                  @click="sortW7('teacher_name')"
                >
                  Nama Guru
                  <span class="ml-1 text-slate-300">{{ w7SortIcon('teacher_name') }}</span>
                </th>
                <th
                  class="cursor-pointer select-none py-3 pr-4 hover:text-slate-600 transition-colors text-right"
                  @click="sortW7('ta_count')"
                >
                  Jumlah TA
                  <span class="ml-1 text-slate-300">{{ w7SortIcon('ta_count') }}</span>
                </th>
                <th
                  class="cursor-pointer select-none py-3 hover:text-slate-600 transition-colors text-right"
                  @click="sortW7('hours_per_week')"
                >
                  Total Jam/Minggu
                  <span class="ml-1 text-slate-300">{{ w7SortIcon('hours_per_week') }}</span>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-50">
              <tr
                v-for="row in w7Sorted"
                :key="row.teacher_id ?? row.teacher_name"
                class="hover:bg-slate-50/60 transition-colors"
              >
                <td class="py-3 pr-4 font-medium text-slate-800">{{ row.teacher_name }}</td>
                <td class="py-3 pr-4 text-right text-slate-600">{{ row.ta_count ?? 0 }}</td>
                <td class="py-3 text-right">
                  <span class="font-medium text-slate-700">{{ row.hours_per_week ?? 0 }}</span>
                  <span class="ml-1 text-xs text-slate-400">jam</span>
                </td>
              </tr>
            </tbody>
            <!-- Totals footer row -->
            <tfoot v-if="w7Totals">
              <tr class="border-t-2 border-slate-200 bg-slate-50 font-semibold">
                <td class="py-3 pr-4 text-sm text-slate-700">Total</td>
                <td class="py-3 pr-4 text-right text-sm text-slate-700">{{ w7Totals.ta_count }}</td>
                <td class="py-3 text-right text-sm">
                  <span class="text-slate-700">{{ w7Totals.hours_per_week }}</span>
                  <span class="ml-1 text-xs text-slate-400">jam</span>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
        <p v-if="widgets.w7.meta?.note" class="mt-2 text-xs text-slate-400">
          {{ widgets.w7.meta.note }}
        </p>
      </div>
      <div v-else class="flex flex-col items-center justify-center py-12 text-center">
        <svg class="h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
        </svg>
        <p class="mt-2 text-sm text-slate-400">Belum ada data beban kerja guru.</p>
      </div>
    </Card>

  </div>
</template>
