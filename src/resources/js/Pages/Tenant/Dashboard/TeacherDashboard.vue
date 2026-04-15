<script setup>
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import DashboardAnnouncementWidget from '@/Components/UI/DashboardAnnouncementWidget.vue';
import { Link } from '@inertiajs/vue3';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  teacher: Object,
  stats: Object, // { my_classes_count, my_students_count }
  recentAnnouncements: Array,
  todaysSchedules: Array,
});

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
};

const greeting = () => {
  const hour = new Date().getHours();
  if (hour < 12) return 'Selamat Pagi';
  if (hour < 15) return 'Selamat Siang';
  if (hour < 18) return 'Selamat Sore';
  return 'Selamat Malam';
};
</script>

<template>
  <div class="space-y-6">
    <!-- Welcome Header -->
    <div class="rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 p-6 text-white shadow-lg">
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-2xl font-bold">{{ greeting() }}, {{ teacher.name }}! 👨‍🏫</h2>
          <p class="mt-1 text-blue-50 opacity-90">Siap mengajar hari ini? Cek jadwal dan kelola kelas Anda.</p>
        </div>
        <div class="flex gap-2">
           <Button href="/attendance" variant="secondary" size="sm" class="bg-white/10 text-white hover:bg-white/20 border-transparent">
            Absensi Hari Ini
          </Button>
        </div>
      </div>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <div class="rounded-xl border border-blue-100 bg-blue-50 p-4">
        <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-500 text-white">
                🏫
            </div>
            <div>
                <p class="text-xs font-semibold text-blue-600">Kelas Ajar</p>
                <p class="text-xl font-bold text-slate-800">{{ stats.my_classes_count }} Kelas</p>
            </div>
        </div>
      </div>
      
      <div class="rounded-xl border border-indigo-100 bg-indigo-50 p-4">
        <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-500 text-white">
                👨‍🎓
            </div>
            <div>
                <p class="text-xs font-semibold text-indigo-600">Total Siswa</p>
                <p class="text-xl font-bold text-slate-800">{{ stats.my_students_count }} Siswa</p>
            </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
      <!-- Left Column: Quick Actions & Schedule -->
      <div class="space-y-6 lg:col-span-2">
        <Card title="Aksi Cepat">
            <div class="grid grid-cols-2 gap-4 sm:grid-cols-3">
                <Link href="/grades" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-emerald-500 hover:shadow-md">
                    <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100 text-emerald-600 transition-colors group-hover:bg-emerald-600 group-hover:text-white">
                    📊
                    </div>
                    <span class="text-xs font-medium text-slate-600 group-hover:text-emerald-600">Input Nilai</span>
                </Link>
                 <Link href="/attendance" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-blue-500 hover:shadow-md">
                    <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600 transition-colors group-hover:bg-blue-600 group-hover:text-white">
                    📝
                    </div>
                    <span class="text-xs font-medium text-slate-600 group-hover:text-blue-600">Absensi</span>
                </Link>
                 <Link href="/classes" class="group flex flex-col items-center justify-center rounded-xl border border-slate-200 bg-white p-4 transition-all hover:border-amber-500 hover:shadow-md">
                    <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600 transition-colors group-hover:bg-amber-600 group-hover:text-white">
                    📖
                    </div>
                    <span class="text-xs font-medium text-slate-600 group-hover:text-amber-600">Lihat Kelas</span>
                </Link>
            </div>
        </Card>

        <!-- Schedule -->
         <Card title="Jadwal Mengajar Hari Ini" subtitle="Kelas yang harus Anda ajar">
           <div v-if="todaysSchedules && todaysSchedules.length > 0" class="space-y-3">
              <div 
                v-for="schedule in todaysSchedules" 
                :key="schedule.id"
                class="flex items-center justify-between border-2 border-slate-900 bg-white p-3 shadow-[4px_4px_0px_0px_rgba(15,23,42,1)] transition-transform hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(15,23,42,1)]"
              >
                 <div class="flex items-center gap-3">
                    <div class="flex h-12 w-16 flex-col flex-shrink-0 items-center justify-center border-2 border-slate-900 bg-blue-100 font-bold text-slate-900 leading-none">
                        <span class="text-xs">{{ schedule.start_time.substring(0, 5) }}</span>
                    </div>
                    <div>
                        <h4 class="font-bold text-lg text-slate-900 leading-tight">{{ schedule.teaching_assignment.school_class.name }}</h4>
                        <p class="text-xs font-mono font-bold text-slate-600 uppercase">{{ schedule.teaching_assignment.subject.name }}</p>
                    </div>
                 </div>
                 <div class="text-right">
                    <Badge variant="outline" class="border-slate-900 text-slate-900 font-mono text-xs rounded-none bg-white">
                        Selesai: {{ schedule.end_time.substring(0, 5) }}
                    </Badge>
                 </div>
              </div>
           </div>
           
           <div v-else class="flex flex-col items-center justify-center py-8 text-center rounded border-2 border-dashed border-slate-300">
              <span class="text-4xl opacity-50">☕</span>
              <p class="mt-2 text-sm font-bold text-slate-900">Tidak ada jadwal mengajar</p>
              <p class="text-xs text-slate-500">Nikmati hari Anda!</p>
           </div>
        </Card>
      </div>

      <!-- Right Column: Announcements -->
      <div class="lg:col-span-1">
        <DashboardAnnouncementWidget 
            :announcements="recentAnnouncements" 
            title="Pengumuman Terbaru"
        />
      </div>
    </div>
  </div>
</template>
