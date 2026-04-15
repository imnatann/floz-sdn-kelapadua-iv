<script setup>
import { Head, Link } from '@inertiajs/vue3';
import { defineAsyncComponent } from 'vue';
import HeroSection from '@/Components/Landing/HeroSection.vue';

// Lazy load heavy components below the fold
const LandingFeatures = defineAsyncComponent(() => 
  import('@/Components/Landing/LandingFeatures.vue')
);
const DeveloperProfile = defineAsyncComponent(() => 
  import('@/Components/Landing/DeveloperProfile.vue')
);
const TerminalSection = defineAsyncComponent(() => 
  import('@/Components/Landing/TerminalSection.vue')
);
const CommunitySection = defineAsyncComponent(() => 
  import('@/Components/Landing/CommunitySection.vue')
);
const Footer = defineAsyncComponent(() => 
  import('@/Components/Landing/Footer.vue')
);
</script>

<template>
    <Head title="FLOZ LMS - Solusi Sekolah Modern" />

    <div class="min-h-screen bg-[#09090b] text-white selection:bg-orange-500 selection:text-white">
        
        <!-- Navbar (Simplified for now, can be extracted later) -->
        <nav class="fixed w-full z-50 bg-[#09090b]/80 backdrop-blur-md border-b border-white/5">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex justify-between h-16 items-center">
                    <div class="flex items-center gap-2">
                        <!-- Simple Brand Logic if needed, or just text for now -->
                        <span class="text-xl font-bold tracking-tighter">FLOZ</span>
                    </div>
                    <div class="flex items-center gap-4">
                        <Link :href="route('login')" class="text-sm font-semibold text-slate-300 hover:text-white transition-colors">
                            Login Admin
                        </Link>
                    </div>
                </div>
            </div>
        </nav>

        <!-- New Rotating Logo Hero -->
        <HeroSection />

        <!-- Existing Features Section (Mastra Style) -->
        <LandingFeatures />

        <!-- Developer Profile (GitHub Style) -->
        <DeveloperProfile />

        <!-- Quick Start / Terminal Section -->
        <TerminalSection />

        <!-- Community Section (Bento Grid) -->
        <CommunitySection />

        <!-- Footer -->
        <Footer />
    </div>
</template>



