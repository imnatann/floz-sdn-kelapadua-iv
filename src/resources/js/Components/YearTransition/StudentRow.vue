<script setup>
import { ref, computed, watch } from 'vue';

const props = defineProps({
    mutation: { type: Object, required: true },
    override: { type: Object, default: null },
});

const emit = defineEmits(['change']);

const defaultAction = computed(() =>
    props.mutation.from_grade_level === 6 ? 'graduate' : 'promote'
);

const action = ref(props.override?.action ?? defaultAction.value);
const reason = ref(props.override?.reason ?? '');

const isNonDefault = computed(() =>
    action.value !== defaultAction.value
);

const actions = [
    { value: 'promote', label: 'Naik Kelas' },
    { value: 'graduate', label: 'Lulus' },
    { value: 'retain', label: 'Tinggal Kelas' },
    { value: 'transfer_out', label: 'Mutasi Keluar' },
    { value: 'dropout', label: 'Putus Sekolah' },
];

const actionColorClass = computed(() => {
    switch (action.value) {
        case 'promote': return 'text-emerald-600';
        case 'graduate': return 'text-blue-600';
        case 'retain': return 'text-amber-600';
        case 'transfer_out':
        case 'dropout': return 'text-slate-500';
        default: return 'text-slate-600';
    }
});

watch([action, reason], () => {
    emit('change', {
        studentId: props.mutation.student_id,
        action: action.value,
        reason: reason.value,
        isDefault: action.value === defaultAction.value,
    });
});
</script>

<template>
    <tr class="hover:bg-orange-50/20 transition-colors">
        <!-- Name + NIS -->
        <td class="px-4 py-3">
            <div class="font-medium text-sm text-slate-800">{{ mutation.student_name }}</div>
            <div class="text-xs text-slate-400">{{ mutation.nis }}</div>
        </td>
        <!-- From class -->
        <td class="px-4 py-3 text-sm text-slate-600">
            {{ mutation.from_class_name }}
        </td>
        <!-- Action select -->
        <td class="px-4 py-3">
            <select
                v-model="action"
                class="appearance-none rounded-lg border border-slate-200 bg-white px-3 py-1.5 pr-8 text-sm focus:border-orange-400 focus:outline-none focus:ring-1 focus:ring-orange-200"
                :class="actionColorClass"
            >
                <option
                    v-for="opt in actions"
                    :key="opt.value"
                    :value="opt.value"
                >
                    {{ opt.label }}
                </option>
            </select>
        </td>
        <!-- Reason -->
        <td class="px-4 py-3">
            <input
                v-if="isNonDefault"
                v-model="reason"
                type="text"
                placeholder="Alasan (wajib)"
                class="w-full rounded-lg border border-slate-200 px-3 py-1.5 text-xs text-slate-700 focus:border-orange-400 focus:outline-none focus:ring-1 focus:ring-orange-200"
                :class="{ 'border-red-300': isNonDefault && !reason }"
            />
            <span v-else class="text-xs text-slate-300">&mdash;</span>
        </td>
        <!-- Warning -->
        <td class="px-4 py-3">
            <div v-if="mutation.warnings && mutation.warnings.length > 0" class="flex items-start gap-1">
                <svg class="h-4 w-4 text-amber-500 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <span class="text-xs text-amber-600">Perlu konfirmasi</span>
            </div>
            <div v-else-if="!mutation.from_class_id" class="flex items-start gap-1">
                <svg class="h-4 w-4 text-slate-400 shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <span class="text-xs text-slate-400">Tidak ada kelas — akan dilewati</span>
            </div>
        </td>
    </tr>
</template>
