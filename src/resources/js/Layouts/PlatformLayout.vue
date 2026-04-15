<script setup>
import { ref, computed } from 'vue';
import { Link, usePage, router } from '@inertiajs/vue3';

const page = usePage();
const user = computed(() => page.props.auth?.user);
const sidebarOpen = ref(true);
const mobileMenuOpen = ref(false);
const userMenuOpen = ref(false);

defineProps({
  title: { type: String, default: 'Dashboard' },
});

const navigation = [
  {
    name: 'Dashboard',
    href: '/platform/dashboard',
    icon: `<svg class="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M4 5a1 1 0 011-1h4a1 1 0 011 1v5a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v2a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 16a1 1 0 011-1h4a1 1 0 011 1v3a1 1 0 01-1 1H5a1 1 0 01-1-1v-3zM14 13a1 1 0 011-1h4a1 1 0 011 1v6a1 1 0 01-1 1h-4a1 1 0 01-1-1v-6z"/></svg>`,
  },
  {
    name: 'Sekolah',
    href: '/platform/tenants',
    icon: `<svg class="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>`,
  },
  {
    name: 'Logs',
    href: '/platform/logs',
    icon: `<svg class="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>`,
  },
];

const isActive = (href) => page.url.startsWith(href);

const logout = () => router.post('/logout');
</script>

<template>
  <div class="flex min-h-screen bg-slate-50">
    <!-- Sidebar -->
    <aside
      :class="[
        'fixed inset-y-0 left-0 z-50 flex flex-col border-r border-slate-200 bg-white transition-all duration-300 hidden lg:flex',
        sidebarOpen ? 'w-60' : 'w-[68px]',
      ]"
    >
      <!-- Logo Area -->
      <div class="flex h-16 items-center gap-3 border-b border-slate-100 px-4">
        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 text-white font-bold text-sm shadow-sm shadow-orange-600/30">
          F
        </div>
        <transition name="fade">
          <span v-if="sidebarOpen" class="font-bold text-base tracking-wide text-slate-800" style="font-family: var(--font-display)">
            FLOZ<span class="text-orange-500">.</span>
          </span>
        </transition>
      </div>

      <!-- Nav Links -->
      <nav class="flex-1 space-y-0.5 px-3 py-4 overflow-y-auto">
        <p v-if="sidebarOpen" class="mb-2 px-3 text-[10px] font-semibold uppercase tracking-widest text-slate-300">Menu</p>
        <Link
          v-for="item in navigation"
          :key="item.name"
          :href="item.href"
          :class="[
            'group flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-medium transition-all duration-150',
            isActive(item.href)
              ? 'sidebar-item-active'
              : 'text-slate-500 hover:bg-slate-50 hover:text-slate-700',
          ]"
        >
          <span v-html="item.icon" :class="[isActive(item.href) ? 'text-orange-600' : 'text-slate-400 group-hover:text-slate-500']" />
          <span v-if="sidebarOpen">{{ item.name }}</span>
        </Link>
      </nav>

      <!-- Sidebar Footer -->
      <div class="border-t border-slate-100 p-3">
        <button
          @click="sidebarOpen = !sidebarOpen"
          class="flex w-full items-center justify-center gap-2 rounded-lg px-3 py-2 text-xs text-slate-400 transition-colors hover:bg-slate-50 hover:text-slate-600"
        >
          <svg :class="['h-4 w-4 transition-transform', sidebarOpen ? '' : 'rotate-180']" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
          </svg>
          <span v-if="sidebarOpen">Tutup</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <div :class="['flex flex-1 flex-col transition-all duration-300', sidebarOpen ? 'lg:pl-60' : 'lg:pl-[68px]']">
      <!-- Top Bar -->
      <header class="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-slate-200 bg-white/80 px-6 backdrop-blur-md">
        <div class="flex items-center gap-4">
          <!-- Mobile menu button -->
          <button @click="mobileMenuOpen = !mobileMenuOpen" class="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 lg:hidden">
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
          </button>
          <h1 class="text-sm font-semibold text-slate-700">{{ title }}</h1>
        </div>

        <div class="flex items-center gap-3">
          <!-- Notification -->
          <button class="relative rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600">
            <svg class="h-[18px] w-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 00-5-5.917V4a1 1 0 10-2 0v1.083A6 6 0 006 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
          </button>

          <!-- User Menu -->
          <div class="relative">
            <button @click="userMenuOpen = !userMenuOpen" class="flex items-center gap-2.5 rounded-lg px-2 py-1.5 transition-colors hover:bg-slate-50">
              <div class="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-orange-500 to-orange-600 text-xs font-semibold text-white shadow-sm">
                {{ user?.name?.charAt(0)?.toUpperCase() }}
              </div>
              <div v-if="sidebarOpen" class="hidden sm:block text-left">
                <p class="text-xs font-medium text-slate-700">{{ user?.name }}</p>
                <p class="text-[10px] text-slate-400">Administrator</p>
              </div>
              <svg class="h-3.5 w-3.5 text-slate-400 hidden sm:block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
            </button>

            <!-- Dropdown -->
            <transition name="fade">
              <div v-if="userMenuOpen" class="absolute right-0 mt-1 w-48 overflow-hidden rounded-xl border border-slate-200 bg-white py-1 shadow-lg">
                <div class="border-b border-slate-100 px-4 py-2.5">
                  <p class="text-xs font-medium text-slate-700">{{ user?.name }}</p>
                  <p class="text-[10px] text-slate-400">{{ user?.email }}</p>
                </div>
                <button @click="logout" class="flex w-full items-center gap-2 px-4 py-2 text-xs text-red-600 transition-colors hover:bg-red-50">
                  <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                  Keluar
                </button>
              </div>
            </transition>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 p-6">
        <slot />
      </main>
    </div>

    <!-- Backdrop for user menu -->
    <div v-if="userMenuOpen" @click="userMenuOpen = false" class="fixed inset-0 z-30" />

    <!-- Mobile Drawer -->
    <transition name="fade">
      <div v-if="mobileMenuOpen" class="fixed inset-0 z-50 lg:hidden">
        <div class="fixed inset-0 bg-black/40 backdrop-blur-sm" @click="mobileMenuOpen = false" />
        <aside class="fixed inset-y-0 left-0 w-60 bg-white p-4 shadow-2xl">
          <div class="mb-6 flex items-center gap-3">
            <div class="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 text-white font-bold text-sm">F</div>
            <span class="font-bold text-base text-slate-800" style="font-family: var(--font-display)">FLOZ<span class="text-orange-500">.</span></span>
          </div>
          <nav class="space-y-0.5">
            <Link
              v-for="item in navigation"
              :key="item.name"
              :href="item.href"
              @click="mobileMenuOpen = false"
              :class="[
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium',
                isActive(item.href) ? 'sidebar-item-active' : 'text-slate-500 hover:bg-slate-50',
              ]"
            >
              <span v-html="item.icon" />
              {{ item.name }}
            </Link>
          </nav>
        </aside>
      </div>
    </transition>
  </div>
</template>
