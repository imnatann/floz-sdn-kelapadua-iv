<script setup>
import { computed } from 'vue';
import Modal from '@/Components/UI/Modal.vue';
import Badge from '@/Components/UI/Badge.vue';

const props = defineProps({
  show: Boolean,
  log: Object,
});

const emit = defineEmits(['close']);

const diffs = computed(() => {
  if (!props.log) return [];
  const oldVals = props.log.old_values || {};
  const newVals = props.log.new_values || {};
  
  const allKeys = new Set([...Object.keys(oldVals), ...Object.keys(newVals)]);
  const changes = [];

  allKeys.forEach(key => {
    // Skip timestamps if you want, or keep them
    if (key === 'updated_at' || key === 'created_at') return;

    const oldVal = oldVals[key];
    const newVal = newVals[key];

    if (JSON.stringify(oldVal) !== JSON.stringify(newVal)) {
      changes.push({
        key,
        old: oldVal,
        new: newVal,
      });
    }
  });

  return changes;
});

const eventColor = (event) => {
    switch (event) {
        case 'created': return 'success';
        case 'updated': return 'warning';
        case 'deleted': return 'danger';
        default: return 'neutral';
    }
};
</script>

<template>
  <Modal :show="show" @close="$emit('close')">
    <div class="p-6">
      <div class="mb-4 flex items-center justify-between">
        <h3 class="text-lg font-medium text-slate-900">Detail Log Aktivitas</h3>
        <div class="flex gap-1">
           <Badge v-if="log?.method" variant="neutral">{{ log?.method }}</Badge>
           <Badge :variant="eventColor(log?.event)">{{ log?.event?.toUpperCase() }}</Badge>
        </div>
      </div>

      <div class="space-y-4" v-if="log">
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="block text-slate-400 text-xs uppercase">User</span>
            <span class="font-medium text-slate-700">{{ log.user?.name || 'Unknown' }}</span>
          </div>
          <div>
             <span class="block text-slate-400 text-xs uppercase">Waktu</span>
             <span class="font-mono text-slate-600">{{ new Date(log.created_at).toLocaleString('id-ID') }}</span>
          </div>
          <div class="col-span-2">
             <span class="block text-slate-400 text-xs uppercase">Target</span>
             <span class="font-mono text-slate-600 break-all">{{ log.auditable_type }} #{{ log.auditable_id }}</span>
          </div>
        </div>

        <div class="mt-4 border-t border-slate-100 pt-4">
          <h4 class="text-sm font-semibold text-slate-800 mb-2">Perubahan Data</h4>
          
          <div v-if="diffs.length > 0" class="space-y-2">
             <div v-for="diff in diffs" :key="diff.key" class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm bg-slate-50 p-2 rounded-lg border border-slate-100">
                <div class="col-span-2 font-medium text-slate-600 border-b border-slate-200 pb-1 mb-1">{{ diff.key }}</div>
                
                <div class="break-all">
                    <span class="text-xs text-red-500 block">Sebelum:</span>
                    <span class="text-slate-600 bg-red-50 px-1 rounded">{{ JSON.stringify(diff.old) }}</span>
                </div>
                <div class="break-all">
                    <span class="text-xs text-green-500 block">Sesudah:</span>
                    <span class="text-slate-600 bg-green-50 px-1 rounded">{{ JSON.stringify(diff.new) }}</span>
                </div>
             </div>
          </div>
          <p v-else class="text-sm text-slate-400 italic">Tidak ada perubahan data yang tercatat (mungkin hanya event akses atau data tidak berubah).</p>
        </div>
      </div>

      <div class="mt-6 flex justify-end">
        <button @click="$emit('close')" class="rounded-lg bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-200">
          Tutup
        </button>
      </div>
    </div>
  </Modal>
</template>
