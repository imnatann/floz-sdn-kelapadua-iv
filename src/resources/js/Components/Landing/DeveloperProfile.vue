<script setup>
import { Link } from '@inertiajs/vue3';
import { onMounted, ref } from 'vue';

// Animation state
const isVisible = ref(false);
onMounted(() => {
    setTimeout(() => isVisible.value = true, 100);
});

// Mock Data
const profile = {
    name: 'Tokaf',
    username: 'tokaf-dev',
    bio: 'Fullstack Developer specializing in Laravel & Vue. Building scalable systems for modern education.',
    avatar: 'https://ui-avatars.com/api/?name=Tokaf&background=18181b&color=f97316&size=256&font-size=0.33', // Darker theme avatar
    location: 'Indonesia',
    email: 'contact@floz.id',
    website: 'https://floz.id',
};

// SVG Paths for "Cute/Sticker" Icons
const techStacks = [
    { 
        name: 'Laravel', 
        color: '#FF2D20', 
        bg: 'bg-red-500/10',
        border: 'border-red-500/20',
        viewBox: '0 0 24 24',
        path: '<path d="M7.288 3.52c-.66.697-3.95 4.195-5.91 10.04a20 20 0 0 0-1.282 5.5c-.09.84.18 2.05.69 2.51l.05.04.09-.07c.85-.72 2.89-2.28 4.2-2.28 2.39 0 4.15 1.57 6.09 3.3.08.06.15.14.23.21l.13.1c1.88 1.48 3.99 3.14 7.6 1.05.4-.23.83-.49 1.25-.78.13-.08.25-.17.38-.26 3.12-2.13 6.01-4.8 1.58-15.89-.35-.87-1.12-2.73-1.67-4.11a1.05 1.05 0 0 0-1.93.01c-.55 1.37-1.32 3.23-1.66 4.1-.73 1.83-1.57 3.33-2.49 4.38-2.67-2.61-4.76-5.46-5.83-6.9 0 0-.8-1.07-1.48-.94" fill="currentColor"/>'
    },
    { 
        name: 'Vue.js', 
        color: '#42B883', 
        bg: 'bg-green-500/10',
        border: 'border-green-500/20', 
        viewBox: '0 0 24 24',
        path: '<path d="M2 3h3.5l6.5 11 6.5-11H22L12 20 2 3zm10 8l-2.5-4.5H6L12 16l6-8.5h-3.5L12 11z" fill="currentColor"/>'
    },
    { 
        name: 'Tailwind', 
        color: '#38BDF8', 
        bg: 'bg-cyan-500/10',
        border: 'border-cyan-500/20', 
        viewBox: '0 0 24 24',
        path: '<path d="M12.001 5.4c-4.8 0-8.8 3.2-10 7.8 2.8-2.6 6-2.2 8.2 0l.6.6c2.2 2.2 5.6 2.4 8.2-.2 1.4-1.4 2-3 2-4.6-2.4 2.2-5.4 2-7.4 0l-.6-.6c-2.4-2.4-6.4-2.6-9.6.2l-.2-.2c1.2-1.8 4.8-4.4 8.8-3zm9 6c-3.6 0-6.6 2.2-8.6 5.2 2.6-1.4 5.6-1 7.6 1l.6.6c2.4 2.4 6.4 2.6 9.6-.2l.2.2c-1.2 1.8-4.8 4.4-8.8 3-4.8 0-8.8-3.2-10-7.8 2.8 2.6 6 2.2 8.2 0l.6-.6c1.6-1.6 4.3-2 6.6-1.4z" fill="currentColor"/>'
    },
    { 
        name: 'MySQL', 
        color: '#4479A1', 
        bg: 'bg-blue-500/10',
        border: 'border-blue-500/20', 
        viewBox: '0 0 24 24',
        path: '<path d="M2.5 12a.5.5 0 0 1 .5-.5h21a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5v-1zm0-4a.5.5 0 0 1 .5-.5h21a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5V8zm0-4a.5.5 0 0 1 .5-.5h21a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5V4zM12 17c-4.418 0-8 2.239-8 5 0 .235.026.467.076.693C5.908 21.6 8.784 21 12 21c3.216 0 6.092.601 7.924 1.693.05-.226.076-.458.076-.693 0-2.761-3.582-5-8-5z" fill="currentColor"/>'
    },
    { 
        name: 'Docker', 
        color: '#2496ED', 
        bg: 'bg-blue-400/10',
        border: 'border-blue-400/20', 
        viewBox: '0 0 24 24',
        path: '<path d="M13.983 11.078h2.119v2.12h-2.12v-2.12zm-2.918 0h2.12v2.12h-2.12v-2.12zm-5.834 0h2.12v2.12h-2.12v-2.12zm-2.917 0h2.12v2.12H2.314v-2.12zm5.834-2.916h2.12v2.12h-2.12v-2.12zm-2.917 0h2.12v2.12h-2.12v-2.12zm5.834 0h2.12v2.12h-2.12v-2.12zm-2.917-2.917h2.12v2.12h-2.12v-2.12zm8.75 8.75h2.12v2.12h-2.12v-2.12zm-2.917 0h2.12v2.12h-2.12v-2.12zM23.18 12.3c-.636 0-1.22.12-1.745.337V7.16h-1.658v3.424c-.044.004-.085.015-.129.015-1.131 0-2.048.916-2.048 2.047 0 .987.701 1.805 1.633 1.999.117.766.778 1.357 1.578 1.357.653 0 1.22-.392 1.48-0.957.275.08.566.125.87.125 1.71 0 3.1-1.39 3.1-3.1s-1.39-3.411-3.1-4.183z" fill="currentColor"/>'
    },
    { 
        name: 'Inertia', 
        color: '#9553E9', 
        bg: 'bg-purple-500/10',
        border: 'border-purple-500/20', 
        viewBox: '0 0 24 24',
        path: '<path d="M6.5 4.5L12 2l5.5 2.5v15L12 22l-5.5-2.5v-15z" stroke="currentColor" stroke-width="2" fill="none"/><path d="M12 8l3 1.5v5L12 16l-3-1.5v-5l3-1.5z" fill="currentColor"/>' 
    },
];

const experienceTimeline = [
    { year: '2018', title: 'SMK Teknik Komputer', description: 'Memulai perjalanan coding dengan PHP Native & Basic Networking.', type: 'education' },
    { year: '2021', title: 'Start Kuliah IT', description: 'Mendalami DSA, OOP, dan System Design. Mulai freelance project.', type: 'education' },
    { year: '2022', title: 'Magang Fullstack @ TechCorp', description: 'Mengembangkan modul HRIS menggunakan CodeIgniter 4.', type: 'work' },
    { year: '2023', title: 'Project FLOZ LMS', description: 'Inisiasi project FLOZ sebagai solusi manajemen sekolah modern.', type: 'project' },
    { year: '2024', title: 'Freelance Senior Dev', description: 'Menangani berbagai project skala enterprise dengan Laravel & Vue.', type: 'work' },
    { year: 'Now', title: 'Building the Future', description: 'Fokus penuh pada pengembangan ekosistem produk digital.', type: 'current' },
];

</script>

<template>
    <section class="py-24 bg-[#0d1117] text-slate-300 font-sans border-t border-slate-800 relative overflow-hidden">
        
        <!-- Animated Background Mesh -->
        <div class="absolute inset-0 z-0 opacity-10 pointer-events-none">
            <div class="absolute top-0 left-0 w-96 h-96 bg-orange-500 rounded-full blur-[100px] animate-blob"></div>
            <div class="absolute bottom-0 right-0 w-96 h-96 bg-purple-500 rounded-full blur-[100px] animate-blob animation-delay-2000"></div>
        </div>

        <div class="container mx-auto px-4 max-w-6xl relative z-10 transition-all duration-1000 transform"
             :class="isVisible ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'">
            
            <!-- Creative Heading -->
            <div class="text-center mb-16 px-4">
                <div class="inline-block relative">
                    <span class="text-xs font-mono text-orange-400 tracking-[0.2em] uppercase mb-2 block animate-pulse">
                        &lt; THE ARCHITECT /&gt;
                    </span>
                    <div class="absolute -inset-1 bg-orange-500/20 blur-sm rounded-lg opacity-50"></div>
                </div>
                
                <h2 class="text-4xl md:text-5xl font-extrabold text-white mb-6 tracking-tight">
                    Siapa di balik layar <span class="text-transparent bg-clip-text bg-gradient-to-r from-orange-400 via-pink-500 to-red-500">FLOZ?</span>
                </h2>
                <p class="text-slate-400 text-lg max-w-2xl mx-auto font-light leading-relaxed">
                    Bukan sekadar kode. Ini adalah seni menerjemahkan masalah menjadi solusi elegan.
                </p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-12 gap-8">
                
                <!-- Left Column: Bio (GitHub Sidebar Enhanced) -->
                <div class="md:col-span-12 lg:col-span-3 flex flex-col gap-6">
                    <div class="relative group mx-auto lg:mx-0 w-64 lg:w-full">
                        <!-- Holographic/Glowing Border -->
                        <div class="absolute -inset-0.5 bg-gradient-to-br from-orange-500 via-purple-500 to-blue-500 rounded-full opacity-75 group-hover:opacity-100 blur transition duration-1000 group-hover:duration-200 animate-tilt"></div>
                        
                        <img :src="profile.avatar" alt="Avatar" 
                             class="relative w-full aspect-square rounded-full border-4 border-[#0d1117] shadow-xl transition-transform duration-500 group-hover:scale-[1.02]">
                        
                        <!-- Status Badge with Animation -->
                        <div class="absolute bottom-4 right-6 w-10 h-10 bg-[#0d1117] rounded-full flex items-center justify-center border border-slate-700 shadow-lg z-10 hover:scale-110 transition-transform cursor-help group-hover:animate-bounce" title="Focusing">
                            <span class="text-xl">🔥</span>
                        </div>
                    </div>

                    <div class="text-center lg:text-left">
                        <h2 class="text-3xl font-bold text-white mb-1">{{ profile.name }}</h2>
                        <p class="text-xl font-light text-slate-500">{{ profile.username }}</p>
                    </div>

                    <p class="text-base text-white leading-relaxed text-center lg:text-left">
                        {{ profile.bio }}
                    </p>

                    <div class="flex flex-col gap-3 text-sm text-slate-400 border-t border-slate-800 pt-6">
                        <div class="flex items-center gap-3 hover:text-white transition-colors">
                            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            {{ profile.location }}
                        </div>
                        <div class="flex items-center gap-3 group/link">
                            <svg class="w-5 h-5 text-slate-500 group-hover/link:text-orange-500 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                            <a :href="'mailto:' + profile.email" class="hover:text-orange-400 transition-colors">{{ profile.email }}</a>
                        </div>
                        <div class="flex items-center gap-3 group/link">
                            <svg class="w-5 h-5 text-slate-500 group-hover/link:text-blue-500 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
                            <a :href="profile.website" target="_blank" class="hover:text-blue-400 transition-colors">{{ profile.website }}</a>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Main Content -->
                <div class="md:col-span-12 lg:col-span-9 flex flex-col gap-8">
                    
                    <!-- Section: Tech Stack (Cute Sticker Style) -->
                    <div class="border border-slate-800 rounded-xl bg-[#0d1117] p-8 relative group overflow-hidden">
                        <!-- Glass effect highlight -->
                        <div class="absolute inset-0 bg-white/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"></div>
                        
                        <div class="flex items-center justify-between mb-6 relative z-10">
                            <div class="flex items-center gap-2">
                                <span class="text-xl">🛠️</span>
                                <h3 class="text-base font-bold text-white">Tech Arsenal</h3>
                            </div>
                            <!-- Fake "Edit" button for GitHub feel -->
                            <div class="px-2 py-1 rounded-md bg-slate-800 border border-slate-700 text-xs text-slate-400 hover:text-white cursor-not-allowed select-none">
                                Edit Pin
                            </div>
                        </div>
                        
                        <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-6">
                            <div v-for="tech in techStacks" :key="tech.name" class="group/icon flex flex-col items-center gap-3 cursor-pointer">
                                <!-- Sticker-like Icon Container -->
                                <div class="w-16 h-16 md:w-20 md:h-20 rounded-2xl flex items-center justify-center transition-all duration-300 transform group-hover/icon:-translate-y-2 group-hover/icon:rotate-3 shadow-lg"
                                     :class="[tech.bg, tech.border]"
                                     :style="{ boxShadow: `0 0 20px ${tech.color}40`, borderStyle: 'solid', borderWidth: '2px' }"
                                >
                                    <svg 
                                        :viewBox="tech.viewBox" 
                                        class="w-8 h-8 md:w-10 md:h-10 fill-current transition-all duration-300"
                                        :style="{ color: tech.color }"
                                        v-html="tech.path">
                                    </svg>
                                </div>
                                <span class="text-xs font-bold text-slate-400 group-hover/icon:text-white transition-colors"
                                      :style="{ color: tech.color }">
                                    {{ tech.name }}
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Section: Experience Timeline (Contribution Graph Style) -->
                    <div class="border border-slate-800 rounded-xl bg-[#0d1117] p-8">
                        <div class="flex items-center justify-between mb-8">
                            <div class="flex items-center gap-2">
                                <h3 class="text-base font-bold text-white">Experience Timeline</h3>
                                <span class="px-2 py-0.5 rounded-full bg-slate-800 text-slate-400 text-xs border border-slate-700">2026</span>
                            </div>
                            <div class="flex items-center gap-1 text-xs text-slate-500">
                                <span class="hidden sm:inline">Contribution Settings</span>
                                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z"></path></svg>
                            </div>
                        </div>

                        <!-- Timeline "Graph" -->
                        <div class="relative border-l-2 border-slate-800 ml-4 space-y-10 pb-4">
                            <div v-for="(exp, index) in experienceTimeline" :key="index" 
                                 class="relative pl-10 group"
                                 :style="{ animationDelay: `${index * 100}ms` }">
                                
                                <!-- Timeline Dot / Node -->
                                <div class="absolute -left-[9px] top-1 w-5 h-5 rounded-full border-4 border-[#0d1117] transition-all duration-300 group-hover:scale-125 group-hover:shadow-[0_0_10px_rgba(34,197,94,0.6)]"
                                    :class="exp.type === 'current' ? 'bg-green-500 animate-pulse' : 'bg-slate-700 group-hover:bg-green-500'"
                                ></div>

                                <!-- Connecting Line Highlight -->
                                <div class="absolute -left-[2px] top-6 bottom-[-40px] w-0.5 bg-gradient-to-b from-green-500 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" v-if="index !== experienceTimeline.length - 1"></div>

                                <div class="flex flex-col sm:flex-row gap-1 sm:items-baseline justify-between">
                                    <h4 class="text-lg font-bold text-slate-300 group-hover:text-green-400 transition-colors">
                                        {{ exp.title }}
                                    </h4>
                                    <span class="text-xs font-mono px-2 py-1 rounded bg-slate-800 text-slate-400 border border-slate-700 group-hover:border-green-500/50 transition-colors">{{ exp.year }}</span>
                                </div>
                                <p class="text-sm text-slate-500 mt-2 leading-relaxed group-hover:text-slate-300 transition-colors">
                                    {{ exp.description }}
                                </p>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    </section>
</template>

<style scoped>
@keyframes blob {
    0% { transform: translate(0px, 0px) scale(1); }
    33% { transform: translate(30px, -50px) scale(1.1); }
    66% { transform: translate(-20px, 20px) scale(0.9); }
    100% { transform: translate(0px, 0px) scale(1); }
}
.animate-blob {
    animation: blob 7s infinite;
}
.animation-delay-2000 {
    animation-delay: 2s;
}
.animate-tilt {
    animation: tilt 10s infinite linear;
}
@keyframes tilt {
    0%, 50%, 100% { transform: rotate(0deg); }
    25% { transform: rotate(1deg); }
    75% { transform: rotate(-1deg); }
}
</style>
