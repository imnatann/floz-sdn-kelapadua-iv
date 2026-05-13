<script setup>
import { useForm, Head, Link, router, usePage } from '@inertiajs/vue3';
import { ref, computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
  classData: { type: Object, default: null },
  academicYears: Array,
  teachers: Array,
  subjects: { type: Array, default: () => [] },
});

const isEdit = !!props.classData;
const page = usePage();
const flash = computed(() => page.props.flash || {});

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
    form.put(`/classes/${props.classData.id}`, { preserveScroll: true });
  } else {
    form.post('/classes', { preserveScroll: true });
  }
};

// ────── Mapel-Guru assignment (edit mode only) ──────
const showAddTaForm = ref(false);
const taForm = useForm({
  teacher_id: '',
  subject_id: '',
  class_id: props.classData?.id || null,
  academic_year_id: props.classData?.academic_year_id || (props.academicYears?.find(y => y.is_active)?.id || ''),
});

const existingTaForCurrentAy = computed(() => {
  const ayId = taForm.academic_year_id;
  return (props.classData?.teaching_assignments || []).filter(ta => ta.academic_year_id === Number(ayId));
});

// Subjects not yet linked to this class in the chosen academic year
const availableSubjects = computed(() => {
  const linkedIds = new Set(existingTaForCurrentAy.value.map(ta => ta.subject_id));
  return props.subjects.filter(s => !linkedIds.has(s.id));
});

const addTa = () => {
  if (!taForm.teacher_id || !taForm.subject_id || !taForm.academic_year_id) return;
  taForm.post('/teaching-assignments', {
    preserveScroll: true,
    onSuccess: () => {
      taForm.reset('teacher_id', 'subject_id');
      showAddTaForm.value = false;
      router.reload({ only: ['classData', 'flash'] });
    },
  });
};

const removeTa = (ta) => {
  if (!confirm(`Hapus penugasan ${ta.subject?.name} — ${ta.teacher?.name}?`)) return;
  router.delete(`/teaching-assignments/${ta.id}`, {
    preserveScroll: true,
    onSuccess: () => router.reload({ only: ['classData', 'flash'] }),
  });
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

    <!-- Mata Pelajaran di Kelas Ini (edit mode only) -->
    <div v-if="isEdit" class="mt-6 rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
        <div>
          <h3 class="text-sm font-semibold text-slate-700">Mata Pelajaran di Kelas Ini</h3>
          <p class="text-xs text-slate-500 mt-0.5">Penugasan guru mengajar mapel di {{ classData.name }}</p>
        </div>
        <button
          type="button"
          @click="showAddTaForm = !showAddTaForm"
          class="inline-flex items-center gap-1.5 rounded-lg bg-emerald-50 px-3 py-1.5 text-xs font-medium text-emerald-700 hover:bg-emerald-100"
        >
          <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="showAddTaForm ? 'M6 18L18 6M6 6l12 12' : 'M12 4v16m8-8H4'" /></svg>
          {{ showAddTaForm ? 'Batal' : 'Tambah Mapel' }}
        </button>
      </div>

      <!-- Flash from TA action -->
      <div v-if="flash.success" class="border-b border-slate-100 bg-emerald-50/50 px-6 py-2 text-xs text-emerald-700">{{ flash.success }}</div>
      <div v-if="flash.error" class="border-b border-slate-100 bg-red-50/50 px-6 py-2 text-xs text-red-700">{{ flash.error }}</div>

      <!-- Inline add form -->
      <div v-if="showAddTaForm" class="border-b border-slate-100 bg-slate-50/50 px-6 py-4">
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div>
            <label class="mb-1 block text-[11px] font-medium uppercase tracking-wide text-slate-500">Tahun Ajaran</label>
            <select v-model="taForm.academic_year_id" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
              <option v-for="y in academicYears" :key="y.id" :value="y.id">{{ y.name }} {{ y.is_active ? '(Aktif)' : '' }}</option>
            </select>
          </div>
          <div>
            <label class="mb-1 block text-[11px] font-medium uppercase tracking-wide text-slate-500">Mata Pelajaran</label>
            <select v-model="taForm.subject_id" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
              <option value="">Pilih mapel</option>
              <option v-for="s in availableSubjects" :key="s.id" :value="s.id">{{ s.name }}</option>
            </select>
            <p v-if="!availableSubjects.length" class="mt-1 text-[11px] text-slate-400">Semua mapel sudah ditugaskan untuk tahun ajaran ini.</p>
          </div>
          <div>
            <label class="mb-1 block text-[11px] font-medium uppercase tracking-wide text-slate-500">Guru Pengampu</label>
            <select v-model="taForm.teacher_id" class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm shadow-sm focus:border-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-400/20">
              <option value="">Pilih guru</option>
              <option v-for="t in teachers" :key="t.id" :value="t.id">{{ t.name }}{{ t.nip ? ` (${t.nip})` : '' }}</option>
            </select>
          </div>
        </div>
        <p v-if="taForm.errors.teacher_id || taForm.errors.subject_id || taForm.errors.academic_year_id || taForm.errors.class_id" class="mt-2 text-xs text-red-500">
          {{ taForm.errors.teacher_id || taForm.errors.subject_id || taForm.errors.academic_year_id || taForm.errors.class_id }}
        </p>
        <div class="mt-3 flex justify-end gap-2">
          <button
            type="button"
            @click="addTa"
            :disabled="taForm.processing || !taForm.teacher_id || !taForm.subject_id || !taForm.academic_year_id"
            class="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-emerald-700 disabled:opacity-50"
          >
            <svg v-if="taForm.processing" class="h-3.5 w-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
            Simpan Penugasan
          </button>
        </div>
      </div>

      <!-- TA list -->
      <div v-if="classData.teaching_assignments?.length" class="divide-y divide-slate-100">
        <div v-for="ta in classData.teaching_assignments" :key="ta.id" class="flex items-center justify-between gap-4 px-6 py-3">
          <div class="flex flex-1 items-center gap-3">
            <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-emerald-50 text-emerald-700">
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
            </div>
            <div class="min-w-0">
              <p class="text-sm font-semibold text-slate-800">{{ ta.subject?.name }}</p>
              <p class="text-xs text-slate-500">{{ ta.teacher?.name }} {{ ta.academic_year?.name ? `· ${ta.academic_year.name}` : '' }}</p>
            </div>
          </div>
          <button
            type="button"
            @click="removeTa(ta)"
            class="rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600"
            title="Hapus penugasan"
          >
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
          </button>
        </div>
      </div>
      <div v-else class="px-6 py-8 text-center">
        <p class="text-sm text-slate-500">Belum ada mata pelajaran yang ditugaskan untuk kelas ini.</p>
        <p class="text-xs text-slate-400 mt-1">Klik <strong>Tambah Mapel</strong> untuk menugaskan guru mengajar mapel di kelas ini.</p>
      </div>
    </div>
  </div>
</template>
