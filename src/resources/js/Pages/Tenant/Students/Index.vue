<script setup>
import { Link, Head, router, usePage } from '@inertiajs/vue3';
import ImportModal from './ImportModal.vue';
import { ref, watch } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import SearchInput from '@/Components/UI/SearchInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Pagination from '@/Components/UI/Pagination.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  students: Object,
  classes: Array,
  filters: Object,
});

const search = ref(props.filters.search || '');
const classId = ref(props.filters.class_id || '');
const status = ref(props.filters.status || '');

let debounceTimer;
watch([search, classId, status], () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    router.get('/students', {
      search: search.value, class_id: classId.value, status: status.value,
    }, { preserveState: true, replace: true });
  }, 300);
});

const genderLabel = (g) => g === 'male' ? 'L' : g === 'female' ? 'P' : '—';
const statusColor = (s) => s === 'active' ? 'emerald' : s === 'graduated' ? 'blue' : 'amber';
const statusLabel = (s) => ({ active: 'Aktif', graduated: 'Lulus', transferred: 'Pindah', dropout: 'Keluar' }[s] || s);

const showImportModal = ref(false);
const permissions = usePage().props.auth.permissions;

const deleteStudent = (student) => {
    if (confirm(`Apakah Anda yakin ingin menghapus siswa ${student.name}? Semua data terkait akan dihapus.`)) {
        router.delete(`/students/${student.id}`);
    }
};
</script>

<template>
  <Head title="Data Siswa" />
  <ImportModal :show="showImportModal" @close="showImportModal = false" />
  
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Data Siswa</h2>
        <p class="mt-0.5 text-sm text-slate-400">Kelola data siswa sekolah</p>
      </div>
      <div class="flex gap-2">
        <Button v-if="permissions.manage_students" variant="secondary" size="sm" @click="showImportModal = true">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
          Import Excel
        </Button>
        <Button v-if="permissions.manage_students" href="/students/create" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
          Tambah Siswa
        </Button>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="w-64">
        <SearchInput v-model="search" placeholder="Cari nama atau NIS..." />
      </div>
      <div class="w-40">
        <FormSelect v-model="classId" label="Kelas">
          <option value="">Semua</option>
          <option v-for="c in classes" :key="c.id" :value="c.id">{{ c.name }}</option>
        </FormSelect>
      </div>
      <div class="w-40">
        <FormSelect v-model="status" label="Status">
          <option value="">Semua</option>
          <option value="active">Aktif</option>
          <option value="graduated">Lulus</option>
          <option value="transferred">Pindah</option>
        </FormSelect>
      </div>
    </div>

    <!-- Table -->
    <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100 bg-slate-50/60">
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Siswa</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">NIS</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Kelas</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">JK</th>
              <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-400">Status</th>
              <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="student in students.data"
              :key="student.id"
              class="border-b border-slate-50 transition-colors hover:bg-slate-50/50"
            >
              <td class="px-4 py-3">
                <div class="flex items-center gap-3">
                  <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-orange-100 to-amber-100 text-xs font-semibold text-orange-700">
                    {{ student.name?.charAt(0) }}
                  </div>
                  <span class="font-medium text-slate-700">{{ student.name }}</span>
                </div>
              </td>
              <td class="px-4 py-3 font-mono text-xs text-slate-500">{{ student.nis }}</td>
              <td class="px-4 py-3 text-slate-500">{{ student.class?.name || '—' }}</td>
              <td class="px-4 py-3 text-slate-500">{{ genderLabel(student.gender) }}</td>
              <td class="px-4 py-3">
                <Badge :color="statusColor(student.status)" size="sm">{{ statusLabel(student.status) }}</Badge>
              </td>
              <td class="px-4 py-3 text-right">
                <div class="flex items-center justify-end gap-1">
                  <Button :href="`/students/${student.id}`" variant="ghost" size="xs">Detail</Button>
                  <Button v-if="permissions.manage_students" :href="`/students/${student.id}/edit`" variant="ghost" size="xs">Edit</Button>
                  <Button v-if="permissions.manage_students" @click="deleteStudent(student)" variant="ghost" size="xs" class="text-red-500 hover:text-red-700 hover:bg-red-50">Hapus</Button>
                </div>
              </td>
            </tr>
            <tr v-if="!students.data?.length">
              <td colspan="6" class="px-4 py-12 text-center">
                <div class="flex flex-col items-center gap-2">
                  <span class="text-3xl">👩‍🎓</span>
                  <p class="text-sm font-medium text-slate-500">Belum ada data siswa</p>
                  <p class="text-xs text-slate-400">Mulai dengan menambahkan siswa pertama</p>
                  <Button v-if="permissions.manage_students" href="/students/create" size="sm" class="mt-2">Tambah Siswa</Button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Pagination -->
    <div class="mt-4 flex justify-center">
      <Pagination :links="students.links" />
    </div>
  </div>
</template>
