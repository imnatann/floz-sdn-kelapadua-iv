<script setup>
import { ref, onMounted, computed } from 'vue';
import { usePage, Link } from '@inertiajs/vue3';
import axios from 'axios';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/id'; // Import Indonesian locale

dayjs.extend(relativeTime);
dayjs.locale('id');

const page = usePage();
const user = computed(() => page.props.auth.user);

const notifications = ref([]);
const unreadCount = ref(0);
const isOpen = ref(false);
const loading = ref(false);

const toggleDropdown = () => {
    isOpen.value = !isOpen.value;
    if (isOpen.value && notifications.value.length === 0) {
        fetchNotifications();
    }
};

const fetchNotifications = async () => {
    loading.value = true;
    try {
        const response = await axios.get('/notifications/data');
        notifications.value = response.data.data;
        // Calculate unread count localy or trust backend? 
        // For now trusting the backend unread_notifications_count if passed, or counting locally
        // But backend index returns pagination objects.
        // We might want a separate call for count or rely on initial props.
    } catch (error) {
        console.error('Failed to fetch notifications', error);
    } finally {
        loading.value = false;
    }
};

const markAsRead = async (notification) => {
    if (notification.read_at) return;

    try {
        await axios.post(`/notifications/${notification.id}/mark-read`);
        notification.read_at = new Date().toISOString();
        unreadCount.value = Math.max(0, unreadCount.value - 1);
    } catch (error) {
        console.error('Failed to mark as read', error);
    }
};

const markAllRead = async () => {
    try {
        await axios.post('/notifications/mark-all-read');
        notifications.value.forEach(n => n.read_at = new Date().toISOString());
        unreadCount.value = 0;
    } catch (error) {
        console.error('Failed to mark all as read', error);
    }
};

// Listen for Real-Time Notifications
onMounted(() => {
    if (user.value) {
        // Initial fetch for count (optional, or pass via HandleInertiaRequests)
        // For now, let's just listen.
        
        window.Echo.private(`App.Models.User.${user.value.id}`)
            .notification((notification) => {
                unreadCount.value++;
                notifications.value.unshift({
                    id: notification.id,
                    data: {
                        title: notification.title,
                        message: notification.message,
                        link: notification.link,
                        type: notification.type
                    },
                    read_at: null,
                    created_at: new Date().toISOString()
                });
                
                // Play sound (optional)
                // const audio = new Audio('/notification.mp3');
                // audio.play();
            });
            
        // Fetch initial unread count if provided by backend (we should add this to HandleInertiaRequests later)
        // temporary: fetch latest
        fetchNotifications().then(() => {
             unreadCount.value = notifications.value.filter(n => !n.read_at).length;
        });
    }
});

</script>

<template>
    <div class="relative notification-dropdown">
        <!-- Backdrop to close dropdown on outside click -->
        <div v-if="isOpen" class="fixed inset-0 z-40" @click="isOpen = false" />

        <!-- Bell Icon -->
        <button 
            @click.stop="toggleDropdown"
            class="relative rounded-full p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 z-50"
        >
            <span class="sr-only">View notifications</span>
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
            </svg>
            <!-- Badge -->
            <span v-if="unreadCount > 0" class="absolute top-2 right-2 flex h-2.5 w-2.5">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"></span>
            </span>
        </button>

        <!-- Dropdown Panel -->
        <div 
            v-if="isOpen"
            class="absolute right-0 mt-2 w-80 sm:w-96 origin-top-right rounded-xl bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none z-50 transform transition-all"
        >
            <div class="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50 rounded-t-xl">
                <h3 class="text-sm font-semibold text-slate-900">Notifikasi</h3>
                <button 
                    v-if="unreadCount > 0"
                    @click="markAllRead"
                    class="text-xs font-medium text-emerald-600 hover:text-emerald-700 hover:underline"
                >
                    Tandai semua dibaca
                </button>
            </div>

            <div class="max-h-96 overflow-y-auto w-full">
                <div v-if="loading && notifications.length === 0" class="p-4 text-center text-slate-500">
                    Loading...
                </div>
                
                <div v-else-if="notifications.length === 0" class="py-8 text-center">
                    <svg class="mx-auto h-10 w-10 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                    <p class="mt-2 text-sm text-slate-500">Tidak ada notifikasi baru</p>
                </div>

                <div v-else class="divide-y divide-slate-100">
                    <div 
                        v-for="notification in notifications" 
                        :key="notification.id"
                        :class="['p-4 hover:bg-slate-50 transition-colors cursor-pointer', { 'bg-emerald-50/30': !notification.read_at }]"
                        @click="markAsRead(notification)"
                    >
                        <div class="flex gap-3">
                           <div class="flex-shrink-0 mt-0.5">
                                <span class="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100 text-blue-600">
                                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                </span>
                           </div>
                           <div class="flex-1 min-w-0">
                               <p class="text-sm font-medium text-slate-900 truncate">
                                   {{ notification.data.title }}
                                   <span v-if="!notification.read_at" class="ml-2 inline-flex items-center rounded-full bg-emerald-100 px-1.5 py-0.5 text-xs font-medium text-emerald-800">Baru</span>
                               </p>
                               <p class="text-sm text-slate-500 mt-0.5 line-clamp-2">{{ notification.data.message }}</p>
                               <p class="text-xs text-slate-400 mt-1">{{ dayjs(notification.created_at).fromNow() }}</p>
                           </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="p-2 border-t border-slate-100 bg-slate-50/50 rounded-b-xl text-center">
                 <Link href="/notifications" @click="isOpen = false" class="text-xs font-medium text-slate-500 hover:text-slate-800 block w-full py-1">
                    Lihat semua notifikasi
                 </Link>
            </div>
        </div>
    </div>
</template>
