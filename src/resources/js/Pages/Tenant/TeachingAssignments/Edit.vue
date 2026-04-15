<script setup>
import { useForm, Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignment: Object,
  teachers: Array,
  subjects: Array,
  classes: Array,
  academicYears: Array,
});

const form = useForm({
  academic_year_id: props.assignment.academic_year_id,
  class_id: props.assignment.class_id,
  subject_id: props.assignment.subject_id,
  teacher_id: props.assignment.teacher_id,
});

const submit = () => {
  form.put(`/tenant/teaching-assignments/${props.assignment.id}`, {
    preserveScroll: true,
  });
};
</script>

<template>
  <Head title="Edit Penugasan" />

  <div class="max-w-3xl mx-auto">
    <!-- Header -->
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Edit Penugasan</h2>
        <p class="text-sm text-slate-500 mt-0.5">Ubah data penugasan guru</p>
      </div>
      <Link
        href="/teaching-assignments"
        class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-600 shadow-sm transition-colors hover:bg-slate-50"
      >
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
        Kembali
      </Link>
    </div>

    <!-- Form Card -->
    <form @submit.prevent="submit" class="rounded-xl border border-slate-200 bg-white shadow-sm">
      <!-- Info Header -->
      <div class="border-b border-slate-100 px-6 py-4 bg-slate-50/50 rounded-t-xl">
        <h3 class="text-sm font-semibold text-slate-700">Detail Penugasan</h3>
        <p class="text-xs text-slate-400">Pilih guru, mapel, dan kelas</p>
      </div>

      <div class="p-6 space-y-6">
        <!-- Academic Year -->
        <div>
          <FormSelect label="Tahun Ajaran" v-model="form.academic_year_id" :required="true" :error="form.errors.academic_year_id">
            <option v-for="y in academicYears" :key="y.id" :value="y.id">{{ y.name }} {{ y.is_active ? '(Aktif)' : '' }}</option>
          </FormSelect>
        </div>

        <!-- Class & Subject Grid -->
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div>
            <FormSelect label="Kelas" v-model="form.class_id" :required="true" :error="form.errors.class_id">
              <option value="">— Pilih Kelas —</option>
              <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }}</option>
            </FormSelect>
          </div>

          <div>
            <FormSelect label="Mata Pelajaran" v-model="form.subject_id" :required="true" :error="form.errors.subject_id">
              <option value="">— Pilih Mapel —</option>
              <option v-for="s in subjects" :key="s.id" :value="s.id">{{ s.name }} ({{ s.code }})</option>
            </FormSelect>
          </div>
        </div>

        <!-- Teacher -->
        <div>
          <FormSelect label="Guru Pengajar" v-model="form.teacher_id" :required="true" :error="form.errors.teacher_id">
            <option value="">— Pilih Guru —</option>
            <option v-for="t in teachers" :key="t.id" :value="t.id">{{ t.name }}</option>
          </FormSelect>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50/50 px-6 py-4 rounded-b-xl">
        <Button href="/teaching-assignments" variant="outline">
          Batal
        </Button>
        <Button type="submit" :loading="form.processing">
          <svg v-if="form.processing" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
          Simpan Perubahan
        </Button>
      </div>
    </form>
  </div>
</template>
