<script setup>
import TenantLayout from '@/Layouts/TenantLayout.vue';
import { Link, router } from '@inertiajs/vue3';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  announcement: Object,
});

const deleteAnnouncement = () => {
    if (confirm('Apakah Anda yakin ingin menghapus pengumuman ini?')) {
        router.delete(`/tenant/announcements/${props.announcement.id}`);
    }
};

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
};
</script>

<template>
  <div class="mx-auto max-w-3xl">
    <!-- Back Button & Actions -->
    <div class="mb-6 flex items-center justify-between">
       <Link href="/announcements" class="flex items-center gap-2 text-sm text-slate-500 hover:text-slate-700 transition-colors">
         <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
         Kembali ke Pengumuman
       </Link>

       <div class="flex gap-2">
           <Button variant="secondary" :href="`/announcements/${announcement.id}/edit`" size="sm" class="flex items-center gap-2">
               <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
               Edit
           </Button>
           <Button variant="danger" @click="deleteAnnouncement" size="sm" class="flex items-center gap-2 bg-red-50 text-red-600 hover:bg-red-100 hover:text-red-700 border-transparent">
               <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
               Hapus
           </Button>
       </div>
    </div>

    <article class="rounded-2xl bg-white shadow-sm ring-1 ring-slate-200 overflow-hidden">
        <!-- Cover Image -->
        <div v-if="announcement.cover_image_url" class="aspect-[21/9] w-full bg-slate-100">
            <img :src="announcement.cover_image_url" class="h-full w-full object-cover" alt="Cover" />
        </div>

        <div class="p-8 sm:p-12">
            <!-- Header -->
            <header class="mb-8 border-b border-slate-100 pb-8">
                <div class="mb-4 flex flex-wrap gap-2">
                    <Badge v-if="announcement.is_pinned" color="amber" size="sm">Pinned</Badge>
                     <Badge :color="announcement.type === 'alert' ? 'red' : announcement.type === 'event' ? 'blue' : 'slate'" size="sm">
                        {{ announcement.type === 'alert' ? 'Penting' : announcement.type === 'event' ? 'Kegiatan' : 'Info' }}
                     </Badge>
                     <span class="text-sm text-slate-400">• {{ formatDate(announcement.created_at) }}</span>
                </div>
                
                <h1 class="text-3xl font-bold text-slate-900 sm:text-4xl leading-tight">
                    {{ announcement.title }}
                </h1>

                <div class="mt-6 flex items-center gap-3">
                    <div class="h-10 w-10 rounded-full bg-slate-200 overflow-hidden">
                        <img v-if="announcement.author?.avatar_url" :src="announcement.author.avatar_url" />
                         <div v-else class="flex h-full w-full items-center justify-center bg-slate-300 text-xs font-bold text-white">
                            {{ announcement.author?.name?.charAt(0) }}
                         </div>
                    </div>
                    <div>
                        <p class="text-sm font-medium text-slate-900">{{ announcement.author?.name }}</p>
                        <p class="text-xs text-slate-500">{{ announcement.author?.role }}</p>
                    </div>
                </div>
            </header>

            <!-- Content -->
            <div 
                class="prose prose-slate prose-lg max-w-none prose-img:rounded-xl prose-a:text-orange-600 hover:prose-a:text-orange-500"
                v-html="announcement.content"
            ></div>
        </div>
    </article>
  </div>
</template>
