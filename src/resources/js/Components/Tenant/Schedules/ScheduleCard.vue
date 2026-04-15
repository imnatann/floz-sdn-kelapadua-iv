<script setup>
import { computed } from 'vue';
import { useForm } from '@inertiajs/vue3';

const props = defineProps({
    schedule: {
        type: Object,
        required: true,
    },
    color: {
        type: String,
        default: 'bg-white',
    },
    canManage: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(['delete']);

const form = useForm({});

const deleteSchedule = () => {
    if (confirm('Hapus jadwal ini?')) {
        form.delete(route('tenant.schedules.destroy', props.schedule.id), {
            preserveScroll: true,
            onSuccess: () => emit('delete'),
        });
    }
};

const formatTime = (time) => {
    return time.substring(0, 5);
};
</script>

<template>
    <div 
        class="group relative mb-4 rounded-none border-2 border-slate-900 p-0 shadow-[4px_4px_0px_0px_rgba(15,23,42,1)] transition-all hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-[2px_2px_0px_0px_rgba(15,23,42,1)] bg-white flex flex-col"
    >
        <!-- Top Bar: Time & Actions -->
        <div class="flex items-center justify-between border-b-2 border-slate-900 p-2" :class="color">
            <div class="px-2 py-0.5 border-2 border-slate-900 bg-white text-[10px] font-black font-mono shadow-[2px_2px_0px_0px_rgba(15,23,42,1)]">
                {{ formatTime(schedule.start_time) }} - {{ formatTime(schedule.end_time) }}
            </div>
            
            <button 
                v-if="canManage"
                @click="deleteSchedule"
                class="flex h-5 w-5 items-center justify-center rounded-none border-2 border-transparent text-slate-500 hover:border-slate-900 hover:bg-red-500 hover:text-white transition-all opacity-0 group-hover:opacity-100"
                title="Hapus Jadwal"
            >
                &times;
            </button>
        </div>

        <!-- Main Content -->
        <div class="p-3 flex-1 flex flex-col items-center justify-center text-center space-y-2">
            <h4 class="font-black text-lg leading-tight uppercase text-slate-900">
                {{ schedule.teaching_assignment.subject.name }}
            </h4>
            
            <div class="flex items-center gap-1.5 text-xs font-bold text-slate-600 border-t-2 border-dashed border-slate-300 pt-2 w-full justify-center">
                 <span>👨‍🏫</span>
                 <span class="truncate max-w-[120px]">{{ schedule.teaching_assignment.teacher.name }}</span>
            </div>
        </div>
    </div>
</template>
