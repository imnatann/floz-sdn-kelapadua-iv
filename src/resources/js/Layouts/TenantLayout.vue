<script setup>
import { ref, computed, watch } from 'vue';
import { Link, usePage, router } from '@inertiajs/vue3';
import Toast from '@/Components/UI/Toast.vue';
import NotificationDropdown from '@/Components/UI/NotificationDropdown.vue';

const page = usePage();
const user = computed(() => page.props.auth?.user);
const sidebarOpen = ref(true);
const mobileMenuOpen = ref(false);
const showUserMenu = ref(false);

const isStudent = computed(() => user.value?.role === 'student');

const navigation = computed(() => {
  const permissions = page.props.auth?.permissions || {};
  
  const items = [
    { name: 'Dashboard', href: '/dashboard', icon: 'dashboard', show: true },
    { name: 'Kelas', href: '/classes', icon: 'classes', show: permissions.manage_classes },
    { name: 'Mata Pelajaran', href: '/subjects', icon: 'subjects', show: permissions.manage_subjects },
    { name: 'Siswa', href: '/students', icon: 'students', show: permissions.view_all_students },
    { name: 'Guru & Staff', href: '/staff', icon: 'staff', show: permissions.manage_teachers },
    { name: 'Jadwal', href: '/schedules', icon: 'schedule', show: true },
    { type: 'divider', name: 'AKADEMIK', show: true },
    { name: 'Absensi', href: '/attendance', icon: 'attendance', show: !isStudent.value },
    { name: 'Tugas & Nilai', href: '/tasks', icon: 'assignments', show: true },
    { name: 'Ujian', href: '/exams', icon: 'homework', show: true },
    { name: 'Rapor', href: '/report-cards', icon: 'reports', show: true },
    { type: 'divider', name: 'LAINNYA', show: user.value?.role === 'school_admin' },
    { name: 'Audit Logs', href: '/audit-logs', icon: 'audit-logs', show: user.value?.role === 'school_admin' },
  ];

  return items.filter(item => item.show);
});

const isActive = (href) => page.url.startsWith(href);

const logout = () => router.post('/logout');

// Toast Logic
const toast = ref({ show: false, message: '', type: 'info' });

watch(() => page.props.flash, (flash) => {
  if (flash?.success) {
    toast.value = { show: true, message: flash.success, type: 'success' };
  } else if (flash?.error) {
    toast.value = { show: true, message: flash.error, type: 'error' };
  } else if (flash?.message) {
    toast.value = { show: true, message: flash.message, type: 'info' };
  }
}, { deep: true });

const closeToast = () => {
    toast.value.show = false;
    // Clear flash manually if needed, but usually next request clears it
};
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-orange-50/30">
    <!-- ═══════ Toast Notification ═══════ -->
    <div aria-live="assertive" class="pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6 z-[100]">
      <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
        <Toast 
            :show="toast.show" 
            :message="toast.message" 
            :type="toast.type" 
            @close="closeToast" 
        />
      </div>
    </div>

    <!-- ═══════ Desktop Sidebar ═══════ -->
    <aside
      :class="[
        sidebarOpen ? 'w-60' : 'w-[72px]',
        'fixed inset-y-0 left-0 z-50 hidden lg:flex flex-col',
        'bg-white border-r border-slate-200/80 transition-all duration-300 ease-in-out',
      ]"
    >
      <!-- Logo -->
      <div class="flex items-center gap-3 px-4 h-16 border-b border-slate-100 shrink-0">
        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-orange-500 to-orange-600 shadow-md shadow-orange-500/20">
          <span class="text-sm font-bold text-white">F</span>
        </div>
        <div v-if="sidebarOpen" class="flex flex-col overflow-hidden">
          <span class="text-base font-bold tracking-wide text-orange-600" style="font-family: 'Space Grotesk', sans-serif">FLOZ.</span>
          <span class="text-[10px] leading-tight text-slate-400">Learning Management System</span>
        </div>
      </div>

      <!-- Nav -->
      <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1">
        <span v-if="sidebarOpen" class="mb-2 block px-3 text-[10px] font-semibold uppercase tracking-widest text-slate-400">Menu</span>
        <Link
          v-for="item in navigation"
          :key="item.name"
          :href="item.href"
          :class="[
            'group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150',
            isActive(item.href)
              ? 'bg-orange-50 text-orange-700'
              : 'text-slate-500 hover:bg-slate-50 hover:text-slate-700',
          ]"
        >
          <!-- Active indicator bar -->
          <div
            v-if="isActive(item.href)"
            class="absolute -left-3 top-1/2 h-6 w-1 -translate-y-1/2 rounded-r-full bg-orange-500"
          />

          <!-- Icons -->
          <svg v-if="item.icon === 'dashboard'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
          <svg v-else-if="item.icon === 'students'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"/></svg>
          <svg v-else-if="item.icon === 'staff'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
          <svg v-else-if="item.icon === 'grades'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
          <svg v-else-if="item.icon === 'reports'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          <svg v-else-if="item.icon === 'classes'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
          <svg v-else-if="item.icon === 'subjects'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
          <svg v-else-if="item.icon === 'assignments'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
          <svg v-else-if="item.icon === 'attendance'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
          <svg v-else-if="item.icon === 'schedule'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
          <svg v-else-if="item.icon === 'announcements'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"/></svg>
          <svg v-else-if="item.icon === 'audit-logs'" class="h-5 w-5 shrink-0" :class="isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-600'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>

          <span v-if="sidebarOpen" class="truncate">{{ item.name }}</span>
        </Link>
      </nav>

      <!-- Collapse -->
      <div class="shrink-0 border-t border-slate-100 p-3">
        <button
          @click="sidebarOpen = !sidebarOpen"
          class="flex w-full items-center justify-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-slate-400 transition-colors hover:bg-slate-50 hover:text-slate-600"
        >
          <svg :class="['h-4 w-4 transition-transform', !sidebarOpen && 'rotate-180']" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7"/></svg>
          <span v-if="sidebarOpen">Tutup</span>
        </button>
      </div>
    </aside>

    <!-- ═══════ Main Content ═══════ -->
    <div :class="[sidebarOpen ? 'lg:pl-60' : 'lg:pl-[72px]', 'transition-all duration-300']">
      <!-- Topbar -->
      <header class="sticky top-0 z-40 flex h-16 items-center justify-between border-b border-slate-200/60 bg-white/80 px-6 backdrop-blur-md">
        <div class="flex items-center gap-4">
          <!-- Mobile hamburger -->
          <button @click="mobileMenuOpen = true" class="rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 lg:hidden">
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
          </button>
          <div>
            <h1 class="text-sm font-semibold text-slate-700">
              {{ page.props.currentRoute || navigation.find(n => isActive(n.href))?.name || 'Dashboard' }}
            </h1>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <!-- Notifications -->
          <NotificationDropdown />

          <!-- Profile -->
          <div class="relative">
            <button
              @click="showUserMenu = !showUserMenu"
              class="flex items-center gap-2.5 rounded-lg px-2 py-1.5 transition-colors hover:bg-slate-50"
            >
              <div class="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-orange-400 to-orange-500 shadow-sm">
                <span class="text-xs font-semibold text-white">{{ user?.name?.charAt(0)?.toUpperCase() }}</span>
              </div>
              <div class="hidden text-left sm:block">
                <p class="text-xs font-medium text-slate-700">{{ user?.name }}</p>
                <p class="text-[10px] text-slate-400">
                  {{ user?.role === 'student' ? 'Siswa' : user?.role === 'teacher' ? 'Guru' : user?.role === 'school_admin' ? 'Admin Sekolah' : 'User' }}
                </p>
              </div>
              <svg class="hidden h-4 w-4 text-slate-400 sm:block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
            </button>

            <!-- Dropdown -->
            <Transition
              enter-active-class="transition duration-100 ease-out"
              enter-from-class="scale-95 opacity-0"
              enter-to-class="scale-100 opacity-100"
              leave-active-class="transition duration-75 ease-in"
              leave-from-class="scale-100 opacity-100"
              leave-to-class="scale-95 opacity-0"
            >
              <div v-if="showUserMenu" class="absolute right-0 mt-2 w-48 origin-top-right rounded-xl border border-slate-200 bg-white p-1.5 shadow-lg shadow-slate-200/50">
                <div class="border-b border-slate-100 px-3 py-2 mb-1">
                  <p class="text-xs font-medium text-slate-700">{{ user?.name }}</p>
                  <p class="text-[10px] text-slate-400">{{ user?.email }}</p>
                </div>
                <Link
                  v-if="user?.student"
                  :href="`/students/${user.student.id}`"
                  class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs text-slate-600 transition-colors hover:bg-slate-50"
                  as="button"
                >
                  <svg class="h-4 w-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                  Profil Saya
                </Link>
                <button
                  @click="logout"
                  class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs text-red-600 transition-colors hover:bg-red-50"
                >
                  <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                  Keluar
                </button>
              </div>
            </Transition>
            <div v-if="showUserMenu" class="fixed inset-0 z-[-1]" @click="showUserMenu = false" />
          </div>
        </div>
      </header>

      <!-- Page content -->
      <main class="p-6">
        <slot />
      </main>
    </div>

    <!-- ═══════ Mobile Drawer ═══════ -->
    <Transition
      enter-active-class="transition duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div v-if="mobileMenuOpen" class="fixed inset-0 z-50 lg:hidden">
        <div class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm" @click="mobileMenuOpen = false" />
        <aside class="fixed inset-y-0 left-0 w-64 bg-white shadow-2xl">
          <div class="flex items-center gap-3 border-b border-slate-100 px-4 py-4">
            <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-orange-500 to-orange-600 shadow-md shadow-orange-500/20">
              <span class="text-sm font-bold text-white">F</span>
            </div>
            <span class="text-base font-bold tracking-wide text-orange-600" style="font-family: 'Space Grotesk', sans-serif">FLOZ.</span>
            <button @click="mobileMenuOpen = false" class="ml-auto rounded-lg p-1 text-slate-400 hover:bg-slate-100">
              <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
          </div>
          <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1">
            <span class="mb-2 block px-3 text-[10px] font-semibold uppercase tracking-widest text-slate-400">Menu</span>
            <Link
              v-for="item in navigation"
              :key="item.name"
              :href="item.href"
              @click="mobileMenuOpen = false"
              :class="[
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all',
                isActive(item.href)
                  ? 'bg-orange-50 text-orange-700'
                  : 'text-slate-500 hover:bg-slate-50',
              ]"
            >
              <svg v-if="item.icon === 'dashboard'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
              <svg v-else-if="item.icon === 'students'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"/></svg>
              <svg v-else-if="item.icon === 'staff'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
              <svg v-else-if="item.icon === 'grades'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/></svg>
              <svg v-else-if="item.icon === 'reports'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
              <svg v-else-if="item.icon === 'classes'" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" /></svg>
              <svg v-else-if="item.icon === 'subjects'" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" /></svg>
              <svg v-else-if="item.icon === 'assignments'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
              <svg v-else-if="item.icon === 'attendance'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
              <svg v-else-if="item.icon === 'schedule'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
              <svg v-else-if="item.icon === 'announcements'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" /></svg>
              <svg v-else-if="item.icon === 'homework'" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
              <svg v-else-if="item.icon === 'audit-logs'" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>
              
              {{ item.name }}
            </Link>
          </nav>
        </aside>
      </div>
    </Transition>
  </div>
</template>
