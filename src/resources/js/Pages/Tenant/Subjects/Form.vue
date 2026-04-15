<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import { computed, watch } from 'vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  subject: { type: Object, default: null },
});

const isEdit = !!props.subject;

const form = useForm({
  code: props.subject?.code || '',
  name: props.subject?.name || '',
  education_level: props.subject?.education_level || 'SMP',
  grade_level: props.subject?.grade_level || '',
  kkm: props.subject?.kkm || 70,
  category: props.subject?.category || 'general',
  description: props.subject?.description || '',
  status: props.subject?.status || 'active',
});

const gradeOptions = computed(() => {
  switch (form.education_level) {
    case 'SD':
      return [
        { value: 1, label: 'Kelas 1' },
        { value: 2, label: 'Kelas 2' },
        { value: 3, label: 'Kelas 3' },
        { value: 4, label: 'Kelas 4' },
        { value: 5, label: 'Kelas 5' },
        { value: 6, label: 'Kelas 6' },
      ];
    case 'SMP':
      return [
        { value: 7, label: 'Kelas 7 (VII)' },
        { value: 8, label: 'Kelas 8 (VIII)' },
        { value: 9, label: 'Kelas 9 (IX)' },
      ];
    case 'SMA':
      return [
        { value: 10, label: 'Kelas 10 (X)' },
        { value: 11, label: 'Kelas 11 (XI)' },
        { value: 12, label: 'Kelas 12 (XII)' },
      ];
    default:
      return [];
  }
});

// Reset grade level when education level changes, but only if it doesn't match the new options
watch(() => form.education_level, (newLevel) => {
  const validGrades = gradeOptions.value.map(o => o.value);
  if (!validGrades.includes(form.grade_level)) {
    form.grade_level = validGrades[0] || '';
  }
});

const submit = () => {
  if (isEdit) {
    form.put(`/tenant/subjects/${props.subject.id}`, { preserveScroll: true });
  } else {
    form.post('/subjects', { preserveScroll: true });
  }
};
</script>

<template>
  <Head :title="isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran'" />

  <div class="max-w-2xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">{{ isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran' }}</h2>
        <p class="text-sm text-slate-500 mt-0.5">{{ isEdit ? `Perbarui data ${subject.name}` : 'Lengkapi data mata pelajaran' }}</p>
      </div>
      <Link href="/subjects" class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-600 shadow-sm hover:bg-slate-50">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
        Kembali
      </Link>
    </div>

    <form @submit.prevent="submit" class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Data Mata Pelajaran</h3>
      </div>
      <div class="grid grid-cols-1 gap-5 px-6 py-5 sm:grid-cols-2">
        <!-- Code -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Kode <span class="text-red-500">*</span></label>
          <input v-model="form.code" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="MTK, IPA, dll" />
          <p v-if="form.errors.code" class="mt-1 text-xs text-red-500">{{ form.errors.code }}</p>
        </div>
        <!-- Name -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Nama <span class="text-red-500">*</span></label>
          <input v-model="form.name" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Matematika" />
          <p v-if="form.errors.name" class="mt-1 text-xs text-red-500">{{ form.errors.name }}</p>
        </div>
        <!-- Education Level -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Jenjang Pendidikan <span class="text-red-500">*</span></label>
          <select v-model="form.education_level" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="SD">SD</option>
            <option value="SMP">SMP</option>
            <option value="SMA">SMA</option>
          </select>
          <p v-if="form.errors.education_level" class="mt-1 text-xs text-red-500">{{ form.errors.education_level }}</p>
        </div>
        <!-- Grade Level -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Kelas (opsional)</label>
          <select v-model="form.grade_level" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="">Semua kelas</option>
            <option v-for="grade in gradeOptions" :key="grade.value" :value="grade.value">
              {{ grade.label }}
            </option>
          </select>
          <p v-if="form.errors.grade_level" class="mt-1 text-xs text-red-500">{{ form.errors.grade_level }}</p>
        </div>
        <!-- KKM -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">KKM <span class="text-red-500">*</span></label>
          <input v-model="form.kkm" type="number" min="0" max="100" step="0.01" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
          <p v-if="form.errors.kkm" class="mt-1 text-xs text-red-500">{{ form.errors.kkm }}</p>
        </div>
        <!-- Category -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Kategori</label>
          <select v-model="form.category" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="general">Umum</option>
            <option value="religion">Agama</option>
            <option value="specialty">Peminatan</option>
          </select>
          <p v-if="form.errors.category" class="mt-1 text-xs text-red-500">{{ form.errors.category }}</p>
        </div>
        <!-- Status -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Status <span class="text-red-500">*</span></label>
          <select v-model="form.status" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="active">Aktif</option>
            <option value="inactive">Nonaktif</option>
          </select>
          <p v-if="form.errors.status" class="mt-1 text-xs text-red-500">{{ form.errors.status }}</p>
        </div>
        <!-- Description -->
        <div class="sm:col-span-2">
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Deskripsi</label>
          <textarea v-model="form.description" rows="3" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="Deskripsi singkat mata pelajaran" />
          <p v-if="form.errors.description" class="mt-1 text-xs text-red-500">{{ form.errors.description }}</p>
        </div>
      </div>

      <div class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50/50 px-6 py-4 rounded-b-xl">
        <Link href="/subjects" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 shadow-sm hover:bg-slate-50">Batal</Link>
        <button type="submit" :disabled="form.processing" class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-emerald-700 disabled:opacity-50">
          <svg v-if="form.processing" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
          {{ isEdit ? 'Simpan Perubahan' : 'Simpan' }}
        </button>
      </div>
    </form>
  </div>
</template>
