<script setup>
import { computed } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import VideoPlayer from '@/Components/VideoPlayer.vue';
import ActivityNavigation from '@/Components/UI/ActivityNavigation.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  course: Object,
  meeting: Object,
  material: Object,
  is_teacher: Boolean,
  is_student: Boolean,
});

// ---- HELPERS ----
const getMeetingLabel = (meetingNumber) => {
  if (meetingNumber === 15) return 'UTS';
  if (meetingNumber === 16) return 'UAS';
  return `Pertemuan ${meetingNumber}`;
};

// Categorize file types
const isPdf = computed(() => props.material.file_name?.toLowerCase().endsWith('.pdf'));
const isVideo = computed(() => {
  const ext = props.material.file_name?.toLowerCase().split('.').pop();
  return ['mp4', 'webm', 'ogg', 'mov'].includes(ext);
});
const isImage = computed(() => {
  const ext = props.material.file_name?.toLowerCase().split('.').pop();
  return ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
});
</script>

<template>
  <Head :title="`${material.title} - ${course.subject?.name}`" />

  <!-- Use a custom layout internally for max screen real-estate -->
  <div class="flex flex-col h-[calc(100vh-100px)] -m-4 sm:-m-6 lg:-m-8">
    
    <!-- Top Bar: Breadcrumbs & Title -->
    <div class="bg-white border-b border-slate-200 px-6 py-4 flex flex-col justify-center flex-shrink-0 z-10 shadow-sm">
      <nav class="flex text-xs text-slate-400 mb-1 truncate">
        <Link href="/dashboard" class="hover:text-blue-600 transition-colors">Dashboard</Link>
        <span class="mx-1.5">/</span>
        <Link href="/courses" class="hover:text-blue-600 transition-colors">Courses</Link>
        <span class="mx-1.5">/</span>
        <span class="truncate">{{ course.subject?.name }}</span>
        <span class="mx-1.5">/</span>
        <Link :href="`/courses/${course.id}/meetings/${meeting.id}`" class="hover:text-blue-600 transition-colors truncate">
          {{ getMeetingLabel(meeting.meeting_number) }}. {{ meeting.title }}
        </Link>
        <span class="mx-1.5">/</span>
        <span class="font-medium text-slate-700 truncate">
          {{ material.type === 'file' ? '[File]' : material.type === 'link' ? '[Link]' : '[Teks]' }} {{ material.title }}
        </span>
      </nav>
      <div class="flex items-center gap-3">
        <h1 class="text-xl font-bold text-slate-800 flex-1 truncate">{{ material.title }}</h1>
        <Badge variant="success" class="flex-shrink-0">Terselesaikan</Badge>
      </div>
    </div>

    <!-- Main Content Area (Scrollable or Full-height IFRAME) -->
    <div class="flex-1 overflow-auto bg-slate-100 flex flex-col relative">
      
      <!-- Content Viewer Engine -->
      <div class="flex-1 flex flex-col items-center justify-center p-4">
        
        <!-- TEXT -->
        <div v-if="material.type === 'text'" class="bg-white rounded-xl shadow-sm border border-slate-200 p-8 w-full max-w-4xl min-h-[50vh] prose prose-slate max-w-none">
          <p class="whitespace-pre-wrap text-slate-700 leading-relaxed">{{ material.content }}</p>
        </div>
        
        <!-- LINK -->
        <div v-else-if="material.type === 'link'" class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center w-full max-w-2xl">
          <div class="w-20 h-20 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
          </div>
          <h2 class="text-2xl font-bold text-slate-800 mb-2">Tautan Eksternal</h2>
          <p class="text-slate-500 mb-8 mx-auto w-3/4">Materi ini mengarah ke situs web eksternal. Silakan klik tombol di bawah untuk membukanya di tab baru.</p>
          <a :href="material.url" target="_blank" class="inline-flex items-center justify-center px-8 py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-md transition-all">
            Buka Tautan Materi
            <svg class="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
          </a>
        </div>

        <!-- FILE -->
        <div v-else-if="material.type === 'file'" class="w-full h-full flex flex-col items-center justify-center">
          <!-- PDF Embedded Iframe -->
          <iframe v-if="isPdf" :src="`/storage/${material.file_path}`" class="w-full h-full rounded-xl shadow-md border-0 bg-white" title="PDF Viewer"></iframe>
          
          <!-- Image Viewer -->
          <div v-else-if="isImage" class="bg-white p-4 rounded-xl shadow-sm border border-slate-200 inline-block">
            <img :src="`/storage/${material.file_path}`" class="max-w-full max-h-[70vh] rounded-lg object-contain" :alt="material.title" />
          </div>
          
          <!-- Video Viewer using existing VideoPlayer component -->
          <div v-else-if="isVideo" class="w-full max-w-5xl mx-auto rounded-xl shadow-lg border border-slate-800 overflow-hidden bg-black">
             <VideoPlayer 
                :src="`/storage/${material.file_path}`" 
                :poster="null"
             />
          </div>

          <!-- Other Files (Download Only) -->
          <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center w-full max-w-md">
            <div class="text-6xl mb-6">📦</div>
            <h2 class="text-xl font-bold text-slate-800 mb-2">{{ material.file_name }}</h2>
            <p class="text-slate-500 text-sm mb-6">Format file ini tidak dapat ditampilkan langsung. Silakan unduh untuk melihatnya.</p>
            <a :href="`/storage/${material.file_path}`" target="_blank" class="inline-flex items-center justify-center px-6 py-2.5 bg-orange-600 hover:bg-orange-700 text-white font-semibold rounded-lg shadow-sm transition-all text-sm">
              Unduh File
              <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
            </a>
          </div>
        </div>

      </div>
    </div>

    <!-- Bottom Navigation Bar (Prev / Dropdown / Next) -->
    <ActivityNavigation 
      :meeting="meeting" 
      :currentActivityId="material.id" 
      currentActivityType="material" 
    />

  </div>
</template>
