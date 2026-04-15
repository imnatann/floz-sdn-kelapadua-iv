<script setup>
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Card from '@/Components/UI/Card.vue';
import Button from '@/Components/UI/Button.vue';
import Badge from '@/Components/UI/Badge.vue';
import Pagination from '@/Components/UI/Pagination.vue';
import SearchInput from '@/Components/UI/SearchInput.vue';
import { Link, router } from '@inertiajs/vue3';
import { ref, watch } from 'vue';
import debounce from 'lodash/debounce';

defineOptions({ layout: TenantLayout });

const props = defineProps({
  announcements: Object,
  filters: Object,
});

const search = ref(props.filters.search || '');

watch(search, debounce((value) => {
  router.get('/announcements', { search: value }, { preserveState: true, replace: true });
}, 300));

const deleteAnnouncement = (announcement) => {
    if (confirm('Apakah Anda yakin ingin menghapus pengumuman ini?')) {
        router.delete(`/tenant/announcements/${announcement.id}`, {
            preserveScroll: true,
            onSuccess: () => {
                // Toast will be handled by layout
            }
        });
    }
};

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
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-slate-800">Pengumuman</h1>
        <p class="text-sm text-slate-500">Informasi terbaru seputar sekolah dan kegiatan.</p>
      </div>
      <div class="flex items-center gap-3">
        <SearchInput v-model="search" placeholder="Cari pengumuman..." class="w-full sm:w-64" />
        <Button href="/announcements/create" class="flex items-center gap-2">
           <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
           Buat Baru
        </Button>
      </div>
    </div>

    <!-- Grid Layout -->
    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      <Link 
        v-for="announcement in announcements.data" 
        :key="announcement.id"
        :href="`/announcements/${announcement.id}`"
        class="group relative flex flex-col overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition-all hover:shadow-md hover:border-orange-200"
      >
        <!-- Cover Image -->
        <div class="aspect-video w-full overflow-hidden bg-slate-100 relative group-hover:opacity-90 transition-opacity">
           <img 
             v-if="announcement.cover_image_url" 
             :src="announcement.cover_image_url" 
             class="h-full w-full object-cover transition-transform duration-500 group-hover:scale-105"
             alt="Cover"
           />
           <div v-else class="flex h-full w-full items-center justify-center bg-gradient-to-br from-slate-50 to-slate-100 text-slate-300">
             <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>
           </div>
           
           <!-- Delete Button (Visible on Hover) -->
           <button 
             @click.prevent="deleteAnnouncement(announcement)"
             class="absolute top-2 right-2 p-2 bg-white/90 rounded-full text-slate-400 opacity-0 group-hover:opacity-100 hover:bg-red-50 hover:text-red-600 transition-all shadow-sm z-10"
             title="Hapus Pengumuman"
           >
             <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
           </button>
        </div>

        <!-- Content -->
        <div class="flex flex-1 flex-col p-4">
           <!-- Badges -->
           <div class="mb-3 flex flex-wrap gap-2">
             <Badge v-if="announcement.is_pinned" color="amber" size="sm" class="gap-1 pl-1">
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="17" x2="12" y2="22"></line><path d="M5 17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a2 2 0 0 0 0-4H8a2 2 0 0 0 0 4h1v4.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24Z"></path></svg>
                Pinned
             </Badge>
             <Badge :color="announcement.type === 'alert' ? 'red' : announcement.type === 'event' ? 'blue' : 'slate'" size="sm">
                {{ announcement.type === 'alert' ? 'Penting' : announcement.type === 'event' ? 'Kegiatan' : 'Info' }}
             </Badge>
           </div>

           <h3 class="mb-2 text-lg font-semibold text-slate-800 line-clamp-2 group-hover:text-orange-600 transition-colors">
             {{ announcement.title }}
           </h3>
           
           <p class="mb-4 text-sm text-slate-500 line-clamp-3 flex-1">
             {{ announcement.excerpt || 'Tidak ada ringkasan.' }}
           </p>

           <!-- Footer -->
           <div class="mt-auto flex items-center justify-between border-t border-slate-100 pt-3 text-xs text-slate-400">
             <div class="flex items-center gap-2">
                <div class="h-6 w-6 rounded-full bg-slate-200 overflow-hidden">
                    <img v-if="announcement.author?.avatar_url" :src="announcement.author.avatar_url" />
                     <div v-else class="flex h-full w-full items-center justify-center bg-slate-300 text-[8px] font-bold text-white">
                        {{ announcement.author?.name?.charAt(0) }}
                     </div>
                </div>
                <span class="truncate max-w-[80px]">{{ announcement.author?.name }}</span>
             </div>
             <span>{{ formatDate(announcement.created_at) }}</span>
           </div>
        </div>
      </Link>
    </div>

    <!-- Empty State -->
    <div v-if="announcements.data.length === 0" class="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-300 bg-slate-50 py-12 text-center">
        <div class="mb-3 rounded-full bg-white p-3 shadow-sm">
             <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-slate-400"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
        </div>
        <h3 class="text-lg font-medium text-slate-900">Belum ada pengumuman</h3>
        <p class="text-sm text-slate-500">Buat pengumuman pertama untuk memberitahu warga sekolah.</p>
    </div>

    <!-- Pagination -->
    <div v-if="announcements.data.length > 0" class="mt-6 flex justify-center">
      <Pagination :links="announcements.links" />
    </div>
  </div>
</template>
