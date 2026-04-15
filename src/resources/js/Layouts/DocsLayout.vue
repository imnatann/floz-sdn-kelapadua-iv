<script setup>
import { ref } from 'vue';
import { Link } from '@inertiajs/vue3';

const isSidebarOpen = ref(false);

const menu = [
    {
        title: 'Getting Started',
        items: [
            { label: 'Introduction', href: '/docs' },
            { label: 'Installation', href: '/docs#installation' },
            { label: 'Configuration', href: '/docs#configuration' },
            { label: 'Directory Structure', href: '/docs#structure' },
        ]
    },
    {
        title: 'Core Concepts',
        items: [
            { label: 'Architecture', href: '/docs#architecture' },
            { label: 'Multi-tenancy', href: '/docs#tenancy' },
            { label: 'Authentication', href: '/docs#auth' },
        ]
    },
    {
        title: 'Modules',
        items: [
            { label: 'Students', href: '/docs#students' },
            { label: 'Grading System', href: '/docs#grading' },
            { label: 'Finance', href: '/docs#finance' },
        ]
    }
];
</script>

<template>
    <div class="min-h-screen bg-[#09090b] text-slate-300 font-sans selection:bg-orange-500/30">
        
        <!-- Mobile Header -->
        <div class="lg:hidden flex items-center justify-between p-4 border-b border-slate-800 bg-[#09090b]/80 backdrop-blur sticky top-0 z-50">
            <Link href="/" class="text-xl font-bold text-white flex items-center gap-2">
                <span class="w-8 h-8 rounded-lg bg-orange-600 flex items-center justify-center text-white font-bold">F</span>
                FLOZ <span class="text-xs px-2 py-0.5 bg-slate-800 rounded-full text-slate-400">Docs</span>
            </Link>
            <button @click="isSidebarOpen = !isSidebarOpen" class="text-slate-400 hover:text-white">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
            </button>
        </div>

        <div class="flex">
            <!-- Sidebar -->
            <aside class="fixed inset-y-0 left-0 w-64 bg-[#0c0c0e] border-r border-slate-800 transform transition-transform duration-300 lg:translate-x-0 z-40 overflow-y-auto"
                   :class="isSidebarOpen ? 'translate-x-0' : '-translate-x-full'">
                
                <div class="p-6 sticky top-0 bg-[#0c0c0e] z-10 hidden lg:block">
                    <Link href="/" class="text-2xl font-bold text-white flex items-center gap-2">
                        <span class="w-8 h-8 rounded-lg bg-orange-600 flex items-center justify-center text-white font-bold text-lg">F</span>
                        FLOZ
                    </Link>
                </div>

                <nav class="px-6 py-4 space-y-8">
                    <div v-for="(group, index) in menu" :key="index">
                        <h3 class="text-sm font-bold text-slate-100 uppercase tracking-wider mb-4">{{ group.title }}</h3>
                        <ul class="space-y-2 border-l border-slate-800">
                            <li v-for="item in group.items" :key="item.label">
                                <Link :href="item.href" 
                                      class="block pl-4 py-1 text-sm text-slate-500 hover:text-orange-400 hover:border-l-2 hover:border-orange-500 -ml-[1px] transition-all"
                                      :class="{ 'text-orange-400 border-l-2 border-orange-500 font-medium': $page.url === item.href }">
                                    {{ item.label }}
                                </Link>
                            </li>
                        </ul>
                    </div>
                </nav>
            </aside>

            <!-- Backdrop -->
            <div v-if="isSidebarOpen" @click="isSidebarOpen = false" class="fixed inset-0 bg-black/50 z-30 lg:hidden"></div>

            <!-- Main Content -->
            <main class="flex-1 lg:ml-64 w-full">
                <div class="max-w-4xl mx-auto px-4 py-12 lg:px-12">
                     <slot />
                </div>
                
                <footer class="border-t border-slate-800 py-8 px-4 lg:px-12 mt-12 text-center text-slate-600 text-sm">
                    © 2026 FLOZ Open Source. Licensed under MIT.
                </footer>
            </main>
        </div>
    </div>
</template>
