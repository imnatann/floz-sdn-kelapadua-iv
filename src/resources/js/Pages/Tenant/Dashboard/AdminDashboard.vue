<script setup>
import TenantLayout from '@/Layouts/TenantLayout.vue';
import StatCard from '@/Components/UI/StatCard.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import { Link } from '@inertiajs/vue3';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  stats: Object,
  recentAnnouncements: Array,
});

const statCards = [
  { label: 'Total Siswa', key: 'total_students', icon: '👩‍🎓', color: 'orange', bg: 'bg-orange-50' },
  { label: 'Total Guru', key: 'total_teachers', icon: '👨‍🏫', color: 'blue', bg: 'bg-blue-50' },
  { label: 'Total Kelas', key: 'total_classes', icon: '🏫', color: 'amber', bg: 'bg-amber-50' },
  { label: 'Total Staff', key: 'total_staff', icon: '👥', color: 'purple', bg: 'bg-purple-50' },
];

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
};
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-800">Dashboard Sekolah</h2>
        <p class="mt-0.5 text-sm text-slate-400">Ringkasan data dan aktivitas sekolah</p>
      </div>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        v-for="stat in statCards"
        :key="stat.key"
        :label="stat.label"
        :value="stats[stat.key] ?? 0"
        :icon="stat.icon"
        :color="stat.color"
      />
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
      <!-- Left Column: Attendance & Quick Actions -->
      <div class="space-y-6 lg:col-span-2">
        <!-- Attendance Summary -->
        <Card title="Absensi Hari Ini" subtitle="Rekap kehadiran siswa hari ini">
          <div class="grid grid-cols-2 gap-4">
            <div class="rounded-xl border border-green-100 bg-green-50/50 p-4 text-center">
              <div class="text-3xl font-bold text-green-600">{{ stats.attendance_present ?? 0 }}</div>
              <div class="text-sm font-medium text-green-800">Hadir</div>
            </div>
            <div class="rounded-xl border border-red-100 bg-red-50/50 p-4 text-center">
              <div class="text-3xl font-bold text-red-600">{{ stats.attendance_absent ?? 0 }}</div>
              <div class="text-sm font-medium text-red-800">Tidak Hadir</div>
            </div>
          </div>
          <div class="mt-4 flex justify-end">
            <Button href="/attendance" variant="outline" size="sm">
              Kelola Absensi →
            </Button>
          </div>
        </Card>

        <!-- Quick Actions -->
        <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <Link href="/students/create" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-blue-500 hover:shadow-md">
            <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600 transition-colors group-hover:bg-blue-600 group-hover:text-white">
              <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"/></svg>
            </div>
            <span class="text-xs font-medium text-slate-600 group-hover:text-blue-600">Tambah Siswa</span>
          </Link>
           <Link href="/announcements/create" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-amber-500 hover:shadow-md">
            <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600 transition-colors group-hover:bg-amber-600 group-hover:text-white">
              <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"/></svg>
            </div>
            <span class="text-xs font-medium text-slate-600 group-hover:text-amber-600">Buat Pengumuman</span>
          </Link>
          <Link href="/staff" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-indigo-500 hover:shadow-md">
             <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-indigo-100 text-indigo-600 transition-colors group-hover:bg-indigo-600 group-hover:text-white">
              <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            </div>
            <span class="text-xs font-medium text-slate-600 group-hover:text-indigo-600">Lihat Guru</span>
          </Link>
          <Link href="/report-cards" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-purple-500 hover:shadow-md">
            <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-purple-100 text-purple-600 transition-colors group-hover:bg-purple-600 group-hover:text-white">
              <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            </div>
            <span class="text-xs font-medium text-slate-600 group-hover:text-purple-600">Cetak Rapor</span>
          </Link>
        </div>
      </div>

      <!-- Right Column: Announcements -->
      <div class="lg:col-span-1">
        <Card title="Pengumuman Terbaru" class="h-full">
          <div class="space-y-4">
            <Link 
              v-for="announcement in recentAnnouncements" 
              :key="announcement.id"
              :href="`/announcements/${announcement.id}`"
              class="relative block border-l-2 border-blue-500 pl-4 py-2 transition-all hover:translate-x-1 hover:bg-slate-50 rounded-r-lg"
            >
              <div class="text-xs text-slate-400">{{ formatDate(announcement.created_at) }}</div>
              <h4 class="text-sm font-semibold text-slate-800 group-hover:text-blue-600">{{ announcement.title }}</h4>
              <p class="mt-1 line-clamp-2 text-xs text-slate-500">{{ announcement.content }}</p>
            </Link>
            <div v-if="!recentAnnouncements?.length" class="py-8 text-center">
              <p class="text-sm text-slate-400">Belum ada pengumuman.</p>
            </div>
          </div>
          <div class="mt-6 border-t border-slate-100 pt-4">
             <Link href="/announcements" class="block text-center text-sm font-medium text-orange-600 hover:text-orange-700">
              Lihat Semua Pengumuman →
            </Link>
          </div>
        </Card>
      </div>
    </div>
  </div>
</template>
