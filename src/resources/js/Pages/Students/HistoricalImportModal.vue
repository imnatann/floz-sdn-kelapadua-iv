<script setup>
import { watch } from 'vue';
import { useForm } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
});
const emit = defineEmits(['close']);

const form = useForm({ file: null });

watch(() => props.show, (val) => {
  if (!val) { form.reset(); form.clearErrors(); }
});

const submit = () => {
  form.post('/students/import-historical', {
    forceFormData: true,
    onSuccess: () => emit('close'),
  });
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-lg rounded-xl bg-white shadow-xl">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-base font-semibold text-slate-800">Import Riwayat Enrollment</h3>
      </div>
      <form @submit.prevent="submit" class="space-y-4 px-6 py-5 text-sm">
        <div class="rounded-lg bg-blue-50 p-3 text-xs text-blue-700">
          Format Excel (.xlsx) — kolom: <strong>NIS, Tahun Ajaran, Semester, Kelas, Status</strong>.<br />
          Contoh: <code>100, 2024/2025, 1, 1A, promoted_out</code>.<br />
          Siswa, TA, Semester, dan Kelas harus sudah ada di sistem.
        </div>
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">File Excel</label>
          <input type="file" accept=".xlsx,.csv" @change="form.file = $event.target.files[0]" class="w-full text-sm" />
          <p v-if="form.errors.file" class="mt-1 text-xs text-red-500" v-html="form.errors.file"></p>
        </div>
        <div class="flex justify-end gap-2 pt-2">
          <button type="button" @click="emit('close')" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm">Batal</button>
          <button type="submit" :disabled="form.processing || !form.file" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm text-white disabled:opacity-50">Upload & Import</button>
        </div>
      </form>
    </div>
  </div>
</template>
