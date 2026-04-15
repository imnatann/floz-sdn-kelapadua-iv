<script setup>
import { Head, Link } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Badge from '@/Components/UI/Badge.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  courses: Array,
  is_teacher: Boolean,
});
</script>

<template>
  <Head title="Kursus" />

  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-2xl font-bold text-slate-800">Kursus</h1>
      <p class="text-sm text-slate-500 mt-1">{{ is_teacher ? 'Kelola materi dan tugas per pertemuan' : 'Akses materi dan tugas mata pelajaran' }}</p>
    </div>

    <!-- Empty State -->
    <div v-if="courses.length === 0" class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
      <div class="w-16 h-16 mx-auto bg-slate-100 rounded-2xl flex items-center justify-center mb-4">
        <svg class="w-8 h-8 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path></svg>
      </div>
      <h3 class="text-lg font-semibold text-slate-700 mb-1">Belum ada kursus</h3>
      <p class="text-sm text-slate-500">{{ is_teacher ? 'Buat penugasan mengajar terlebih dahulu untuk memulai.' : 'Belum ada mata pelajaran yang ditugaskan untuk kelas kamu.' }}</p>
    </div>

    <!-- Course Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
      <Link
        v-for="course in courses"
        :key="course.id"
        :href="`/courses/${course.id}`"
        class="group bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden hover:shadow-md hover:border-orange-300 transition-all duration-300"
      >
        <!-- Color Banner -->
        <div class="h-2.5 bg-gradient-to-r from-orange-500 to-orange-600"></div>
        
        <div class="p-5">
          <!-- Subject Name -->
          <h3 class="text-lg font-bold text-slate-800 group-hover:text-orange-600 transition-colors line-clamp-1">
            {{ course.subject?.name }}
          </h3>
          
          <!-- Class -->
          <div class="flex items-center gap-2 mt-2">
            <div class="p-1 bg-blue-50 rounded">
              <svg class="w-3.5 h-3.5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
            </div>
            <span class="text-sm text-slate-600">{{ course.school_class?.name }}</span>
          </div>

          <!-- Teacher (for students) -->
          <div v-if="!is_teacher" class="flex items-center gap-2 mt-2">
            <div class="p-1 bg-emerald-50 rounded">
              <svg class="w-3.5 h-3.5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
            </div>
            <span class="text-sm text-slate-600">{{ course.teacher?.name }}</span>
          </div>

          <!-- Academic Year -->
          <div class="flex items-center gap-2 mt-2">
            <div class="p-1 bg-amber-50 rounded">
              <svg class="w-3.5 h-3.5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
            </div>
            <span class="text-sm text-slate-500">{{ course.academic_year?.name }}</span>
          </div>

          <!-- Arrow indicator -->
          <div class="mt-4 flex justify-end">
            <div class="w-8 h-8 rounded-full bg-slate-50 group-hover:bg-orange-50 flex items-center justify-center transition-colors">
              <svg class="w-4 h-4 text-slate-400 group-hover:text-orange-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
            </div>
          </div>
        </div>
      </Link>
    </div>
  </div>
</template>
