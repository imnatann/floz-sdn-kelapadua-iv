<script setup>
import { computed } from 'vue';
import { Link } from '@inertiajs/vue3';
import Badge from '@/Components/UI/Badge.vue';
import Card from '@/Components/UI/Card.vue';

const props = defineProps({
  student: Object,
});

const sortedEnrollments = computed(() => {
  if (!props.student.enrollments) return [];
  return [...props.student.enrollments].sort((a, b) => {
    const ayA = a.semester?.academic_year?.start_date || '';
    const ayB = b.semester?.academic_year?.start_date || '';
    if (ayA !== ayB) return ayB.localeCompare(ayA);
    return (b.semester?.semester_number || 0) - (a.semester?.semester_number || 0);
  });
});

const enrollmentStatusLabel = (s) => ({
  active: 'Aktif',
  promoted_out: 'Selesai (Naik kelas)',
  retained_out: 'Selesai (Tinggal kelas)',
  graduated: 'Lulus',
  transferred_out: 'Pindah',
  dropped_out: 'Keluar',
}[s] || s);

const typeLabel = (t) => ({
  promotion: 'Naik Kelas',
  retention: 'Tinggal Kelas',
  transfer_in: 'Pindah Masuk',
  transfer_out: 'Pindah Keluar',
  dropout: 'Putus Sekolah',
  graduated: 'Lulus'
}[t] || t);

const typeColor = (t) => ({
  promotion: 'emerald',
  retention: 'rose',
  transfer_in: 'blue',
  transfer_out: 'amber',
  dropout: 'slate',
  graduated: 'emerald'
}[t] || 'slate');
</script>

<template>
  <div>
    <!-- Riwayat Kelas (Phase 1 — temporal tracking) -->
    <div class="rounded-xl border border-slate-200 bg-white shadow-sm mb-6">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Riwayat Kelas</h3>
        <p class="mt-0.5 text-xs text-slate-400">Penempatan kelas per semester</p>
      </div>
      <div v-if="!student.enrollments || student.enrollments.length === 0" class="px-6 py-8 text-center text-sm text-slate-400">
        Belum ada riwayat kelas
      </div>
      <table v-else class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100 bg-slate-50/60">
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Tahun / Semester</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Kelas</th>
            <th class="px-4 py-2 text-left text-xs font-semibold uppercase text-slate-400">Status</th>
            <th class="px-4 py-2 text-right text-xs font-semibold uppercase text-slate-400">Aksi</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in sortedEnrollments" :key="e.id" class="border-b border-slate-100 hover:bg-slate-50">
            <td class="px-4 py-2">{{ e.semester?.academic_year?.name }} — Sem {{ e.semester?.semester_number }}</td>
            <td class="px-4 py-2">{{ e.school_class?.name || '—' }}</td>
            <td class="px-4 py-2">
              <span class="text-xs font-medium">{{ enrollmentStatusLabel(e.status) }}</span>
              <span v-if="e.exit_date" class="ml-1 text-[10px] text-slate-400">({{ new Date(e.exit_date).toLocaleDateString('id-ID') }})</span>
            </td>
            <td class="px-4 py-2 text-right">
              <Link :href="`/students/${student.id}/timeline/${e.semester_id}`" class="text-xs font-medium text-orange-600 hover:underline">
                Lihat detail
              </Link>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <Card title="Riwayat Mutasi Siswa" subtitle="Catatan perjalanan akademik siswa">
    <div v-if="student.mutations?.length" class="relative border-l border-slate-200 ml-3 space-y-8 py-2">
      <div v-for="mutation in student.mutations" :key="mutation.id" class="relative ml-6">
        <span class="absolute -left-[31px] mt-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-white ring-4 ring-white">
          <span class="h-2 w-2 rounded-full bg-slate-300"></span>
        </span>
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
           <div>
              <p class="text-sm font-bold text-slate-700">{{ typeLabel(mutation.type) }}</p>
              <p class="text-xs text-slate-500">{{ mutation.date }}</p>
           </div>
           <Badge :color="typeColor(mutation.type)" size="sm">{{ typeLabel(mutation.type) }}</Badge>
        </div>
        <p class="mt-2 text-sm text-slate-600">
          <span v-if="mutation.from_class">Dari Kelas: <span class="font-medium text-slate-800">{{ mutation.from_class.name }}</span></span>
          <span v-if="mutation.to_class"> ke <span class="font-medium text-slate-800">{{ mutation.to_class.name }}</span></span>
        </p>
        <p v-if="mutation.reason" class="mt-1 text-sm italic text-slate-500">"{{ mutation.reason }}"</p>
        <p v-if="mutation.notes" class="mt-1 text-xs text-slate-400">Catatan: {{ mutation.notes }}</p>
      </div>
    </div>
    <div v-else class="flex flex-col items-center gap-2 py-8">
      <span class="text-3xl">🔄</span>
      <p class="text-sm text-slate-500">Belum ada riwayat mutasi</p>
    </div>
  </Card>
  </div>
</template>
