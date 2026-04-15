<script setup>
import { ref, computed } from 'vue';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Pagination from '@/Components/UI/Pagination.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignments: Object,
  teachers: Array,
  subjects: Array,
  classes: Array,
  academicYears: Array,
  filters: Object,
});

const page = usePage();
const flash = computed(() => page.props.flash || {});

// Filter State
const teacherFilter = ref(props.filters?.teacher_id || '');
const subjectFilter = ref(props.filters?.subject_id || '');
const classFilter = ref(props.filters?.class_id || '');
const yearFilter = ref(props.filters?.academic_year_id || '');

const applyFilters = () => {
  router.get('/teaching-assignments', {
    teacher_id: teacherFilter.value || undefined,
    subject_id: subjectFilter.value || undefined,
    class_id: classFilter.value || undefined,
    academic_year_id: yearFilter.value || undefined,
  }, { preserveState: true, replace: true });
};

const confirmDelete = (assignment) => {
  if (confirm('Yakin ingin menghapus penugasan ini?')) {
    router.delete(`/tenant/teaching-assignments/${assignment.id}`);
  }
};
</script>

<template>
  <Head title="Penugasan Guru" />

  <div>
    <!-- Header -->
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Penugasan Guru</h2>
        <p class="text-sm text-slate-500 mt-0.5">Atur jadwal mengajar guru per kelas dan mata pelajaran</p>
      </div>
      <Button href="/teaching-assignments/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Penugasan
      </Button>
    </div>

    <!-- Flash -->
    <div v-if="flash.success" class="mb-4 flex items-center gap-2 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
      <svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      {{ flash.success }}
    </div>
    <div v-if="flash.error" class="mb-4 flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
      <svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      {{ flash.error }}
    </div>

    <!-- Filters -->
    <div class="mb-5 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <FormSelect v-model="yearFilter" @change="applyFilters">
        <option value="">Semua Tahun Ajaran</option>
        <option v-for="y in academicYears" :key="y.id" :value="y.id">{{ y.name }} {{ y.is_active ? '(Aktif)' : '' }}</option>
      </FormSelect>
      <FormSelect v-model="classFilter" @change="applyFilters">
        <option value="">Semua Kelas</option>
        <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }}</option>
      </FormSelect>
      <FormSelect v-model="subjectFilter" @change="applyFilters">
        <option value="">Semua Mapel</option>
        <option v-for="s in subjects" :key="s.id" :value="s.id">{{ s.name }} ({{ s.code }})</option>
      </FormSelect>
      <FormSelect v-model="teacherFilter" @change="applyFilters">
        <option value="">Semua Guru</option>
        <option v-for="t in teachers" :key="t.id" :value="t.id">{{ t.name }}</option>
      </FormSelect>
    </div>

    <!-- Table -->
    <div v-if="assignments?.data?.length > 0" class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <table class="min-w-full divide-y divide-slate-200">
        <thead class="bg-slate-50">
          <tr>
            <th class="px-5 py-3 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500">Guru</th>
            <th class="px-5 py-3 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500">Mata Pelajaran</th>
            <th class="px-5 py-3 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500">Kelas</th>
            <th class="px-5 py-3 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500">Tahun Ajaran</th>
            <th class="px-5 py-3 text-right text-[11px] font-semibold uppercase tracking-wider text-slate-500">Aksi</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="item in assignments.data" :key="item.id" class="transition-colors hover:bg-slate-50/50">
            <td class="px-5 py-3.5 text-sm font-medium text-slate-800">{{ item.teacher?.name }}</td>
            <td class="px-5 py-3.5 text-sm text-slate-600">{{ item.subject?.name }} <span class="text-xs text-slate-400">({{ item.subject?.code }})</span></td>
            <td class="px-5 py-3.5 text-sm text-slate-600 font-medium">{{ item.school_class?.name }}</td>
            <td class="px-5 py-3.5 text-sm text-slate-500">{{ item.academic_year?.name }}</td>
            <td class="px-5 py-3.5 text-right flex justify-end gap-2">
              <Link :href="`/teaching-assignments/${item.id}/edit`" class="rounded-lg p-1.5 text-slate-400 hover:bg-amber-50 hover:text-amber-500" title="Edit">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
              </Link>
              <button @click="confirmDelete(item)" class="rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-500" title="Hapus">
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Empty -->
    <div v-else class="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white py-16">
      <svg class="h-12 w-12 text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/></svg>
      <h3 class="text-sm font-semibold text-slate-600 mb-1">Belum ada penugasan guru</h3>
      <p class="text-xs text-slate-400 mb-4">Tautkan guru ke mata pelajaran dan kelas</p>
      <Button href="/teaching-assignments/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Buat Penugasan
      </Button>
    </div>

    <!-- Pagination -->
    <div class="mt-6">
      <Pagination :links="assignments.links" />
    </div>
  </div>
</template>
