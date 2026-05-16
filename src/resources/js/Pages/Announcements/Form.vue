<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';
import { useForm, Link } from '@inertiajs/vue3';
import Button from '@/Components/UI/Button.vue';
import TiptapEditor from '@/Components/Editor/TiptapEditor.vue';
import { computed } from 'vue';
import dayjs from 'dayjs';

defineOptions({ layout: AppLayout });

const props = defineProps({
  announcement: {
    type: Object,
    default: null,
  },
});

const form = useForm({
  title: props.announcement?.title || '',
  content: props.announcement?.content || '',
  excerpt: props.announcement?.excerpt || '',
  target_audience: props.announcement?.target_audience || 'all',
  type: props.announcement?.type || 'info',
  is_pinned: props.announcement?.is_pinned || false,
  is_published: props.announcement?.is_published !== undefined ? props.announcement.is_published : true,
});

const submit = () => {
  if (props.announcement) {
    form.put(`/announcements/${props.announcement.id}`);
  } else {
    form.post('/announcements');
  }
};

const typeLabel = computed(() => {
    const types = { info: 'Informasi', event: 'Kegiatan', alert: 'Penting' };
    return types[form.type] || form.type;
});

const audienceLabel = computed(() => {
    const audiences = { all: 'Semua Warga', teachers: 'Guru & Staff', students: 'Siswa' };
    return audiences[form.target_audience] || form.target_audience;
});
</script>

<template>
  <div class="mx-auto max-w-3xl pb-20 pt-8 px-4 sm:px-0">
    <!-- Top Actions (Sticky or just top) -->
    <div class="flex items-center justify-between mb-8">
       <div class="text-sm text-slate-500 breadcrumbs">
          <ul>
            <li><Link href="/dashboard" class="hover:text-slate-800">Dashboard</Link></li>
            <li><Link href="/announcements" class="hover:text-slate-800">Pengumuman</Link></li>
            <li><span class="text-slate-800 font-medium">{{ announcement ? 'Edit' : 'Baru' }}</span></li>
          </ul>
       </div>
       <div class="flex items-center gap-2">
          <Link href="/announcements" class="px-3 py-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors">
            Discard
          </Link>
          <Button @click="submit" :disabled="form.processing" size="sm">
            {{ form.processing ? 'Saving...' : (announcement ? 'Update' : 'Publish') }}
          </Button>
       </div>
    </div>

    <!-- Document Title -->
    <div class="mb-6">
       <input 
          v-model="form.title" 
          type="text" 
          placeholder="Judul Pengumuman" 
          class="w-full border-none bg-transparent p-0 text-4xl font-bold text-slate-800 placeholder:text-slate-300 focus:ring-0 focus:outline-none"
       />
       <p v-if="form.errors.title" class="mt-1 text-sm text-red-500">{{ form.errors.title }}</p>
    </div>

    <!-- Properties (Metadata) -->
    <div class="mb-8 space-y-2 text-sm text-slate-600 border-b border-slate-100 pb-6">
       
        <!-- Type Property -->
       <div class="flex items-center group">
          <div class="w-32 flex items-center gap-2 text-slate-400">
             <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
             <span>Type</span>
          </div>
          <div class="flex-1">
             <select v-model="form.type" class="border-none bg-transparent p-1 py-0 text-sm font-medium text-slate-700 focus:ring-0 cursor-pointer hover:bg-slate-50 rounded -ml-1">
                <option value="info">Informasi</option>
                <option value="event">Kegiatan</option>
                <option value="alert">Penting/Darurat</option>
             </select>
          </div>
       </div>

       <!-- Audience Property -->
       <div class="flex items-center group">
          <div class="w-32 flex items-center gap-2 text-slate-400">
             <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
             <span>Audience</span>
          </div>
           <div class="flex-1">
             <select v-model="form.target_audience" class="border-none bg-transparent p-1 py-0 text-sm font-medium text-slate-700 focus:ring-0 cursor-pointer hover:bg-slate-50 rounded -ml-1">
                <option value="all">Semua Warga Sekolah</option>
                <option value="teachers">Hanya Guru & Staff</option>
                <option value="students">Hanya Siswa</option>
             </select>
          </div>
       </div>

       <!-- Date Created (Read Only) -->
       <div class="flex items-center group">
          <div class="w-32 flex items-center gap-2 text-slate-400">
             <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
             <span>Date</span>
          </div>
          <div class="flex-1 px-1 text-slate-700">
            {{ dayjs().format('MMMM D, YYYY') }}
          </div>
       </div>

        <!-- Excerpt Property (Optional Text) -->
       <div class="flex items-start group">
          <div class="w-32 flex items-center gap-2 text-slate-400 pt-1">
             <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="21" y1="10" x2="3" y2="10"/><line x1="21" y1="6" x2="3" y2="6"/><line x1="21" y1="14" x2="3" y2="14"/><line x1="21" y1="18" x2="3" y2="18"/></svg>
             <span>Excerpt</span>
          </div>
          <div class="flex-1">
             <textarea 
                v-model="form.excerpt"
                rows="1"
                @input="$event.target.style.height = ''; $event.target.style.height = $event.target.scrollHeight + 'px'"
                class="w-full border-none bg-transparent p-1 py-0 text-sm text-slate-700 focus:ring-0 resize-none overflow-hidden placeholder:text-slate-300 -ml-1"
                placeholder="Empty"
             ></textarea>
          </div>
       </div>

        <!-- Options (Pinned/Published) -->
        <div class="flex items-center gap-4 pt-2">
            <label class="flex items-center gap-2 cursor-pointer text-xs text-slate-500 hover:text-slate-800 transition-colors">
                <input type="checkbox" v-model="form.is_pinned" class="rounded border-slate-300 text-slate-600 focus:ring-slate-500">
                Pin to top
            </label>
             <label class="flex items-center gap-2 cursor-pointer text-xs text-slate-500 hover:text-slate-800 transition-colors">
                <input type="checkbox" v-model="form.is_published" class="rounded border-slate-300 text-slate-600 focus:ring-slate-500">
                Publish immediately
            </label>
        </div>

    </div>

    <!-- Main Content Editor -->
    <div>
        <TiptapEditor v-model="form.content" placeholder="Press '/' for commands..." />
        <p v-if="form.errors.content" class="mt-1 text-sm text-red-500">{{ form.errors.content }}</p>
    </div>

  </div>
</template>

<style scoped>
/* Custom tweaks to make inputs look like plain text */
select {
    background-position: right 0 center !important;
}
</style>
