<script setup>
import { Head, usePage } from '@inertiajs/vue3';
import { ref } from 'vue';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import StudentProfileTab from './Tabs/StudentProfileTab.vue';
import StudentAcademicTab from './Tabs/StudentAcademicTab.vue';
import StudentMutationTab from './Tabs/StudentMutationTab.vue';
import StudentCounselingTab from './Tabs/StudentCounselingTab.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({ 
  student: Object,
  academicHistory: Array 
});

const tabs = [
  { id: 'profile', label: 'Profil & Kesehatan', component: StudentProfileTab },
  { id: 'academic', label: 'Akademik', component: StudentAcademicTab },
  { id: 'mutation', label: 'Mutasi & Riwayat', component: StudentMutationTab },
  { id: 'counseling', label: 'Bimbingan Konseling', component: StudentCounselingTab },
];

const activeTab = ref('profile');

const statusColor = (s) => s === 'active' ? 'emerald' : s === 'graduated' ? 'blue' : 'amber';
const statusLabel = (s) => ({ active: 'Aktif', graduated: 'Lulus', transferred: 'Pindah', dropout: 'Keluar' }[s] || s);

const permissions = usePage().props.auth.permissions;
</script>

<template>
  <Head :title="student.name" />
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div class="flex items-center gap-4">
        <Button href="/students" variant="outline" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
          Kembali
        </Button>
        <div class="flex items-center gap-4">
          <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-400 to-teal-500 text-lg font-bold text-white shadow-md shadow-emerald-500/20">
            {{ student.name?.charAt(0) }}
          </div>
          <div>
            <h2 class="text-xl font-bold text-slate-800">{{ student.name }}</h2>
            <p class="mt-0.5 text-sm text-slate-400">
              NIS: {{ student.nis }}
              <span v-if="student.nisn"> · NISN: {{ student.nisn }}</span>
            </p>
          </div>
        </div>
      </div>
      <div class="flex gap-2">
        <Button v-if="permissions.manage_students" :href="`/students/${student.id}/edit`" variant="outline" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
          Edit Siswa
        </Button>
        <Button variant="primary" size="sm">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"/></svg>
          ID Card
        </Button>
      </div>
    </div>

    <!-- Quick Info Ribbon -->
    <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
      <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Kelas</p>
        <p class="mt-1 text-sm font-bold text-slate-700">{{ student.class?.name || '—' }}</p>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Status</p>
        <Badge :color="statusColor(student.status)" class="mt-1">{{ statusLabel(student.status) }}</Badge>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Wali Kelas</p>
        <p class="mt-1 text-sm font-bold text-slate-700 truncate">{{ student.class?.homeroom_teacher?.name || '—' }}</p>
      </div>
      <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Total Kredit</p>
        <p class="mt-1 text-sm font-bold text-slate-700">0 Poin</p>
      </div>
    </div>

    <!-- Tabs Navigation -->
    <div class="border-b border-slate-200">
      <nav class="-mb-px flex space-x-8 overflow-x-auto" aria-label="Tabs">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            activeTab === tab.id
              ? 'border-emerald-500 text-emerald-600'
              : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700',
            'whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium'
          ]"
        >
          {{ tab.label }}
        </button>
      </nav>
    </div>

    <!-- Tab Content -->
    <div>
      <component :is="tabs.find(t => t.id === activeTab).component" :student="student" :academic-history="academicHistory" />
    </div>
  </div>
</template>
