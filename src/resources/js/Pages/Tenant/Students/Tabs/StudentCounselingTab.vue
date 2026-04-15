<script setup>
import Badge from '@/Components/UI/Badge.vue';
import Card from '@/Components/UI/Card.vue';

const props = defineProps({
  student: Object,
});

const severityColor = (s) => ({
  low: 'slate',
  medium: 'amber',
  high: 'rose',
  critical: 'purple'
}[s] || 'slate');

const statusColor = (s) => ({
  open: 'rose',
  in_progress: 'blue',
  resolved: 'emerald'
}[s] || 'slate');
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h3 class="text-lg font-semibold text-slate-800">Buku Saku (Bimbingan Konseling)</h3>
      <button class="text-sm font-medium text-blue-600 hover:text-blue-700">
        + Tambah Catatan
      </button>
    </div>

    <div v-if="student.counseling_notes?.length" class="grid grid-cols-1 gap-4">
      <div v-for="note in student.counseling_notes" :key="note.id" class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
        <div class="flex items-start justify-between">
          <div>
            <div class="flex items-center gap-2">
              <Badge :color="severityColor(note.severity)" size="sm" class="uppercase">{{ note.severity }}</Badge>
              <h4 class="font-semibold text-slate-800">{{ note.title }}</h4>
            </div>
            <p class="mt-1 text-xs text-slate-400">
              {{ note.date }} • Oleh: {{ note.counselor?.name || 'Admin' }}
            </p>
          </div>
          <Badge :color="statusColor(note.status)">{{ note.status }}</Badge>
        </div>
        <p class="mt-3 text-sm text-slate-600">{{ note.description }}</p>
        <div v-if="note.follow_up_action" class="mt-3 rounded bg-slate-50 p-3 text-xs text-slate-600">
          <span class="font-bold text-slate-700">Tindak Lanjut:</span> {{ note.follow_up_action }}
        </div>
      </div>
    </div>
    
    <div v-else class="flex flex-col items-center gap-2 rounded-xl border border-dashed border-slate-300 bg-slate-50 py-12">
      <span class="text-3xl">🛡️</span>
      <p class="text-sm text-slate-500">Belum ada catatan konseling</p>
    </div>
  </div>
</template>
