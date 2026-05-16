<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue';
import { Head } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';
import SelectYears from './Steps/SelectYears.vue';
import ClassStructure from './Steps/ClassStructure.vue';
import StudentReview from './Steps/StudentReview.vue';
import Preview from './Steps/Preview.vue';
import Confirm from './Steps/Confirm.vue';

defineOptions({ layout: AppLayout });

const props = defineProps({
    academicYears: { type: Array, default: () => [] },
    initialTargetAcademicYearId: { type: [Number, String, null], default: null },
});

const currentStep = ref(1);
const totalSteps = 5;

const stepLabels = [
    'Pilih Tahun Ajaran',
    'Struktur Kelas',
    'Review Siswa',
    'Pratinjau',
    'Konfirmasi',
];

const wizardData = ref({
    sourceAyId: null,
    targetAyId: props.initialTargetAcademicYearId ? Number(props.initialTargetAcademicYearId) : null,
    newClasses: [],
    overrides: {},
    plan: null,
});

// W-03: beforeunload guard — warn user when navigating away mid-wizard
function beforeUnloadHandler(e) {
    e.preventDefault();
    e.returnValue = 'Proses transisi belum selesai. Yakin ingin meninggalkan halaman ini?';
    return e.returnValue;
}

watch(currentStep, (step) => {
    if (step >= 2) {
        window.addEventListener('beforeunload', beforeUnloadHandler);
    } else {
        window.removeEventListener('beforeunload', beforeUnloadHandler);
    }
});

onUnmounted(() => {
    window.removeEventListener('beforeunload', beforeUnloadHandler);
});

function next() {
    currentStep.value = Math.min(currentStep.value + 1, totalSteps);
}
function back() {
    currentStep.value = Math.max(currentStep.value - 1, 1);
}

// Remove guard on Step 5 confirm success (called from Confirm component via event)
function onTransitionComplete() {
    window.removeEventListener('beforeunload', beforeUnloadHandler);
}
</script>

<template>
    <Head title="Transisi Tahun Ajaran" />
    <div class="max-w-5xl mx-auto">
        <!-- Header -->
        <div class="mb-6">
            <h2 class="text-xl font-bold text-slate-800">Transisi Tahun Ajaran</h2>
            <p class="text-sm text-slate-500 mt-0.5">Proses kenaikan kelas otomatis akhir tahun ajaran</p>
        </div>

        <!-- Step indicator -->
        <div class="flex items-center mb-8">
            <template v-for="(label, i) in stepLabels" :key="i">
                <div class="flex items-center gap-2 shrink-0">
                    <div
                        :class="[
                            'w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold border-2 transition-all',
                            currentStep === i + 1
                                ? 'bg-orange-500 border-orange-500 text-white shadow-md shadow-orange-500/30'
                                : currentStep > i + 1
                                    ? 'bg-emerald-500 border-emerald-500 text-white'
                                    : 'bg-white border-slate-300 text-slate-400',
                        ]"
                    >
                        <svg v-if="currentStep > i + 1" class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                        </svg>
                        <span v-else>{{ i + 1 }}</span>
                    </div>
                    <span
                        class="text-sm hidden md:block truncate max-w-[140px]"
                        :class="currentStep === i + 1 ? 'font-semibold text-slate-800' : currentStep > i + 1 ? 'text-emerald-600 font-medium' : 'text-slate-400'"
                    >
                        {{ label }}
                    </span>
                </div>
                <div
                    v-if="i < stepLabels.length - 1"
                    class="flex-1 h-0.5 mx-2"
                    :class="currentStep > i + 1 ? 'bg-emerald-400' : 'bg-slate-200'"
                />
            </template>
        </div>

        <!-- Step content -->
        <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
            <SelectYears
                v-if="currentStep === 1"
                :academicYears="academicYears"
                v-model="wizardData"
                @next="next"
            />
            <ClassStructure
                v-else-if="currentStep === 2"
                v-model="wizardData"
                @next="next"
                @back="back"
            />
            <StudentReview
                v-else-if="currentStep === 3"
                v-model="wizardData"
                @next="next"
                @back="back"
            />
            <Preview
                v-else-if="currentStep === 4"
                v-model="wizardData"
                @next="next"
                @back="back"
            />
            <Confirm
                v-else-if="currentStep === 5"
                v-model="wizardData"
                @back="back"
            />
        </div>
    </div>
</template>
