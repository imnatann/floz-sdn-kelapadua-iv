<script setup>
import { ref, watch, reactive } from 'vue';
import { router } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
  semester: Object,
});
const emit = defineEmits(['close']);

const loading = ref(false);
const preview = ref(null);
const overrides = reactive({});

const STATUS_OPTIONS = [
  { value: 'active',          label: 'Aktif' },
  { value: 'transferred_out', label: 'Keluar (Pindah)' },
  { value: 'dropped_out',     label: 'Keluar (Dropout)' },
  { value: 'graduated',       label: 'Lulus' },
  { value: 'retained_out',    label: 'Tinggal kelas' },
];

watch(() => props.show, async (val) => {
  if (val && props.semester) {
    loading.value = true;
    try {
      const res = await fetch(`/semesters/${props.semester.id}/carry-over-preview`);
      preview.value = await res.json();
      for (const row of (preview.value.carry_over || [])) {
        overrides[row.student_id] = 'active';
      }
    } finally {
      loading.value = false;
    }
  } else {
    preview.value = null;
    Object.keys(overrides).forEach((k) => delete overrides[k]);
  }
});

const confirm = () => {
  router.post(`/semesters/${props.semester.id}/activate`, {
    overrides: { ...overrides },
  }, {
    onFinish: () => emit('close'),
  });
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-2xl rounded-xl bg-white shadow-xl">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-base font-semibold text-slate-800">Aktivasi Semester {{ semester?.semester_number }}</h3>
      </div>
      <div class="max-h-[60vh] overflow-y-auto px-6 py-5 text-sm">
        <div v-if="loading" class="text-center text-slate-400">Memuat preview…</div>
        <template v-else-if="preview">
          <p v-if="preview.source_semester_id" class="mb-4 text-slate-600">
            <strong>{{ preview.carry_over.length }}</strong> siswa akan di-carry-over ke semester ini.
            <span v-if="preview.skipped.length">
              <strong>{{ preview.skipped.length }}</strong> siswa di-skip (sudah keluar/lulus).
            </span>
          </p>
          <p v-else class="mb-4 text-slate-600">Tidak ada semester sebelumnya. Tidak ada carry-over.</p>

          <div v-if="preview.carry_over.length" class="mb-4">
            <h4 class="mb-2 text-xs font-semibold uppercase text-slate-500">Daftar siswa & status di semester baru</h4>
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-slate-100 bg-slate-50/60">
                  <th class="px-3 py-2 text-left text-xs font-semibold uppercase text-slate-500">Siswa</th>
                  <th class="px-3 py-2 text-left text-xs font-semibold uppercase text-slate-500">Kelas</th>
                  <th class="px-3 py-2 text-left text-xs font-semibold uppercase text-slate-500">Status</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in preview.carry_over" :key="row.student_id" class="border-b border-slate-50">
                  <td class="px-3 py-2 text-slate-700">{{ row.name }}</td>
                  <td class="px-3 py-2 text-slate-600">{{ row.class_name }}</td>
                  <td class="px-3 py-2">
                    <select v-model="overrides[row.student_id]" class="w-full rounded-md border border-slate-200 px-2 py-1 text-xs">
                      <option v-for="opt in STATUS_OPTIONS" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
                    </select>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-if="preview.skipped.length">
            <h4 class="mb-1 text-xs font-semibold uppercase text-slate-500">Di-skip</h4>
            <ul class="space-y-1">
              <li v-for="row in preview.skipped" :key="row.student_id" class="text-slate-600">
                {{ row.name }} — {{ row.reason }}
              </li>
            </ul>
          </div>
        </template>
      </div>
      <div class="flex justify-end gap-2 border-t border-slate-100 bg-slate-50/60 px-6 py-3">
        <button @click="emit('close')" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50">Batal</button>
        <button @click="confirm" :disabled="loading" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50">
          Aktifkan & Carry-Over
        </button>
      </div>
    </div>
  </div>
</template>
