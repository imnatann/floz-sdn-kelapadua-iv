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
  teachers: Object,
  filters: Object,
});

const page = usePage();
const flash = computed(() => page.props.flash || {});

const search = ref(props.filters?.search || '');
const statusFilter = ref(props.filters?.status || '');

const filteredTeachers = computed(() => {
  // Filtering is done server-side via controller, this is just for display
  return props.teachers?.data || [];
});

const applyFilters = () => {
  router.get('/staff', {
    search: search.value || undefined,
    status: statusFilter.value || undefined,
  }, { preserveState: true, replace: true });
};

const confirmDelete = (teacher) => {
  if (confirm(`Yakin ingin menghapus data ${teacher.name}?`)) {
    router.delete(`/tenant/staff/${teacher.id}`);
  }
};
</script>

<template>
  <Head title="Guru & Staff" />

  <div>
    <!-- Header -->
    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Guru & Staff</h2>
        <p class="text-sm text-slate-500 mt-0.5">Kelola data guru dan tenaga kependidikan</p>
      </div>
      <Button href="/staff/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Guru
      </Button>
    </div>

    <!-- Flash Messages -->
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 -translate-y-2"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 -translate-y-2"
    >
      <div v-if="flash.success" class="mb-4 flex items-center gap-2 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
        <svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        {{ flash.success }}
      </div>
    </Transition>
    <div v-if="flash.error" class="mb-4 flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
      <svg class="h-4 w-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      {{ flash.error }}
    </div>

    <!-- Filters -->
    <div class="mb-5 flex flex-col gap-3 sm:flex-row">
      <div class="relative flex-1">
        <SearchInput v-model="search" @input="applyFilters" placeholder="Cari nama, NIP, atau email..." />
      </div>
      <div class="w-48">
        <FormSelect v-model="statusFilter" @change="applyFilters">
          <option value="">Semua Status</option>
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
        </FormSelect>
      </div>
    </div>

    <!-- Teacher Cards Grid -->
    <div v-if="filteredTeachers.length > 0" class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="teacher in filteredTeachers"
        :key="teacher.id"
        class="group relative rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:shadow-md hover:border-slate-300"
      >
        <!-- Top row: Avatar + Actions -->
        <div class="flex items-start justify-between mb-4">
          <div class="flex items-center gap-3">
            <div class="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-orange-400 to-amber-500 shadow-sm">
              <span class="text-sm font-bold text-white">{{ teacher.name?.charAt(0)?.toUpperCase() }}</span>
            </div>
            <div>
              <h3 class="text-sm font-semibold text-slate-800 leading-tight">{{ teacher.name }}</h3>
              <p class="text-xs text-slate-400 mt-0.5">{{ teacher.nip || teacher.nuptk || 'Belum ada NIP' }}</p>
            </div>
          </div>
          <!-- Actions -->
          <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <Link
              :href="`/staff/${teacher.id}/edit`"
              class="rounded-lg p-1.5 text-slate-400 transition-colors hover:bg-orange-50 hover:text-orange-600"
              title="Edit"
            >
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
            </Link>
            <button
              @click="confirmDelete(teacher)"
              class="rounded-lg p-1.5 text-slate-400 transition-colors hover:bg-red-50 hover:text-red-500"
              title="Hapus"
            >
              <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
            </button>
          </div>
        </div>

        <!-- Details -->
        <div class="space-y-2">
          <div v-if="teacher.email" class="flex items-center gap-2 text-xs text-slate-500">
            <svg class="h-3.5 w-3.5 shrink-0 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
            {{ teacher.email }}
          </div>
          <div v-if="teacher.phone" class="flex items-center gap-2 text-xs text-slate-500">
            <svg class="h-3.5 w-3.5 shrink-0 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
            {{ teacher.phone }}
          </div>
          <div v-if="teacher.classes && teacher.classes.length" class="flex items-center gap-2 text-xs text-slate-500">
            <svg class="h-3.5 w-3.5 shrink-0 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
            Wali Kelas: {{ teacher.classes.map(c => c.name).join(', ') }}
          </div>
        </div>

        <!-- Status Badge -->
        <div class="mt-3 pt-3 border-t border-slate-100 flex items-center gap-2">
          <Badge :variant="teacher.status === 'active' ? 'success' : 'default'">
            {{ teacher.status === 'active' ? 'Aktif' : 'Nonaktif' }}
          </Badge>
          <Badge v-if="teacher.gender" variant="default">
            {{ teacher.gender === 'male' ? 'Laki-laki' : 'Perempuan' }}
          </Badge>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white py-16">
      <svg class="h-12 w-12 text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
      <h3 class="text-sm font-semibold text-slate-600 mb-1">Belum ada data guru</h3>
      <p class="text-xs text-slate-400 mb-4">Mulai tambahkan guru dan staff sekolah</p>
      <Button href="/staff/create">
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Tambah Guru Pertama
      </Button>
    </div>

    <!-- Pagination -->
    <div class="mt-6">
      <Pagination :links="teachers.links" />
    </div>
  </div>
</template>
