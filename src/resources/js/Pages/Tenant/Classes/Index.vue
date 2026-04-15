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
  classes: Object,
  academicYears: Array,
  filters: Object,
});

const page = usePage();
const flash = computed(() => page.props.flash || {});

const search = ref(props.filters?.search || '');
const yearFilter = ref(props.filters?.academic_year_id || '');
const statusFilter = ref(props.filters?.status || '');

const applyFilters = () => {
  router.get('/classes', {
    search: search.value || undefined,
    academic_year_id: yearFilter.value || undefined,
    status: statusFilter.value || undefined,
  }, { preserveState: true, replace: true });
};

const confirmDelete = (cls) => {
  if (confirm(`Yakin ingin menghapus kelas ${cls.name}?`)) {
    router.delete(`/tenant/classes/${cls.id}`);
  }
};
</script>

<template>
  <Head title="Manajemen Kelas" />

  <div>
    <!-- Header -->
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Manajemen Kelas</h2>
        <p class="text-sm text-slate-500 mt-0.5">Kelola kelas dan wali kelas</p>
      </div>
      <Button href="/classes/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Kelas
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
        <SearchInput v-model="search" @input="applyFilters" placeholder="Cari nama kelas..." />
      </div>
      <div class="w-48">
        <FormSelect v-model="yearFilter" @change="applyFilters">
          <option value="">Semua Tahun Ajaran</option>
          <option v-for="y in academicYears" :key="y.id" :value="y.id">{{ y.name }} {{ y.is_active ? '(Aktif)' : '' }}</option>
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

    <!-- Card Grid -->
    <div v-if="classes?.data?.length > 0" class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
      <div v-for="cls in classes.data" :key="cls.id" class="group relative flex flex-col justify-between rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:shadow-md">
        <!-- Card Header -->
        <div class="mb-4 flex items-start justify-between">
          <div>
            <h3 class="text-lg font-bold text-slate-800">{{ cls.name }}</h3>
            <p class="text-xs font-medium text-slate-500">Kelas {{ cls.grade_level }}</p>
          </div>
          <Badge :variant="cls.status === 'active' ? 'success' : 'default'">
            {{ cls.status === 'active' ? 'Aktif' : 'Nonaktif' }}
          </Badge>
        </div>

        <!-- Card Body -->
        <div class="mb-5 space-y-3">
          <!-- Academic Year -->
          <div class="flex items-center gap-2 text-sm text-slate-600">
            <svg class="h-4 w-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            <span>{{ cls.academic_year?.name || '-' }}</span>
          </div>
          
          <!-- Homeroom Teacher -->
          <div class="flex items-center gap-2 text-sm text-slate-600">
            <svg class="h-4 w-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            <span class="truncate">{{ cls.homeroom_teacher?.name || 'Belum ada wali kelas' }}</span>
          </div>

          <!-- Students -->
          <div class="flex items-center gap-2 text-sm text-slate-600">
            <svg class="h-4 w-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            <span>{{ cls.students_count }} / {{ cls.max_students }} Siswa</span>
          </div>
        </div>

        <!-- Card Footer / Actions -->
        <div class="mt-auto border-t border-slate-100 pt-4 flex items-center justify-between">
          <Link :href="`/classes/${cls.id}/edit`" class="text-sm font-medium text-orange-600 hover:text-orange-700">
            Edit Kelas
          </Link>
          <button @click="confirmDelete(cls)" class="text-sm font-medium text-slate-400 hover:text-red-600 transition-colors" title="Hapus">
            Hapus
          </button>
        </div>
      </div>
    </div>

    <!-- Empty -->
    <div v-else class="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white py-16">
      <svg class="h-12 w-12 text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
      <h3 class="text-sm font-semibold text-slate-600 mb-1">Belum ada data kelas</h3>
      <p class="text-xs text-slate-400 mb-4">Mulai tambahkan kelas untuk sekolah Anda</p>
      <Button href="/classes/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Kelas Pertama
      </Button>
    </div>

    <!-- Pagination -->
    <!-- Pagination -->
    <div class="mt-6">
      <Pagination :links="classes.links" />
    </div>
  </div>
</template>
