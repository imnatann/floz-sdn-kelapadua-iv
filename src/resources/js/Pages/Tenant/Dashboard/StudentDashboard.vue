<script setup>
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import DashboardAnnouncementWidget from '@/Components/UI/DashboardAnnouncementWidget.vue';
import { Link } from '@inertiajs/vue3';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  student: Object,
  stats: Object,
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
    <div class="rounded-xl bg-gradient-to-r from-orange-500 to-amber-500 p-6 text-white shadow-lg">
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-2xl font-bold">{{ greeting() }}, {{ student.name }}! 👋</h2>
          <p class="mt-1 text-orange-50 opacity-90">Semangat belajar hari ini! Jangan lupa cek jadwal dan tugasmu.</p>
        </div>
        <div class="flex gap-2">
          <Button :href="`/students/${student.id}`" variant="secondary" size="sm" class="bg-white/10 text-white hover:bg-white/20 border-transparent">
            Profil Saya
          </Button>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
      <!-- Left Column: Stats & Quick Actions -->
      <div class="space-y-6 lg:col-span-2">
        <!-- Quick Stats Row -->
        <div class="grid grid-cols-2 gap-4 sm:grid-cols-3">
          <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
             <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Kehadiran</p>
             <p class="mt-1 text-2xl font-bold text-slate-700">{{ stats.attendance_percentage }}%</p>
             <p class="text-xs text-slate-400">Semester ini</p>
          </div>
          <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
             <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Kelas</p>
             <p class="mt-1 text-2xl font-bold text-slate-700">{{ student.class?.name || '-' }}</p>
             <p class="text-xs text-slate-400">Wali Kelas: {{ student.class?.homeroom_teacher?.name || '-' }}</p>
          </div>
          <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
             <p class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Status</p>
             <div class="mt-2">
                <Badge :color="student.status === 'active' ? 'emerald' : 'amber'">{{ student.status === 'active' ? 'Aktif' : 'Non-Aktif' }}</Badge>
             </div>
          </div>
        </div>

        <!-- Today's Schedule -->
        <Card title="Jadwal Hari Ini" subtitle="Mata pelajaran yang harus diikuti">
           <div v-if="todaysSchedules && todaysSchedules.length > 0" class="space-y-3">
              <div 
                v-for="schedule in todaysSchedules" 
                :key="schedule.id"
                class="flex items-center justify-between border-2 border-slate-900 bg-white p-3 shadow-[4px_4px_0px_0px_rgba(15,23,42,1)] transition-transform hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(15,23,42,1)]"
              >
                 <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 flex-shrink-0 items-center justify-center border-2 border-slate-900 bg-orange-100 font-bold text-slate-900">
                        {{ schedule.start_time.substring(0, 5) }}
                    </div>
                    <div>
                        <h4 class="font-bold text-slate-900 leading-tight">{{ schedule.teaching_assignment.subject.name }}</h4>
                        <p class="text-xs font-mono text-slate-600">{{ schedule.teaching_assignment.teacher.name }}</p>
                    </div>
                 </div>
                 <div class="hidden sm:block">
                    <Badge variant="outline" class="border-slate-900 text-slate-900 font-mono text-xs rounded-none">
                        {{ schedule.start_time.substring(0, 5) }} - {{ schedule.end_time.substring(0, 5) }}
                    </Badge>
                 </div>
              </div>
           </div>
           
           <div v-else class="flex flex-col items-center justify-center py-8 text-center rounded border-2 border-dashed border-slate-300">
              <span class="text-4xl opacity-50">🏖️</span>
              <p class="mt-2 text-sm font-bold text-slate-900">Tidak ada jadwal hari ini</p>
              <p class="text-xs text-slate-500">Selamat beristirahat!</p>
           </div>
        </Card>
      </div>

      <!-- Right Column: Announcements -->
      <div class="lg:col-span-1">
        <DashboardAnnouncementWidget :announcements="recentAnnouncements" />
      </div>
    </div>
  </div>
</template>
