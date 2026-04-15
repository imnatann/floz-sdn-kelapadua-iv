<script setup>
import { ref, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import SearchInput from '@/Components/UI/SearchInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import debounce from 'lodash/debounce';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  assignments: Object,
  subjects: Array,
  classes: Array,
  filters: Object,
  is_student: Boolean,
});

// -- LIST & FILTER LOGIC --
const search = ref(props.filters?.search || '');
const classFilter = ref(props.filters?.class_id || '');
const subjectFilter = ref(props.filters?.subject_id || '');

const applyFilters = debounce(() => {
  router.get('/offline-assignments', {
    search: search.value || undefined,
    class_id: classFilter.value || undefined,
    subject_id: subjectFilter.value || undefined,
  }, { preserveState: true, replace: true });
}, 300);

watch(search, applyFilters);
watch(classFilter, applyFilters);
watch(subjectFilter, applyFilters);

const formatDate = (dateString) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleString('id-ID', {
    day: 'numeric', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  });
};

const formatClasses = (classes) => {
  if (!classes || classes.length === 0) return '-';
  if (classes.length === 1) return classes[0].name;
  return classes.length + ' Kelas';
};

const deleteAssignment = (id) => {
  if (confirm('Hapus tugas ini?')) {
    router.delete(`/tenant/offline-assignments/${id}`);
  }
};

const getSubmissionStatus = (assignment) => {
    if (!assignment.student_submission) return { label: 'Belum Kumpul', variant: 'warning' };
    if (assignment.student_submission.grade) return { label: 'Dinilai', variant: 'success' };
    return { label: 'Sudah Kumpul', variant: 'info' };
};
</script>

<template>
  <Head title="Tugas Offline" />

  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-800">Tugas Offline</h1>
        <nav class="flex text-sm text-slate-500 mt-1">
          <Link href="/dashboard" class="hover:text-blue-600">Home</Link>
          <span class="mx-2">/</span>
          <span class="text-slate-800 font-medium">Tugas Offline</span>
        </nav>
      </div>
      <Link v-if="!is_student" href="/offline-assignments/create">
          <Button variant="primary" icon="plus">Tambah Tugas</Button>
      </Link>
    </div>

    <!-- Filters -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-slate-200 grid grid-cols-1 md:grid-cols-12 gap-4">
      <div v-if="!is_student" class="md:col-span-3">
        <FormSelect
          v-model="classFilter"
          placeholder="Semua Kelas"
          :options="classes.map(c => ({ value: c.id, label: c.name }))"
        />
      </div>
      <div :class="is_student ? 'md:col-span-4' : 'md:col-span-3'">
        <FormSelect
          v-model="subjectFilter"
          placeholder="Semua Mapel"
          :options="subjects.map(s => ({ value: s.id, label: s.name }))"
        />
      </div>
      <div :class="is_student ? 'md:col-span-4 md:col-start-9' : 'md:col-span-4 md:col-start-9'">
         <SearchInput v-model="search" placeholder="Cari Judul..." />
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead class="bg-slate-50 border-b border-slate-200 text-slate-500 font-medium uppercase tracking-wider">
            <tr>
              <th class="px-6 py-4">Kelas</th>
              <th class="px-6 py-4">Mapel</th>
              <th class="px-6 py-4">Judul</th>
              <th class="px-6 py-4">Tenggat</th>
              <th class="px-6 py-4">Status</th>
              <th class="px-6 py-4 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200">
            <tr v-if="assignments.data.length === 0">
              <td colspan="6" class="px-6 py-8 text-center text-slate-500 italic">
                Belum ada tugas offline.
              </td>
            </tr>
            <tr v-for="assignment in assignments.data" :key="assignment.id" class="hover:bg-slate-50 transition-all">
              <td class="px-6 py-4 text-slate-600">
                {{ formatClasses(assignment.classes) }}
              </td>
              <td class="px-6 py-4 font-medium text-cyan-600">
                {{ assignment.subject?.name || '-' }}
              </td>
              <td class="px-6 py-4 font-medium text-slate-800">{{ assignment.title }}</td>
              <td class="px-6 py-4 text-slate-500">{{ formatDate(assignment.due_date) }}</td>
              <td class="px-6 py-4">
                <template v-if="!is_student">
                    <Badge :variant="assignment.status === 'active' ? 'success' : 'secondary'">
                    {{ assignment.status === 'active' ? 'Aktif' : 'Nonaktif' }}
                    </Badge>
                </template>
                <template v-else>
                     <Badge :variant="getSubmissionStatus(assignment).variant">
                        {{ getSubmissionStatus(assignment).label }}
                     </Badge>
                </template>
              </td>
              <td class="px-6 py-4 text-right flex justify-end gap-2">
                <Link :href="`/offline-assignments/${assignment.id}`" class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="Detail">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                </Link>
                <template v-if="!is_student">
                    <Link :href="`/offline-assignments/${assignment.id}/edit`" class="p-2 text-amber-500 hover:bg-amber-50 rounded-lg transition-colors" title="Edit">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                    </Link>
                    <button @click="deleteAssignment(assignment.id)" class="p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors" title="Hapus">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                    </button>
                </template>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="assignments.total > 0" class="px-6 py-4 border-t border-slate-200 bg-slate-50">
        <Pagination :links="assignments.links" :from="assignments.from" :to="assignments.to" :total="assignments.total" />
      </div>
    </div>
  </div>
</template>
