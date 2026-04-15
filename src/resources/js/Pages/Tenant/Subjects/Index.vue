<script setup>
import { ref, computed } from 'vue';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import SearchInput from '@/Components/UI/SearchInput.vue';
import FormSelect from '@/Components/UI/FormSelect.vue';
import Pagination from '@/Components/UI/Pagination.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  subjects: Object,
  filters: Object,
});

const page = usePage();
const flash = computed(() => page.props.flash || {});

const search = ref(props.filters?.search || '');
const categoryFilter = ref(props.filters?.category || '');
const statusFilter = ref(props.filters?.status || '');

const applyFilters = () => {
  router.get('/subjects', {
    search: search.value || undefined,
    category: categoryFilter.value || undefined,
    status: statusFilter.value || undefined,
  }, { preserveState: true, replace: true });
};

const confirmDelete = (subject) => {
  if (confirm(`Yakin ingin menghapus mata pelajaran ${subject.name}?`)) {
    router.delete(`/tenant/subjects/${subject.id}`);
  }
};

const categoryLabel = (cat) => {
  const map = { general: 'Umum', religion: 'Agama', specialty: 'Peminatan' };
  return map[cat] || cat || '-';
};
</script>

<template>
  <Head title="Mata Pelajaran" />

  <div>
    <!-- Header -->
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Mata Pelajaran</h2>
        <p class="text-sm text-slate-500 mt-0.5">Kelola daftar mata pelajaran sekolah</p>
      </div>
      <Button href="/subjects/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Mapel
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
    <div class="mb-5 flex flex-col gap-3 sm:flex-row">
      <div class="relative flex-1">
        <SearchInput v-model="search" @input="applyFilters" placeholder="Cari nama atau kode mapel..." />
      </div>
      <div class="w-48">
        <FormSelect v-model="categoryFilter" @change="applyFilters">
          <option value="">Semua Kategori</option>
          <option value="general">Umum</option>
          <option value="religion">Agama</option>
          <option value="specialty">Peminatan</option>
        </FormSelect>
      </div>
      <div class="w-48">
        <FormSelect v-model="statusFilter" @change="applyFilters">
          <option value="">Semua Status</option>
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
        </FormSelect>
      </div>
    </div>

    <!-- Table -->
    <div v-if="subjects?.data?.length > 0" class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <table class="min-w-full divide-y divide-slate-200">
        <thead class="bg-slate-50">
          <tr>
            <th class="px-5 py-3 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500">Kode</th>
            <th class="px-5 py-3 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500">Nama</th>
            <th class="px-5 py-3 text-center text-[11px] font-semibold uppercase tracking-wider text-slate-500">Jenjang</th>
            <th class="px-5 py-3 text-center text-[11px] font-semibold uppercase tracking-wider text-slate-500">KKM</th>
            <th class="px-5 py-3 text-center text-[11px] font-semibold uppercase tracking-wider text-slate-500">Kategori</th>
            <th class="px-5 py-3 text-center text-[11px] font-semibold uppercase tracking-wider text-slate-500">Status</th>
            <th class="px-5 py-3 text-right text-[11px] font-semibold uppercase tracking-wider text-slate-500">Aksi</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="s in subjects.data" :key="s.id" class="transition-colors hover:bg-slate-50/50">
            <td class="px-5 py-3.5">
              <span class="inline-flex items-center rounded-md bg-slate-100 px-2 py-0.5 text-xs font-mono font-medium text-slate-600">{{ s.code }}</span>
            </td>
            <td class="px-5 py-3.5 text-sm font-medium text-slate-800">{{ s.name }}</td>
            <td class="px-5 py-3.5 text-center text-sm text-slate-600">{{ s.education_level }}</td>
            <td class="px-5 py-3.5 text-center">
              <Badge variant="warning">{{ s.kkm }}</Badge>
            </td>
            <td class="px-5 py-3.5 text-center text-xs text-slate-500">{{ categoryLabel(s.category) }}</td>
            <td class="px-5 py-3.5 text-center">
              <Badge :variant="s.status === 'active' ? 'success' : 'default'">
                {{ s.status === 'active' ? 'Aktif' : 'Nonaktif' }}
              </Badge>
            </td>
            <td class="px-5 py-3.5 text-right">
              <div class="flex items-center justify-end gap-1">
                <Link :href="`/subjects/${s.id}/edit`" class="rounded-lg p-1.5 text-slate-400 hover:bg-orange-50 hover:text-orange-600" title="Edit">
                  <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                </Link>
                <button @click="confirmDelete(s)" class="rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-500" title="Hapus">
                  <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Empty -->
    <div v-else class="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white py-16">
      <svg class="h-12 w-12 text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
      <h3 class="text-sm font-semibold text-slate-600 mb-1">Belum ada mata pelajaran</h3>
      <p class="text-xs text-slate-400 mb-4">Tambahkan mata pelajaran untuk sekolah Anda</p>
      <Button href="/subjects/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Mapel Pertama
      </Button>
    </div>

    <!-- Pagination -->
    <div class="mt-6">
      <Pagination :links="subjects.links" />
    </div>
  </div>
</template>
