<script setup>
import { Link, Head } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Card from '@/Components/UI/Card.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  reportCard: Object,
  grades: Array,
});

const predicateColor = (p) => p === 'A' ? 'emerald' : p === 'B' ? 'blue' : p === 'C' ? 'amber' : 'rose';
</script>

<template>
  <Head :title="`Rapor — ${reportCard.student?.name}`" />
  <div class="mx-auto max-w-4xl space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div class="flex items-center gap-4">
        <Button href="/report-cards" variant="outline" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
          Kembali
        </Button>
        <div>
          <h2 class="text-xl font-bold text-slate-800">Rapor — {{ reportCard.student?.name }}</h2>
          <p class="mt-0.5 text-sm text-slate-400">
            Kelas {{ reportCard.school_class?.name }} · Semester {{ reportCard.semester?.semester_number }} — {{ reportCard.semester?.academic_year?.name }}
          </p>
          <p class="mt-0.5 text-xs font-semibold" :class="reportCard.report_type === 'uts' ? 'text-amber-600' : 'text-emerald-600'">
            {{ reportCard.report_type === 'uts' ? 'Penilaian Tengah Semester (UTS)' : 'Penilaian Akhir Semester (Final)' }}
          </p>
        </div>
      </div>
      <div class="flex gap-2">
        <Button :href="`/report-cards/${reportCard.id}/pdf`" tag="a" variant="outline" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          Download PDF
        </Button>
        <Link
          v-if="reportCard.status === 'draft'"
          :href="`/report-cards/${reportCard.id}/publish`"
          method="post"
          as="button"
          class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-xs font-medium text-white shadow-sm transition-colors hover:bg-emerald-700"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
          Terbitkan
        </Link>
      </div>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
      <div class="rounded-xl border border-slate-200 bg-white p-4 text-center shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Peringkat</p>
        <div class="mt-2">
          <div v-if="reportCard.rank && reportCard.rank <= 3" class="mx-auto flex h-10 w-10 items-center justify-center rounded-full text-lg font-bold" :class="reportCard.rank === 1 ? 'bg-amber-100 text-amber-700' : reportCard.rank === 2 ? 'bg-slate-100 text-slate-600' : 'bg-orange-100 text-orange-700'">
            {{ reportCard.rank }}
          </div>
          <p v-else class="text-2xl font-bold text-slate-700">{{ reportCard.rank || '—' }}</p>
        </div>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-4 text-center shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Rata-rata</p>
        <p class="mt-2 text-2xl font-bold text-emerald-600">{{ reportCard.average_score ?? '—' }}</p>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-4 text-center shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Total Nilai</p>
        <p class="mt-2 text-2xl font-bold text-slate-700">{{ reportCard.total_score ?? '—' }}</p>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-4 text-center shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Status</p>
        <Badge :color="reportCard.status === 'published' ? 'emerald' : 'amber'" class="mt-2">
          {{ reportCard.status === 'published' ? 'Diterbitkan' : 'Draft' }}
        </Badge>
      </div>
    </div>

    <!-- Grades Table -->
    <Card title="Nilai Per Mata Pelajaran" :subtitle="`${grades?.length || 0} mata pelajaran`">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100">
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-10">#</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Mata Pelajaran</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Nilai Akhir</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Predikat</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Keterangan</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(grade, i) in grades" :key="grade.id" class="border-b border-slate-50 transition-colors hover:bg-slate-50/50">
              <td class="px-4 py-3 text-xs text-slate-400">{{ i + 1 }}</td>
              <td class="px-4 py-3 font-medium text-slate-700">{{ grade.subject?.name }}</td>
              <td class="px-4 py-3">
                <span class="font-mono font-semibold text-slate-700">{{ grade.final_score ?? '—' }}</span>
              </td>
              <td class="px-4 py-3">
                <Badge v-if="grade.predicate" :color="predicateColor(grade.predicate)" size="sm">{{ grade.predicate }}</Badge>
                <span v-else class="text-slate-300">—</span>
              </td>
              <td class="px-4 py-3 text-xs text-slate-400">{{ grade.description || '—' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Card>

    <!-- Attendance -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Kehadiran</h3>
      </div>
      <div class="grid grid-cols-2 gap-px bg-slate-100 p-px sm:grid-cols-4">
        <div class="bg-white p-5 text-center">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Hadir</p>
          <p class="mt-1 text-2xl font-bold text-emerald-600">{{ reportCard.attendance_present ?? 0 }}</p>
        </div>
        <div class="bg-white p-5 text-center">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Sakit</p>
          <p class="mt-1 text-2xl font-bold text-amber-500">{{ reportCard.attendance_sick ?? 0 }}</p>
        </div>
        <div class="bg-white p-5 text-center">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Izin</p>
          <p class="mt-1 text-2xl font-bold text-blue-500">{{ reportCard.attendance_permit ?? 0 }}</p>
        </div>
        <div class="bg-white p-5 text-center">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Alpa</p>
          <p class="mt-1 text-2xl font-bold text-red-500">{{ reportCard.attendance_absent ?? 0 }}</p>
        </div>
      </div>
    </div>

    <!-- Extracurriculars -->
    <div v-if="reportCard.extracurricular && reportCard.extracurricular.length > 0" class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Ekstrakurikuler</h3>
      </div>
      <div class="p-0">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100">
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Kegiatan Ekstrakurikuler</th>
              <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400 w-32">Keterangan</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(extra, idx) in reportCard.extracurricular" :key="idx" class="border-b border-slate-50">
              <td class="px-6 py-3 font-medium text-slate-700">{{ extra.name }}</td>
              <td class="px-6 py-3 text-slate-600 font-semibold">{{ extra.grade }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Comments -->
    <div v-if="reportCard.homeroom_comment || reportCard.principal_comment" class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 bg-slate-50/60 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Catatan</h3>
      </div>
      <div class="divide-y divide-slate-100">
        <div v-if="reportCard.homeroom_comment" class="p-6">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Wali Kelas</p>
          <p class="mt-2 text-sm leading-relaxed text-slate-600">{{ reportCard.homeroom_comment }}</p>
        </div>
        <div v-if="reportCard.principal_comment" class="p-6">
          <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Kepala Sekolah</p>
          <p class="mt-2 text-sm leading-relaxed text-slate-600">{{ reportCard.principal_comment }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
