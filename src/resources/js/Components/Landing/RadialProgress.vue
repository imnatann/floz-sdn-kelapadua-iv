<script setup>
import { onMounted, ref, computed } from 'vue';

const props = defineProps({
    series: {
        type: Array, // [{ label: 'Label', percent: 75, color: 'text-green-500', hexColor: '#22c55e', gradient: ['#22c55e', '#4ade80'] }]
        default: () => []
    },
    width: { type: Number, default: 320 },
    height: { type: Number, default: 320 }
});

const isVisible = ref(false);

onMounted(() => {
    setTimeout(() => {
        isVisible.value = true;
    }, 200);
});

// Configuration
const center = 100; // viewBox 0 0 200 200
const strokeWidth = 10; // Thinner for elegance
const gap = 14; 
const maxRadius = 90; // Larger outer radius

const getRadius = (index) => maxRadius - (index * gap);
const getCircumference = (radius) => 2 * Math.PI * radius;

const tracks = computed(() => {
    return props.series.map((item, index) => {
        const radius = getRadius(index);
        const circumference = getCircumference(radius);
        const offset = circumference - (item.percent / 100) * circumference;
        
        return {
            ...item,
            radius,
            circumference,
            offset: isVisible.value ? offset : circumference,
            id: `grad-${index}`
        };
    });
});
</script>

<template>
    <div class="flex flex-col md:flex-row items-center justify-center gap-8 md:gap-12 p-6 w-full h-full bg-[#09090b]/50 rounded-2xl border border-white/5 backdrop-blur-sm">
        
        <!-- Chart Section -->
        <div :style="{ width: `${width}px`, height: `${height}px` }" class="relative flex-shrink-0 order-2 md:order-1">
             <!-- Central Text Hub -->
            <div class="absolute inset-0 flex flex-col items-center justify-center z-10 pointer-events-none">
                <h4 class="text-3xl font-black text-white tracking-tighter drop-shadow-2xl">
                    STATISTIK
                </h4>
                <span class="text-[10px] font-bold tracking-[0.3em] text-slate-500 uppercase mt-1">
                    PENDIDIKAN RI
                </span>
            </div>

            <svg class="w-full h-full -rotate-90 transform drop-shadow-[0_0_15px_rgba(0,0,0,0.5)]" viewBox="0 0 200 200">
                <defs>
                    <!-- Define Linear Gradients dynamically -->
                    <linearGradient v-for="track in tracks" :key="track.id" :id="track.id" x1="0%" y1="0%" x2="100%" y2="100%">
                         <!-- If item has gradient array, use it, else default lighter shade -->
                        <stop offset="0%" :stop-color="track.hexColor" />
                        <stop offset="100%" :stop-color="track.hexColor" stop-opacity="0.6" />
                    </linearGradient>
                </defs>

                <!-- Background Tracks (Dark Grey) -->
                <circle v-for="(track, idx) in tracks" :key="`bg-${idx}`"
                    :cx="center" :cy="center" 
                    :r="track.radius" 
                    fill="none" 
                    stroke="#1e293b" 
                    stroke-opacity="0.3"
                    :stroke-width="strokeWidth" 
                    stroke-linecap="round"
                />

                <!-- Progress Front Bars -->
                <circle v-for="(track, idx) in tracks" :key="`prog-${idx}`"
                    :cx="center" :cy="center" 
                    :r="track.radius" 
                    fill="none" 
                    :stroke="`url(#${track.id})`"
                    :stroke-width="strokeWidth" 
                    stroke-linecap="round"
                    class="transition-all duration-[2000ms] ease-[cubic-bezier(0.25,1,0.5,1)]"
                    :style="{
                        strokeDasharray: track.circumference,
                        strokeDashoffset: track.offset
                    }"
                />
            </svg>
        </div>

        <!-- Legend Section (Side Layout) -->
        <div class="flex flex-col gap-6 order-1 md:order-2 min-w-[140px]">
            <div v-for="(track, idx) in tracks" :key="idx" 
                 class="flex flex-col items-start transition-all duration-700 delay-300 group"
                 :class="isVisible ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-4'"
                 :style="{ transitionDelay: `${idx * 150}ms` }"
            >
                <!-- Label with localized indicator color -->
                <div class="flex items-center gap-2 mb-1">
                    <span class="w-2 h-2 rounded-full shadow-[0_0_8px_currentColor]" :style="{ backgroundColor: track.hexColor }"></span>
                    <span class="text-[10px] sm:text-xs font-bold uppercase tracking-wider text-slate-400 group-hover:text-white transition-colors">
                        {{ track.label }}
                    </span>
                </div>
                
                <span class="text-3xl sm:text-4xl font-black text-white leading-none tracking-tight flex items-baseline gap-1"
                      :style="{ textShadow: `0 0 20px ${track.hexColor}40` }">
                    {{ track.percent }}<span class="text-sm font-bold opacity-50">%</span>
                </span>
            </div>
        </div>
    </div>
</template>
