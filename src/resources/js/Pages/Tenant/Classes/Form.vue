<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  classData: { type: Object, default: null },
  academicYears: Array,
  teachers: Array,
});

const isEdit = !!props.classData;

const form = useForm({
  name: props.classData?.name || '',
  grade_level: props.classData?.grade_level || 7,
  academic_year_id: props.classData?.academic_year_id || (props.academicYears?.find(y => y.is_active)?.id || ''),
  homeroom_teacher_id: props.classData?.homeroom_teacher_id || '',
  max_students: props.classData?.max_students || 40,
  status: props.classData?.status || 'active',
});

const submit = () => {
  if (isEdit) {
    form.put(`/tenant/classes/${props.classData.id}`, { preserveScroll: true });
  } else {
    form.post('/classes', { preserveScroll: true });
  }
};
</script>

<template>
  <Head :title="isEdit ? 'Edit Kelas' : 'Tambah Kelas'" />

  <div class="max-w-2xl mx-auto">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">{{ isEdit ? 'Edit Kelas' : 'Tambah Kelas Baru' }}</h2>
        <p class="text-sm text-slate-500 mt-0.5">{{ isEdit ? `Perbarui data ${classData.name}` : 'Lengkapi data kelas' }}</p>
      </div>
      <Link href="/classes" class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-600 shadow-sm hover:bg-slate-50">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
        Kembali
      </Link>
    </div>

    <form @submit.prevent="submit" class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-100 px-6 py-4">
        <h3 class="text-sm font-semibold text-slate-700">Data Kelas</h3>
      </div>
      <div class="grid grid-cols-1 gap-5 px-6 py-5 sm:grid-cols-2">
        <!-- Name -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Nama Kelas <span class="text-red-500">*</span></label>
          <input v-model="form.name" type="text" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" placeholder="7A, X IPA 1, dll" />
          <p v-if="form.errors.name" class="mt-1 text-xs text-red-500">{{ form.errors.name }}</p>
        </div>
        <!-- Grade Level -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Tingkat <span class="text-red-500">*</span></label>
          <select v-model="form.grade_level" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option v-for="n in 12" :key="n" :value="n">Kelas {{ n }}</option>
          </select>
          <p v-if="form.errors.grade_level" class="mt-1 text-xs text-red-500">{{ form.errors.grade_level }}</p>
        </div>
        <!-- Academic Year -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Tahun Ajaran <span class="text-red-500">*</span></label>
          <select v-model="form.academic_year_id" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="">Pilih tahun ajaran</option>
            <option v-for="y in academicYears" :key="y.id" :value="y.id">{{ y.name }} {{ y.is_active ? '(Aktif)' : '' }}</option>
          </select>
          <p v-if="form.errors.academic_year_id" class="mt-1 text-xs text-red-500">{{ form.errors.academic_year_id }}</p>
        </div>
        <!-- Homeroom Teacher -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Wali Kelas</label>
          <select v-model="form.homeroom_teacher_id" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
            <option value="">Belum ditentukan</option>
            <option v-for="t in teachers" :key="t.id" :value="t.id">{{ t.name }} {{ t.nip ? `(${t.nip})` : '' }}</option>
          </select>
          <p v-if="form.errors.homeroom_teacher_id" class="mt-1 text-xs text-red-500">{{ form.errors.homeroom_teacher_id }}</p>
        </div>
        <!-- Max Students -->
        <div>
          <label class="mb-1.5 block text-xs font-medium text-slate-600">Maks Siswa <span class="text-red-500">*</span></label>
          <input v-model="form.max_students" type="number" min="1" max="100" class="w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm text-slate-700 shadow-sm placeholder:text-slate-400 focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20" />
          <p v-if="form.errors.max_students" class="mt-1 text-xs text-red-500">{{ form.errors.max_students }}</p>
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
      </div>

      <div class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50/50 px-6 py-4 rounded-b-xl">
        <Link href="/classes" class="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-600 shadow-sm hover:bg-slate-50">Batal</Link>
        <button type="submit" :disabled="form.processing" class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-emerald-700 disabled:opacity-50">
          <svg v-if="form.processing" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
          {{ isEdit ? 'Simpan Perubahan' : 'Simpan' }}
        </button>
      </div>
    </form>
  </div>
</template>
