<script setup>
import { watch } from 'vue';
import { useForm } from '@inertiajs/vue3';

const props = defineProps({
  show: Boolean,
  student: Object,
});
const emit = defineEmits(['close']);

const form = useForm({
  status: 'transferred_out',
  exit_date: new Date().toISOString().slice(0, 10),
  reason: '',
});

const STATUS_OPTIONS = [
  { value: 'transferred_out', label: 'Pindah sekolah' },
  { value: 'dropped_out',     label: 'Dropout / Berhenti' },
  { value: 'graduated',       label: 'Lulus' },
];

watch(() => props.show, (val) => {
  if (!val) {
    form.reset();
    form.clearErrors();
  }
});

const submit = () => {
  form.post(`/students/${props.student.id}/exit`, {
    onSuccess: () => emit('close'),
  });
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="w-full max-w-md rounded-xl bg-white shadow-xl">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-base font-semibold text-slate-800">Tandai Keluar: {{ student?.name }}</h3>
      </div>
      <form @submit.prevent="submit" class="space-y-4 px-6 py-5 text-sm">
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Status <span class="text-red-500">*</span></label>
          <select v-model="form.status" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm">
            <option v-for="o in STATUS_OPTIONS" :key="o.value" :value="o.value">{{ o.label }}</option>
          </select>
          <p v-if="form.errors.status" class="mt-1 text-xs text-red-500">{{ form.errors.status }}</p>
        </div>
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Tanggal keluar <span class="text-red-500">*</span></label>
          <input v-model="form.exit_date" type="date" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" />
          <p v-if="form.errors.exit_date" class="mt-1 text-xs text-red-500">{{ form.errors.exit_date }}</p>
        </div>
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Alasan (opsional)</label>
          <textarea v-model="form.reason" rows="3" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm" placeholder="Pindah karena…" />
        </div>
        <div class="flex justify-end gap-2 pt-2">
          <button type="button" @click="emit('close')" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600">Batal</button>
          <button type="submit" :disabled="form.processing" class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50">Tandai Keluar</button>
        </div>
      </form>
    </div>
  </div>
</template>
