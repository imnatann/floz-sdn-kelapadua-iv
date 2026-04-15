<script setup>
import ScheduleCard from './ScheduleCard.vue';

defineProps({
    day: {
        type: String, // e.g., "Senin"
        required: true,
    },
    date: {
        type: String,
        default: '',
    },
    schedules: {
        type: Array,
        default: () => [],
    },
    isToday: {
        type: Boolean,
        default: false,
    },
    canManage: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(['add']);

const colors = [
    'bg-yellow-100', // Math/Science?
    'bg-blue-100',   // Language?
    'bg-green-100',  // Social?
    'bg-purple-100', // Arts?
    'bg-red-100',    // Sports?
    'bg-orange-100', // Others?
];

const getRandomColor = (id) => {
    // Deterministic color based on ID (simple hash)
    const hash = id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return colors[hash % colors.length];
};
</script>

<template>
    <div class="flex h-full min-w-[200px] flex-col rounded-none border-2 border-slate-900 bg-slate-50">
        <!-- Header -->
        <div 
            class="border-b-2 border-slate-900 p-3 text-center"
            :class="isToday ? 'bg-orange-600 text-white' : 'bg-white'"
        >
            <h3 class="font-black text-xl uppercase tracking-tighter">{{ day }}</h3>
            <div v-if="date" class="mt-1 flex items-center justify-center gap-1">
                <span class="inline-block px-2 py-0.5 border-2 border-current text-[10px] font-bold font-mono" :class="isToday ? 'bg-white text-orange-600 border-white' : 'bg-slate-100 border-slate-900'">
                    {{ date }}
                </span>
            </div>
        </div>

        <!-- content -->
        <div class="flex-1 space-y-4 p-4">
            <div v-if="schedules.length === 0" class="flex h-32 items-center justify-center rounded border-2 border-dashed border-slate-300 p-4 text-center">
                <p class="text-xs text-slate-400 font-mono">Kosong</p>
            </div>

            <ScheduleCard 
                v-for="schedule in schedules" 
                :key="schedule.id" 
                :schedule="schedule"
                :color="getRandomColor(schedule.id)"
                :can-manage="canManage"
            />
            
            <!-- Add Button (Ghost) -->
            <button 
                v-if="canManage"
                @click="$emit('add')"
                class="w-full rounded-none border-2 border-dashed border-slate-400 p-2 text-slate-500 transition-colors hover:border-slate-900 hover:bg-white hover:text-slate-900 flex items-center justify-center gap-2"
            >
                <span class="font-bold text-lg">+</span>
            </button>
        </div>
    </div>
</template>
