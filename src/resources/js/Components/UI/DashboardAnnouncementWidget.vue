<script setup>
import { Link } from '@inertiajs/vue3';
import Card from '@/Components/UI/Card.vue';
import { computed } from 'vue';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/id';

dayjs.extend(relativeTime);
dayjs.locale('id');

const props = defineProps({
    announcements: {
        type: Array,
        default: () => [],
    },
    title: {
        type: String,
        default: 'Pengumuman Sekolah',
    },
    viewAllLink: {
        type: String,
        default: '/tenant/announcements',
    },
});

const formattedAnnouncements = computed(() => {
    return props.announcements.map(announcement => {
        // Strip HTML tags if excerpt is missing, fallback to empty string
        const cleanContent = announcement.excerpt || announcement.content.replace(/<[^>]*>/g, '');
        
        return {
            ...announcement,
            formattedDate: dayjs(announcement.created_at).fromNow(),
            cleanContent: cleanContent.length > 100 ? cleanContent.substring(0, 100) + '...' : cleanContent,
        };
    });
});
</script>

<template>
    <Card :title="title" class="h-full flex flex-col">
        <div class="flex-1 overflow-y-auto px-1">
            <div v-if="formattedAnnouncements.length > 0" class="divide-y divide-slate-100">
                <Link 
                    v-for="announcement in formattedAnnouncements" 
                    :key="announcement.id" 
                    :href="route('announcements.show', announcement.id)"
                    class="group block py-3 first:pt-0 last:pb-0"
                >
                    <div class="flex items-start gap-3">
                        <!-- Icon -->
                        <div class="mt-1 flex-shrink-0">
                            <span v-if="announcement.is_pinned" class="flex h-8 w-8 items-center justify-center rounded-full bg-orange-100 text-orange-600 transition-colors group-hover:bg-orange-200">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" /></svg>
                            </span>
                            <span v-else class="flex h-8 w-8 items-center justify-center rounded-full bg-slate-100 text-slate-500 transition-colors group-hover:bg-slate-200 group-hover:text-slate-700">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" /></svg>
                            </span>
                        </div>
                        
                        <!-- Content -->
                        <div class="min-w-0 flex-1">
                            <div class="flex items-center justify-between gap-2">
                                <h4 class="truncate text-sm font-semibold text-slate-900 group-hover:text-orange-600 transition-colors">
                                    {{ announcement.title }}
                                </h4>
                                <span class="flex-shrink-0 text-[10px] text-slate-400">
                                    {{ announcement.formattedDate }}
                                </span>
                            </div>
                            <p class="mt-1 line-clamp-2 text-xs text-slate-500 group-hover:text-slate-600">
                                {{ announcement.cleanContent }}
                            </p>
                        </div>
                    </div>
                </Link>
            </div>

            <!-- Empty State -->
            <div v-else class="flex h-full flex-col items-center justify-center py-8 text-center">
                <div class="rounded-full bg-slate-50 p-3">
                    <svg class="h-6 w-6 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" /></svg>
                </div>
                <p class="mt-2 text-xs font-medium text-slate-500">Belum ada pengumuman</p>
            </div>
        </div>

        <!-- Footer Link -->
        <div class="mt-auto pt-4 border-t border-slate-100">
            <Link :href="viewAllLink" class="group flex items-center justify-center gap-1 text-xs font-medium text-slate-500 hover:text-orange-600 transition-colors">
                Lihat Semua Pengumuman
                <svg class="h-3 w-3 transition-transform group-hover:translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" /></svg>
            </Link>
        </div>
    </Card>
</template>
