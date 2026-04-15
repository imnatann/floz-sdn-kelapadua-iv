<script setup>
import { ref, onMounted } from 'vue';
import { Head, Link, usePage } from '@inertiajs/vue3';
import TenantLayout from '@/Layouts/TenantLayout.vue';
import Button from '@/Components/UI/Button.vue';
import axios from 'axios';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/id';

dayjs.extend(relativeTime);
dayjs.locale('id');

defineOptions({ layout: TenantLayout });

const notifications = ref({ data: [], links: [] });
const loading = ref(true);

const fetchNotifications = async (url = '/notifications/data') => {
    loading.value = true;
    try {
        const response = await axios.get(url);
        notifications.value = response.data;
    } catch (error) {
        console.error('Failed to fetch notifications', error);
    } finally {
        loading.value = false;
    }
};

const markAsRead = async (notification) => {
    if (notification.read_at) return;
    try {
        await axios.post(`/tenant/notifications/${notification.id}/mark-read`);
        const index = notifications.value.data.findIndex(n => n.id === notification.id);
        if (index !== -1) {
            notifications.value.data[index].read_at = new Date().toISOString();
        }
    } catch (error) {
        console.error('Failed to mark as read', error);
    }
};

const markAllRead = async () => {
    try {
        await axios.post('/notifications/mark-all-read');
        notifications.value.data.forEach(n => n.read_at = new Date().toISOString());
    } catch (error) {
        console.error('Failed to mark all as read', error);
    }
};

onMounted(() => {
    fetchNotifications();
});
</script>

<template>
    <Head title="Notifikasi" />

    <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="mb-6 flex items-center justify-between">
            <div>
                <h2 class="text-xl font-bold text-slate-800">Notifikasi</h2>
                <p class="text-sm text-slate-500 mt-0.5">Semua aktivitas dan pemberitahuan Anda</p>
            </div>
            <Button variant="outline" @click="markAllRead">
                Tandai semua dibaca
            </Button>
        </div>

        <!-- List -->
        <div class="space-y-4">
            <div v-if="loading" class="text-center py-12">
                <svg class="h-8 w-8 animate-spin mx-auto text-slate-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                </svg>
            </div>

            <div v-else-if="notifications.data.length === 0" class="flex flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white py-16">
                 <svg class="h-12 w-12 text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                 <h3 class="text-sm font-semibold text-slate-600 mb-1">Tidak ada notifikasi</h3>
                 <p class="text-xs text-slate-400">Anda belum memiliki pemberitahuan apapun saat ini</p>
            </div>

            <div v-else class="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden divide-y divide-slate-100">
                <div 
                    v-for="notification in notifications.data" 
                    :key="notification.id"
                    :class="['p-5 transition-colors flex gap-4', notification.read_at ? 'hover:bg-slate-50' : 'bg-emerald-50/40 hover:bg-emerald-50/60']"
                >
                    <div class="flex-shrink-0 mt-1">
                        <span class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100 text-blue-600">
                             <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                        </span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <div class="flex items-start justify-between">
                            <div>
                                <h4 class="text-sm font-bold text-slate-900">
                                    {{ notification.data.title }}
                                    <span v-if="!notification.read_at" class="ml-2 inline-flex items-center rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">Baru</span>
                                </h4>
                                <p class="text-sm text-slate-600 mt-1">{{ notification.data.message }}</p>
                                <p class="text-xs text-slate-400 mt-2">{{ dayjs(notification.created_at).format('D MMMM YYYY, HH:mm') }} &bull; {{ dayjs(notification.created_at).fromNow() }}</p>
                            </div>
                            <div class="flex flex-col gap-2 ml-4">
                                <Link 
                                    v-if="notification.data.link" 
                                    :href="notification.data.link" 
                                    class="text-xs font-medium text-blue-600 hover:text-blue-700 hover:underline whitespace-nowrap"
                                    @click="markAsRead(notification)"
                                >
                                    Lihat Detail
                                </Link>
                                <button 
                                    v-if="!notification.read_at"
                                    @click="markAsRead(notification)"
                                    class="text-xs font-medium text-slate-400 hover:text-slate-600 whitespace-nowrap text-right"
                                >
                                    Tandai dibaca
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Pagination -->
            <div v-if="notifications.links && notifications.links.length > 3" class="flex justify-center mt-6">
                 <!-- Simple pagination implementation or import component -->
                 <div class="flex gap-1">
                    <button 
                        v-for="(link, i) in notifications.links" 
                        :key="i"
                        :disabled="!link.url || link.active"
                        @click="link.url && fetchNotifications(link.url)"
                        v-html="link.label"
                        :class="['px-3 py-1 rounded text-sm', link.active ? 'bg-emerald-600 text-white' : 'bg-white border hover:bg-slate-50 text-slate-600', !link.url ? 'opacity-50 cursor-not-allowed' : '']"
                    ></button>
                 </div>
            </div>
        </div>
    </div>
</template>
