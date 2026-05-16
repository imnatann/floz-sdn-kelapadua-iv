<script setup>
import { Head } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import Button from '@/Components/UI/Button.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  student: Object,
  semester: Object,
  enrollment: Object,
  tasks: Array,
  exams: Array,
  attendanceSummary: Object,
  reportCard: Object,
});

const statusLabel = (s) => ({
  active: 'Aktif',
  promoted_out: 'Selesai (Naik kelas)',
  retained_out: 'Selesai (Tinggal kelas)',
  graduated: 'Lulus',
  transferred_out: 'Pindah',
  dropped_out: 'Keluar',
}[s] || s);

const formatDate = (d) => d ? new Date(d).toLocaleDateString('id-ID') : '—';
</script>

<template>
  <Head :title="`${student.name} — ${semester.academic_year?.name} Sem ${semester.semester_number}`" />

  <div class="mx-auto max-w-5xl space-y-6">
    <!-- Header -->
    <div class="flex items-center gap-4">
      <Button :href="`/students/${student.id}`" variant="outline" size="sm">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
        Kembali
      </Button>
      <div>
        <h2 class="text-xl font-bold text-slate-800">{{ student.name }}</h2>
        <p class="text-sm text-slate-500">
          {{ semester.academic_year?.name }} — Semester {{ semester.semester_number }}
          <span v-if="enrollment?.school_class"> · Kelas {{ enrollment.school_class.name }}</span>
          <span v-if="enrollment?.status" class="ml-2 inline-block rounded bg-slate-100 px-2 py-0.5 text-xs text-slate-700">{{ statusLabel(enrollment.status) }}</span>
        </p>
      </div>
    </div>

    <!-- Tasks -->
    <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Tugas ({{ tasks.length }})</h3>
      </div>
      <div v-if="tasks.length === 0" class="px-6 py-6 text-center text-sm text-slate-400">Tidak ada tugas.</div>
      <table v-else class="w-full text-sm">
        <thead class="bg-slate-50/60">
          <tr class="border-b border-slate-100">
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Tanggal</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Mapel</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Judul</th>
            <th class="px-4 py-2 text-right text-xs font-semibold uppercase text-slate-400">Nilai</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="t in tasks" :key="t.id" class="border-b border-slate-50">
            <td class="px-4 py-2 text-slate-600">{{ formatDate(t.task_date) }}</td>
            <td class="px-4 py-2 text-slate-700">{{ t.subject?.name || '—' }}</td>
            <td class="px-4 py-2 text-slate-700">{{ t.title }}</td>
            <td class="px-4 py-2 text-right">
              <span v-if="t.student_score !== null && t.student_score !== undefined" class="font-medium text-slate-800">{{ t.student_score }} / {{ t.max_score }}</span>
              <span v-else class="text-xs text-slate-400">{{ t.submission_status || '—' }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Exams -->
    <div class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Ujian ({{ exams.length }})</h3>
      </div>
      <div v-if="exams.length === 0" class="px-6 py-6 text-center text-sm text-slate-400">Tidak ada ujian.</div>
      <table v-else class="w-full text-sm">
        <thead class="bg-slate-50/60">
          <tr class="border-b border-slate-100">
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Tanggal</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Mapel</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Judul / Tipe</th>
            <th class="px-4 py-2 text-right text-xs font-semibold uppercase text-slate-400">Nilai</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in exams" :key="e.id" class="border-b border-slate-50">
            <td class="px-4 py-2 text-slate-600">{{ formatDate(e.exam_date) }}</td>
            <td class="px-4 py-2 text-slate-700">{{ e.subject?.name || '—' }}</td>
            <td class="px-4 py-2 text-slate-700">{{ e.title }} <span class="ml-1 text-xs text-slate-400">({{ e.exam_type }})</span></td>
            <td class="px-4 py-2 text-right">
              <span v-if="e.student_score !== null && e.student_score !== undefined" class="font-medium text-slate-800">{{ e.student_score }} / {{ e.max_score }}</span>
              <span v-else class="text-xs text-slate-400">—</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Attendance + Report -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 class="mb-3 text-sm font-semibold text-slate-700">Rekap Absensi</h3>
        <div class="space-y-1 text-sm">
          <div class="flex justify-between"><span class="text-slate-500">Hadir</span><span class="font-medium">{{ attendanceSummary?.hadir || 0 }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Sakit</span><span class="font-medium">{{ attendanceSummary?.sakit || 0 }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Izin</span><span class="font-medium">{{ attendanceSummary?.izin || 0 }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Alfa</span><span class="font-medium">{{ attendanceSummary?.alfa || 0 }}</span></div>
        </div>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 class="mb-3 text-sm font-semibold text-slate-700">Rapor</h3>
        <div v-if="reportCard" class="space-y-1 text-sm">
          <div class="flex justify-between"><span class="text-slate-500">Rata-rata</span><span class="font-medium">{{ reportCard.average_score || '—' }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Total</span><span class="font-medium">{{ reportCard.total_score || '—' }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Ranking</span><span class="font-medium">{{ reportCard.rank || '—' }}</span></div>
          <div class="flex justify-between"><span class="text-slate-500">Status</span><span class="font-medium">{{ reportCard.status }}</span></div>
        </div>
        <div v-else class="text-sm text-slate-400">Belum ada rapor.</div>
      </div>
    </div>
  </div>
</template>
