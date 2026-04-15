<script setup>
import { Link } from '@inertiajs/vue3';
import HeroLogos from '@/Components/Landing/HeroLogos.vue';
</script>

<template>
    <section class="relative w-full min-h-[90vh] flex flex-col items-center justify-center overflow-hidden bg-[#09090b]">
        <!-- Background Logos (Absolute) -->
        <div class="absolute inset-0 flex items-center justify-center pointer-events-none opacity-40 md:opacity-60" style="will-change: opacity;">
            <HeroLogos />
        </div>

        <!-- Fade Overlay to blend edges -->
        <div class="absolute inset-0 bg-gradient-to-b from-[#09090b] via-transparent to-[#09090b] z-10 pointer-events-none"></div>
        <div class="absolute inset-0 bg-gradient-to-r from-[#09090b] via-transparent to-[#09090b] z-10 pointer-events-none"></div>

        <!-- Content (Relative Z-20) -->
        <div class="relative z-20 container mx-auto px-4 text-center mt-20 md:mt-0">
            <h1 class="text-5xl md:text-7xl font-bold tracking-tight text-white mb-6 drop-shadow-2xl">
                Satu Platform.<br/>
                <span class="text-orange-500">Kontrol Tanpa Batas.</span>
            </h1>
            
            <p class="text-lg md:text-xl text-slate-300 max-w-2xl mx-auto mb-10 leading-relaxed drop-shadow-md">
                Buka potensi sekolah Anda dengan sistem manajemen terintegrasi. HR, Kesiswaan, dan Keuangan dalam satu dashboard.
            </p>

            <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
                <Link href="/login" 
                    class="px-8 py-4 bg-orange-600 hover:bg-orange-500 text-white rounded-full font-semibold text-lg transition-all transform hover:scale-105 shadow-[0_0_20px_rgba(249,115,22,0.4)]"
                >
                    Mulai Sekarang
                </Link>
                <button 
                    class="px-8 py-4 bg-slate-800/50 hover:bg-slate-700/50 text-white border border-slate-700 rounded-full font-semibold text-lg backdrop-blur-md transition-all"
                >
                    Lihat Demo
                </button>
            </div>
        </div>
    </section>
</template>
