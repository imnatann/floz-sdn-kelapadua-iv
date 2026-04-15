<script setup>
import Badge from '@/Components/UI/Badge.vue';
import Card from '@/Components/UI/Card.vue';

const props = defineProps({
  student: Object,
});

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
</template>
